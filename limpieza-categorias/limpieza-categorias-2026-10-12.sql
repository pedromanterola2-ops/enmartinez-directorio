-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez — Limpieza de categorías (2026-10-12)
--  Deja máximo ~40 negocios en las 9 categorías más llenas y quita duplicados.
--  Retira 306 negocios importados del DENUE. NO toca los capturados a mano.
--
--  Cómo correrlo: Supabase → LaPastora → SQL Editor → pegar TODO → Run.
--  Es reversible: antes de borrar guarda copia en tablas de respaldo.
-- ═══════════════════════════════════════════════════════════════════

begin;

-- 1) Lista de candidatos a retirar
create temp table _retirar (id bigint primary key) on commit drop;
insert into _retirar (id) values
  (46), (53), (54), (56), (57), (58), (64), (66), (67), (69), (70), (72), (77), (78), (81),
  (84), (85), (88), (89), (91), (92), (94), (97), (101), (102), (103), (104), (106), (107), (108),
  (109), (110), (112), (113), (114), (115), (119), (121), (122), (123), (124), (126), (127), (128), (163),
  (174), (176), (177), (178), (181), (182), (183), (187), (188), (191), (193), (195), (199), (201), (203),
  (204), (206), (208), (209), (210), (212), (218), (224), (225), (226), (227), (229), (230), (231), (232),
  (270), (273), (274), (280), (292), (294), (295), (302), (303), (306), (311), (314), (315), (316), (317),
  (318), (391), (398), (404), (405), (406), (407), (408), (411), (414), (416), (419), (421), (423), (424),
  (425), (426), (433), (440), (441), (443), (448), (450), (451), (452), (454), (455), (456), (504), (505),
  (506), (510), (511), (512), (513), (515), (517), (518), (519), (543), (544), (545), (546), (547), (548),
  (550), (552), (553), (556), (557), (558), (559), (563), (566), (567), (569), (571), (575), (577), (580),
  (581), (583), (584), (585), (586), (587), (590), (593), (596), (597), (602), (604), (605), (606), (607),
  (608), (609), (610), (611), (613), (614), (615), (616), (618), (628), (631), (632), (643), (648), (650),
  (651), (652), (653), (655), (658), (660), (663), (664), (668), (671), (672), (674), (676), (677), (678),
  (679), (680), (682), (683), (684), (685), (687), (690), (692), (693), (694), (695), (696), (699), (700),
  (703), (704), (705), (706), (707), (709), (710), (713), (717), (718), (720), (723), (724), (725), (726),
  (727), (728), (730), (732), (736), (740), (741), (744), (745), (746), (747), (750), (751), (752), (753),
  (755), (756), (757), (761), (762), (764), (765), (766), (767), (769), (771), (782), (786), (788), (790),
  (791), (792), (793), (794), (796), (797), (799), (802), (804), (805), (806), (809), (811), (812), (815),
  (816), (817), (819), (821), (822), (823), (824), (825), (826), (827), (830), (831), (832), (835), (837),
  (841), (843), (844), (845), (846), (847), (849), (851), (852), (853), (855), (857), (861), (863), (864),
  (867), (868), (871), (873), (874), (875);

-- 2) Seguro: NO retirar negocios que la gente ya contactó desde EnMartinez
--    (clic en WhatsApp, llamar, cómo llegar, compartir, web o Facebook),
--    ni los que ya editaste a mano (origen distinto de 'denue-2026-05').
delete from _retirar r
 using public.negocios n
 where n.id = r.id and (n.origen is distinct from 'denue-2026-05' or n.destacado);
delete from _retirar r
 where exists (select 1 from public.eventos e where e.negocio_id = r.id and e.tipo <> 'vista');

-- 3) Respaldo (con RLS activa y sin políticas: nadie de fuera la puede leer)
create table if not exists public.negocios_retirados_2026_10_12 as
  select * from public.negocios where false;
alter table public.negocios_retirados_2026_10_12 enable row level security;
insert into public.negocios_retirados_2026_10_12
  select n.* from public.negocios n join _retirar r on r.id = n.id;

create table if not exists public.eventos_retirados_2026_10_12 as
  select * from public.eventos where false;
alter table public.eventos_retirados_2026_10_12 enable row level security;
insert into public.eventos_retirados_2026_10_12
  select e.* from public.eventos e join _retirar r on r.id = e.negocio_id;

-- 4) Retirar
delete from public.negocios n using _retirar r where n.id = r.id;

commit;

-- 5) Revisa el resultado: negocios por categoría
select categoria, count(*) from public.negocios group by categoria order by 2 desc;

-- ── DESHACER (solo si lo necesitas) ────────────────────────────────
-- insert into public.negocios
--   select * from public.negocios_retirados_2026_10_12
--   on conflict (id) do nothing;
-- (los eventos de vistas se pueden regresar igual desde eventos_retirados_2026_10_12)
