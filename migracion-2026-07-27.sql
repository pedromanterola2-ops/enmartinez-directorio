-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez.com — Migración previa a la captura masiva de negocios
--  Generado: 27 de julio de 2026
--
--  QUÉ HACE:
--    1. Agrega la columna `slug` + trigger automático  → arregla el error 500
--       en /negocio/:slug y hace que cada negocio nuevo nazca con su página.
--    2. Agrega la columna `foto` → para la foto de fachada.
--    3. Crea el bucket de Storage `negocios` con permisos correctos
--       (lectura pública, subida solo para ti).
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--
--  Es seguro correrlo más de una vez: todo usa "if not exists" o equivalente.
-- ═══════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 1 — SLUG (arregla el error 500 de /negocio/:slug)
-- ═══════════════════════════════════════════════════════════════════

create extension if not exists unaccent;

alter table public.negocios add column if not exists slug text;

-- Genera el slug a partir del nombre, evitando duplicados.
-- Si ya trae slug (editado a mano), lo respeta.
create or replace function public.generar_slug_negocio()
returns trigger
language plpgsql
as $$
declare
  base text;
  candidato text;
  i int := 1;
begin
  if new.slug is not null and length(trim(new.slug)) > 0 then
    return new;
  end if;

  base := trim(both '-' from regexp_replace(lower(unaccent(new.nombre)), '[^a-z0-9]+', '-', 'g'));
  if base = '' then
    base := 'negocio';
  end if;

  candidato := base;
  while exists (
    select 1 from public.negocios
    where slug = candidato and id is distinct from new.id
  ) loop
    i := i + 1;
    candidato := base || '-' || i;
  end loop;

  new.slug := candidato;
  return new;
end;
$$;

-- El trigger se dispara en cada insert/update: el panel admin y cualquier
-- SQL futuro obtienen slug automáticamente, sin que tengas que pensarlo.
drop trigger if exists trg_generar_slug_negocio on public.negocios;
create trigger trg_generar_slug_negocio
before insert or update on public.negocios
for each row execute function public.generar_slug_negocio();

-- Backfill: genera slug para los negocios que ya existen.
update public.negocios set nombre = nombre where slug is null;

-- Slug único + índice para que la consulta de la ficha sea instantánea.
alter table public.negocios drop constraint if exists negocios_slug_unique;
alter table public.negocios add constraint negocios_slug_unique unique (slug);
create index if not exists negocios_slug_idx on public.negocios (slug);


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 2 — FOTO DE FACHADA
-- ═══════════════════════════════════════════════════════════════════

-- Guarda la URL pública de la imagen (la sube el panel admin a Storage).
alter table public.negocios add column if not exists foto text;

comment on column public.negocios.foto is
  'URL pública de la foto de fachada. La sube el panel admin al bucket "negocios".';


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 3 — BUCKET DE STORAGE PARA LAS FOTOS
-- ═══════════════════════════════════════════════════════════════════

-- Bucket público: cualquiera puede VER las fotos (son de negocios, es el punto),
-- pero solo tú puedes subirlas o borrarlas.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'negocios',
  'negocios',
  true,
  3145728,  -- 3 MB máximo por foto
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
  set public             = true,
      file_size_limit    = 3145728,
      allowed_mime_types = array['image/jpeg','image/png','image/webp'];

-- ── Políticas del bucket ──
drop policy if exists "fotos negocios lectura publica" on storage.objects;
create policy "fotos negocios lectura publica"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'negocios');

drop policy if exists "fotos negocios sube admin" on storage.objects;
create policy "fotos negocios sube admin"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'negocios' and public.es_admin_enmartinez());

drop policy if exists "fotos negocios actualiza admin" on storage.objects;
create policy "fotos negocios actualiza admin"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'negocios' and public.es_admin_enmartinez())
  with check (bucket_id = 'negocios' and public.es_admin_enmartinez());

drop policy if exists "fotos negocios borra admin" on storage.objects;
create policy "fotos negocios borra admin"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'negocios' and public.es_admin_enmartinez());


-- ═══════════════════════════════════════════════════════════════════
--  VERIFICACIÓN — deberías ver slug y foto en cada negocio
-- ═══════════════════════════════════════════════════════════════════

select id, nombre, slug, foto from public.negocios order by nombre;
