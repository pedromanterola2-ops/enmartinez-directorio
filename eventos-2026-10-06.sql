-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez.com — Contador de visitas y clics por negocio
--  Generado: 6 de octubre de 2026
--
--  QUÉ RESUELVE:
--  Saber cuánta gente ve cada ficha y cuántos le escriben por WhatsApp,
--  le llaman o piden cómo llegar. Con eso se le manda al dueño un
--  reporte mensual ("tu ficha tuvo 120 visitas y 18 llamadas"), que es
--  el mejor argumento para vender la ficha Destacada.
--
--  SEGURIDAD:
--  · El público (anon) SOLO puede insertar. No puede leer, editar ni borrar.
--  · Solo el admin (es_admin_enmartinez) lee, vía la función resumen_eventos.
--  · Trigger con topes para que nadie infle números ni llene la tabla:
--    600 eventos/minuto en total y 60/minuto por negocio.
--  · No se guarda IP, ni navegador, ni nada que identifique a la persona.
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run. Se puede correr más de una vez.
-- ═══════════════════════════════════════════════════════════════════

create table if not exists public.eventos (
  id          bigint generated always as identity primary key,
  negocio_id  bigint not null references public.negocios(id) on delete cascade,
  tipo        text   not null,
  origen      text   not null default 'home',
  creado_en   timestamptz not null default now()
);

alter table public.eventos drop constraint if exists eventos_tipo_valido;
alter table public.eventos add constraint eventos_tipo_valido
  check (tipo in ('vista', 'whatsapp', 'llamar', 'como_llegar', 'compartir', 'web', 'facebook'));

alter table public.eventos drop constraint if exists eventos_origen_valido;
alter table public.eventos add constraint eventos_origen_valido
  check (origen in ('home', 'ficha', 'categoria', 'mapa'));

create index if not exists eventos_fecha_idx   on public.eventos (creado_en);
create index if not exists eventos_negocio_idx on public.eventos (negocio_id, creado_en);

-- ── RLS: anon solo inserta ──
alter table public.eventos enable row level security;

drop policy if exists "eventos: cualquiera inserta" on public.eventos;
create policy "eventos: cualquiera inserta" on public.eventos
  for insert to anon, authenticated with check (true);

drop policy if exists "eventos: solo admin lee" on public.eventos;
create policy "eventos: solo admin lee" on public.eventos
  for select to authenticated using (public.es_admin_enmartinez());

drop policy if exists "eventos: solo admin borra" on public.eventos;
create policy "eventos: solo admin borra" on public.eventos
  for delete to authenticated using (public.es_admin_enmartinez());

-- ── Topes contra inflado de números ──
create or replace function public.validar_evento()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  total_min   int;
  negocio_min int;
begin
  new.creado_en := now();   -- la fecha la pone el servidor, no el visitante

  select count(*) into total_min
    from public.eventos where creado_en > now() - interval '1 minute';
  if total_min >= 600 then
    raise exception 'Demasiados eventos' using errcode = 'check_violation';
  end if;

  select count(*) into negocio_min
    from public.eventos
   where negocio_id = new.negocio_id and creado_en > now() - interval '1 minute';
  if negocio_min >= 60 then
    raise exception 'Demasiados eventos para este negocio' using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_evento on public.eventos;
create trigger trg_validar_evento
  before insert on public.eventos
  for each row execute function public.validar_evento();

-- ── Resumen para el panel (solo admin) ──
-- Devuelve una fila por negocio con los conteos del periodo.
create or replace function public.resumen_eventos(desde timestamptz, hasta timestamptz default now())
returns table (
  negocio_id   bigint,
  vistas       bigint,
  whatsapp     bigint,
  llamar       bigint,
  como_llegar  bigint,
  compartir    bigint,
  web          bigint,
  facebook     bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.es_admin_enmartinez() then
    raise exception 'Solo el administrador' using errcode = 'insufficient_privilege';
  end if;
  return query
    select e.negocio_id,
           count(*) filter (where e.tipo = 'vista'),
           count(*) filter (where e.tipo = 'whatsapp'),
           count(*) filter (where e.tipo = 'llamar'),
           count(*) filter (where e.tipo = 'como_llegar'),
           count(*) filter (where e.tipo = 'compartir'),
           count(*) filter (where e.tipo = 'web'),
           count(*) filter (where e.tipo = 'facebook')
      from public.eventos e
     where e.creado_en >= desde and e.creado_en < hasta
     group by e.negocio_id;
end;
$$;

revoke all on function public.resumen_eventos(timestamptz, timestamptz) from public, anon;
grant execute on function public.resumen_eventos(timestamptz, timestamptz) to authenticated;

notify pgrst, 'reload schema';
