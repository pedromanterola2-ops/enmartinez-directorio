-- ═══════════════════════════════════════════════════════════
--  EnMartinez.com — Limpieza de ejemplos + carga de negocios reales
--  Generado: 4 de julio de 2026
--  Pegar completo en: Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════

-- ── 1. Borrar los 13 negocios de ejemplo + "Pytr" (prueba) ──
-- Se conserva id 14 ("langosta loca") por instrucción explícita.
-- IDs confirmados en vivo el 2026-07-04 — si agregaste algo nuevo
-- desde entonces, revisa antes de correr.
delete from public.negocios
where id in (1,2,3,4,5,6,7,8,9,10,11,12,13,16);

-- ── 2. Negocios reales confirmados ──
-- Nota: varios campos quedan vacíos a propósito (servicios, pago,
-- horario en algunos casos) porque no pude confirmarlos por internet.
-- Complétalos desde el panel admin cuando tengas el dato, y usa la
-- pestaña Ubicaciones (drag & drop) para poner el pin en el mapa —
-- ninguno lleva lat/lng todavía.

insert into public.negocios
  (nombre, categoria, cat_label, icono, descripcion, direccion, telefono, whatsapp, horario, servicios, pago, facebook, web, destacado, lat, lng)
values

-- Hotel Aqua (dirección exacta pendiente de confirmar)
('Hotel Aqua', 'hoteles', '🏨 Hoteles', '🏨',
 'Hotel en Martínez de la Torre. Cuenta con el restaurante El Limonal en sus instalaciones.',
 null, '2321622737', '2321622737', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Restaurante El Limonal (dentro de Hotel Aqua)
('Restaurante El Limonal', 'restaurantes', '🍽️ Restaurantes', '🍽️',
 'Restaurante ubicado dentro del Hotel Aqua.',
 'Dentro de Hotel Aqua, Martínez de la Torre, Ver.', '2323735009', '2321081130', 'Lun–Dom 6:30–22:30',
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Hotel Vicans
('Hotel Vicans', 'hoteles', '🏨 Hoteles', '🏨',
 'Hotel en Martínez de la Torre. Cuenta con el restaurante Au Citron en sus instalaciones.',
 'Carretera Nacional Libramiento s/n, CP 93600, Martínez de la Torre, Ver.', '2323249220', '2323249220', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Restaurante Au Citron (dentro de Hotel Vicans, comparte teléfono del hotel)
('Au Citron', 'restaurantes', '🍽️ Restaurantes', '🍽️',
 'Restaurante ubicado dentro del Hotel Vicans.',
 'Dentro de Hotel Vicans, Carretera Nacional Libramiento s/n, CP 93600, Martínez de la Torre, Ver.', '2323249220', '2323249220', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Hotel Veracruz
('Hotel Veracruz', 'hoteles', '🏨 Hoteles', '🏨',
 'Hotel en el centro de Martínez de la Torre.',
 'Av. Maximino Ávila Camacho 106, Centro, CP 93600, Martínez de la Torre, Ver.', '2323240028', '2323240028', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Hotel Encanto
('Hotel Encanto', 'hoteles', '🏨 Hoteles', '🏨',
 'Hotel en Martínez de la Torre.',
 'Av. Libramiento Martínez de la Torre–Tlapacoyan s/n, CP 93603, Martínez de la Torre, Ver.', '2323733583', '2323733583', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Veterinaria Doctor Cuevas
('Veterinaria Doctor Cuevas', 'veterinarias', '🐾 Veterinarias', '🐾',
 'Clínica veterinaria en Martínez de la Torre.',
 'Alfinio Flores Beltrán 905, Col. Adolfo Ruiz Cortines, Martínez de la Torre, Ver.', '2323732264', '2323732264', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Mundo Animal
('Mundo Animal', 'veterinarias', '🐾 Veterinarias', '🐾',
 'Clínica veterinaria en el centro de Martínez de la Torre.',
 'Maximino Ávila Camacho 209, Centro, Martínez de la Torre, Ver.', '2321013822', '2321013822', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Veterinaria de la Dra. Arlette
('Veterinaria de la Dra. Arlette', 'veterinarias', '🐾 Veterinarias', '🐾',
 'Clínica veterinaria en el centro de Martínez de la Torre.',
 'Pedro Belli 511, Centro, CP 93600, Martínez de la Torre, Ver.', '2323245778', '2323245778', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Clínica Veterinaria Mascovet Plus
('Clínica Veterinaria Mascovet Plus', 'veterinarias', '🐾 Veterinarias', '🐾',
 'Clínica veterinaria en el centro de Martínez de la Torre.',
 'Ignacio de la Llave 403, Centro, CP 93600, Martínez de la Torre, Ver.', '2326900745', '2326900745', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null),

-- Central Veterinaria del Golfo
('Central Veterinaria del Golfo', 'veterinarias', '🐾 Veterinarias', '🐾',
 'Clínica veterinaria en el centro de Martínez de la Torre.',
 'Melchor Ocampo s/n esq. Salvador Allende, Centro, Martínez de la Torre, Ver.', '2323734067', '2323734067', null,
 '[]'::jsonb, '[]'::jsonb, '', '', false, null, null);

-- ── 3. Verificación rápida ──
select id, nombre, categoria, direccion, telefono, lat, lng
from public.negocios
order by categoria, nombre;
