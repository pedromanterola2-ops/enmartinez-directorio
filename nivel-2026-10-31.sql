-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez — Niveles de ficha (Fase 0 del plan, 2026-10-31)
--
--  Nivel A = ficha completa (foto, WhatsApp o capturada a mano). Sale en el inicio.
--  Nivel B = ficha básica (p. ej. importada del DENUE). Solo en búsqueda y categorías.
--  Nivel C = retirada (duplicada, cerrada o sin teléfono que funcione). No se muestra.
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--  Es seguro correrlo más de una vez: la clasificación inicial solo se hace
--  la primera vez (cuando la columna todavía no existe).
--
--  PARA DESHACERLO:
--    alter table public.negocios drop column nivel;
--  (el sitio vuelve a mostrar todos los negocios en el inicio)
-- ═══════════════════════════════════════════════════════════════════

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'negocios' and column_name = 'nivel'
  ) then
    alter table public.negocios add column nivel text not null default 'B';

    -- Clasificación inicial: A = destacados, capturados a mano (sin origen),
    -- o con foto o WhatsApp. Todo lo demás queda en B.
    update public.negocios
       set nivel = 'A'
     where destacado is true
        or origen is null
        or foto is not null
        or whatsapp is not null;
  end if;
end $$;

alter table public.negocios drop constraint if exists negocios_nivel_valido;
alter table public.negocios add constraint negocios_nivel_valido
  check (nivel in ('A', 'B', 'C'));

create index if not exists negocios_nivel_idx on public.negocios (nivel);

notify pgrst, 'reload schema';

-- Comprobación: cuántos hay en cada nivel
select nivel, count(*) as negocios from public.negocios group by nivel order by nivel;
