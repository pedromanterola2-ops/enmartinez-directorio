-- ═══════════════════════════════════════════════════════════
--  EnMartinez.com — Agregar slug para páginas individuales /negocio/[slug]
--  Generado: 4 de julio de 2026
--  Pegar completo en: Supabase → SQL Editor → New query → Run
--  (Corre esto ANTES o DESPUÉS de negocios-reales-2026-07-04.sql, el orden no importa)
-- ═══════════════════════════════════════════════════════════

-- ── 1. Columna slug ──
create extension if not exists unaccent;
alter table public.negocios add column if not exists slug text;

-- ── 2. Función: genera un slug a partir del nombre y evita duplicados ──
create or replace function public.generar_slug_negocio()
returns trigger
language plpgsql
as $$
declare
  base text;
  candidato text;
  i int := 1;
begin
  -- Si ya trae slug (por ejemplo, editado a mano en el panel), respétalo.
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

-- ── 3. Trigger: se activa en cada insert/update, así el admin panel
--     y cualquier script SQL futuro obtienen slug automático ──
drop trigger if exists trg_generar_slug_negocio on public.negocios;
create trigger trg_generar_slug_negocio
before insert or update on public.negocios
for each row execute function public.generar_slug_negocio();

-- ── 4. Backfill: genera slug para los negocios que ya existen ──
-- (el UPDATE no cambia nada visible, pero dispara el trigger de arriba)
update public.negocios set nombre = nombre where slug is null;

-- ── 5. Slug único + índice ──
alter table public.negocios drop constraint if exists negocios_slug_unique;
alter table public.negocios add constraint negocios_slug_unique unique (slug);
create index if not exists negocios_slug_idx on public.negocios (slug);

-- ── 6. Verificación ──
select id, nombre, slug from public.negocios order by nombre;
