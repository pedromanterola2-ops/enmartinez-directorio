-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez — Dejar 12 negocios visibles por categoría (2026-11-19)
--
--  Quedan visibles 179 fichas: las 26 capturadas a mano (nivel A) y 153 del
--  DENUE (nivel B, "por revisar"). Las otras 420 pasan a nivel C (ocultas):
--  NO se borran. Siguen en la base y se reactivan cambiando el nivel en el
--  panel (filtro "C · Ocultas").
--
--  Criterio (12 por cada una de las 15 categorías nuevas):
--    1) todas las nivel A;
--    2) del DENUE: más empleados, más años registradas, más cerca del centro,
--       con web/Facebook; un solo negocio por teléfono repetido; reparto
--       entre las categorías que se unieron (ej. talleres + transporte).
--  Lista para el recorrido: revision-negocios/lista-revision-12-por-categoria.csv
--
--  ANTES de correrlo: hacer push del código (para que categoría, ficha y
--  sitemap oculten el nivel C). Si se corre antes, las ocultas siguen
--  apareciendo en /categoria y /negocio hasta publicar.
--
--  CÓMO USARLO: Supabase → LaPastora → SQL Editor → pegar TODO → Run.
--  Es seguro correrlo más de una vez.
--
--  PARA DESHACERLO:
--    update public.negocios n set nivel = r.nivel
--      from public.negocios_nivel_respaldo_2026_11_19 r where r.id = n.id;
-- ═══════════════════════════════════════════════════════════════════

begin;

-- 0) Copia de seguridad del nivel actual (solo la primera vez)
create table if not exists public.negocios_nivel_respaldo_2026_11_19 as
  select id, nivel from public.negocios;
alter table public.negocios_nivel_respaldo_2026_11_19 enable row level security;

-- 1) Ocultar todo lo que no está en la lista. Solo toca ids que existían hoy
--    (<= 923) y nunca toca fichas nivel A.
update public.negocios
   set nivel = 'C'
 where id <= 923
   and coalesce(nivel, '') <> 'A'
   and id not in (
  14, 16, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
  33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 45, 59, 60, 61,
  62, 74, 93, 100, 105, 111, 118, 125, 129, 134, 139, 140, 141, 146, 147,
  149, 153, 155, 156, 157, 165, 167, 185, 186, 190, 192, 196, 200, 202, 233,
  234, 235, 236, 238, 248, 249, 253, 255, 261, 262, 321, 326, 329, 343, 351,
  353, 354, 355, 356, 357, 358, 359, 360, 361, 364, 365, 367, 369, 371, 374,
  375, 378, 379, 386, 387, 388, 400, 403, 431, 432, 435, 437, 444, 464, 465,
  466, 471, 472, 479, 481, 485, 490, 491, 497, 501, 507, 520, 522, 527, 533,
  534, 536, 537, 572, 619, 624, 630, 638, 642, 646, 656, 659, 669, 673, 675,
  688, 689, 698, 712, 714, 733, 742, 748, 770, 775, 777, 781, 784, 829, 836,
  850, 862, 866, 869, 870, 876, 877, 878, 879, 882, 883, 884, 891, 892, 897,
  898, 901, 908, 911, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923
 );

-- 2) Las que se quedan y no son A: nivel B (por revisar)
update public.negocios
   set nivel = 'B'
 where id in (
  14, 16, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
  33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 45, 59, 60, 61,
  62, 74, 93, 100, 105, 111, 118, 125, 129, 134, 139, 140, 141, 146, 147,
  149, 153, 155, 156, 157, 165, 167, 185, 186, 190, 192, 196, 200, 202, 233,
  234, 235, 236, 238, 248, 249, 253, 255, 261, 262, 321, 326, 329, 343, 351,
  353, 354, 355, 356, 357, 358, 359, 360, 361, 364, 365, 367, 369, 371, 374,
  375, 378, 379, 386, 387, 388, 400, 403, 431, 432, 435, 437, 444, 464, 465,
  466, 471, 472, 479, 481, 485, 490, 491, 497, 501, 507, 520, 522, 527, 533,
  534, 536, 537, 572, 619, 624, 630, 638, 642, 646, 656, 659, 669, 673, 675,
  688, 689, 698, 712, 714, 733, 742, 748, 770, 775, 777, 781, 784, 829, 836,
  850, 862, 866, 869, 870, 876, 877, 878, 879, 882, 883, 884, 891, 892, 897,
  898, 901, 908, 911, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923
 )
   and coalesce(nivel, '') not in ('A', 'B');

commit;

-- 3) Comprobación: deben salir 179 visibles (A + B) y 420 ocultas (C)
select nivel, count(*) from public.negocios group by 1 order by 1;
