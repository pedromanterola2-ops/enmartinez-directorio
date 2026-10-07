-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez.com — Negocios sin local / a domicilio
--  Generado: 6 de octubre de 2026
--
--  QUÉ RESUELVE:
--  Hay negocios que no tienen local (solo a domicilio, por pedido o en
--  línea, como Pytr) y otros que tienen local y además entregan. Hasta
--  ahora el sitio no podía distinguirlos: a un negocio sin dirección le
--  decía "Sin dirección registrada", como si faltara un dato.
--
--  Valores de `modalidad`:
--    'local'     → tiene local físico (lo normal, valor por defecto)
--    'domicilio' → NO tiene local: solo a domicilio / por pedido
--    'ambos'     → tiene local y también lleva a domicilio
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--  Se puede correr más de una vez sin problema.
--
--  No toca RLS: las políticas existentes cubren la columna nueva.
-- ═══════════════════════════════════════════════════════════════════

alter table public.negocios
  add column if not exists modalidad text not null default 'local';

alter table public.negocios drop constraint if exists negocios_modalidad_valida;
alter table public.negocios add constraint negocios_modalidad_valida
  check (modalidad in ('local', 'domicilio', 'ambos'));

-- El formulario público de registro también la pregunta
alter table public.solicitudes
  add column if not exists modalidad text not null default 'local';

alter table public.solicitudes drop constraint if exists solicitudes_modalidad_valida;
alter table public.solicitudes add constraint solicitudes_modalidad_valida
  check (modalidad in ('local', 'domicilio', 'ambos'));

-- Pytr no tiene local: se marca de una vez
update public.negocios set modalidad = 'domicilio' where slug = 'pytr';

-- Para que PostgREST vea la columna nueva de inmediato
notify pgrst, 'reload schema';
