-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez — Unir 24 categorías en 15 (2026-10-31)
--
--  restaurantes  ← restaurantes, comida, cafes
--  panaderias    ← panaderias, botanas
--  construccion  ← construccion, oficios
--  talleres      ← talleres, transporte
--  servicios     ← servicios, profesionales, bancos
--  eventos       ← eventos, hoteles
--  agro          ← agro, agroindustria
--  (sin cambio: abarrotes, salud, belleza, ropa, tecnologia, educacion,
--   veterinarias, papelerias)
--  Además: las 2 papelerías que estaban sin categoría (ids 36 y 40).
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--  Antes de cambiar nada guarda una copia en `negocios_categoria_respaldo`.
--  Es seguro correrlo más de una vez.
--
--  PARA DESHACERLO:
--    update public.negocios n
--       set categoria = r.categoria, cat_label = r.cat_label
--      from public.negocios_categoria_respaldo r
--     where r.id = n.id;
-- ═══════════════════════════════════════════════════════════════════

begin;

-- 0) Copia de seguridad (solo la primera vez)
create table if not exists public.negocios_categoria_respaldo as
  select id, categoria, cat_label from public.negocios;
alter table public.negocios_categoria_respaldo enable row level security;

-- 1) Las 2 papelerías sin categoría
update public.negocios
   set categoria = 'papelerias'
 where id in (36, 40) and coalesce(categoria, '') = '';

-- 2) Categorías unidas
update public.negocios set categoria = 'restaurantes', cat_label = '🍽️ Restaurantes y comida'
 where categoria in ('restaurantes', 'comida', 'cafes');
update public.negocios set categoria = 'panaderias', cat_label = '🥐 Panaderías y botanas'
 where categoria in ('panaderias', 'botanas');
update public.negocios set categoria = 'construccion', cat_label = '🏗️ Construcción y oficios'
 where categoria in ('construccion', 'oficios');
update public.negocios set categoria = 'talleres', cat_label = '🔧 Talleres y transporte'
 where categoria in ('talleres', 'transporte');
update public.negocios set categoria = 'servicios', cat_label = '⚡ Servicios profesionales y financieros'
 where categoria in ('servicios', 'profesionales', 'bancos');
update public.negocios set categoria = 'eventos', cat_label = '🎉 Eventos y hospedaje'
 where categoria in ('eventos', 'hoteles');
update public.negocios set categoria = 'agro', cat_label = '🌿 Agro y agroindustria'
 where categoria in ('agro', 'agroindustria');

-- 3) Las que no se unen: solo se uniforma la etiqueta
update public.negocios set cat_label = '🛒 Abarrotes y súper'        where categoria = 'abarrotes';
update public.negocios set cat_label = '🏥 Salud y farmacias'        where categoria = 'salud';
update public.negocios set cat_label = '💇 Belleza y estética'       where categoria = 'belleza';
update public.negocios set cat_label = '👗 Ropa y calzado'           where categoria = 'ropa';
update public.negocios set cat_label = '💻 Tecnología'               where categoria = 'tecnologia';
update public.negocios set cat_label = '🏫 Educación'                where categoria = 'educacion';
update public.negocios set cat_label = '🐾 Veterinarias y mascotas'  where categoria = 'veterinarias';
update public.negocios set cat_label = '📚 Papelerías y regalos'     where categoria = 'papelerias';

commit;

-- Comprobación: deben salir 15 categorías y ninguna vacía
select categoria, cat_label, count(*) as negocios
  from public.negocios
 group by categoria, cat_label
 order by negocios desc;
