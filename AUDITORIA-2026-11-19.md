# Auditoría EnMartinez — 19 de noviembre de 2026

Revisión del sitio en vivo, del código de la carpeta y de los datos reales en Supabase (599 negocios). En esta ronda no se cambió nada: es solo diagnóstico.

## Resumen en 5 líneas
1. **Lo que se ve en línea está atrasado.** Hay 2 commits sin subir (miniaturas de fotos y unión de 24 a 15 categorías). Además, `categorias-2026-10-31.sql` no se ha corrido: la tabla de respaldo no existe y el sitio todavía muestra 24 categorías.
2. **El "40" no es real: es un tope.** La limpieza del 12 de octubre dejó máximo unos 40 negocios en las categorías más llenas, y por eso 10 categorías marcan exactamente 40.
3. **El 96 % de las fichas están casi vacías.** Tienen nombre, dirección y teléfono del DENUE, y nada más.
4. **El nivel C no se respeta en todo el sitio.** El inicio lo oculta, pero `/categoria`, `/negocio` y el sitemap no. Esto importa para tu plan de recortar.
5. **Se publican archivos internos** (SQL de seguridad, auditorías y el CSV del DENUE) en el dominio público.

---

## 1. Datos (lo que hay hoy en la base)

| Dato | Cantidad | De 599 |
|---|---|---|
| Del DENUE / capturados a mano | 573 / 26 | |
| Nivel A / B / C | 26 / 573 / 0 | |
| Con foto | 10 | 1.7 % |
| Con WhatsApp | 2 | 0.3 % |
| Con horario | 24 | 4 % |
| Con Facebook / web | 14 / 25 | |
| Destacados | 1 (langosta loca) | |
| Sin categoría | 2 (ids 36 y 40, las papelerías) | |

**Descripciones de plantilla.** Las 573 del DENUE dicen todas "Tienda de abarrotes en la colonia X, Martínez de la Torre." No es dato falso, pero Google trata 573 páginas casi iguales como contenido pobre.

**Teléfonos repetidos (10 casos), para revisar a mano:**
- **Pytr y langosta loca comparten el número 228 234 7278.** Parece un número de prueba o el tuyo. Revisar ya, porque langosta loca es la ficha Destacada.
- Varias sucursales de un mismo dueño (Tubyco / Tubos y Conexiones del Golfo, 6 fichas con el mismo número; Farmacia Medina; Compuservicios). Conviene dejar una ficha por negocio y anotar las sucursales dentro.
- Casos raros que sugieren datos viejos del DENUE: "Bella Flor" e "Impresiones Díaz", o "Tae Kwon Do Dragón Dorado" y "Reparación de Alhajas Mickey", con el mismo teléfono.

**Categorías con exactamente 40:** abarrotes, belleza, comida, oficios, papelerías, restaurantes, ropa, salud, talleres. Hoteles tiene solo 3.

## 2. Tu propuesta: bajar de 40 a una cantidad que se pueda revisar

Estoy de acuerdo, y los números la respaldan. Revisar 573 fichas del DENUE una por una (confirmar que siguen abiertas y buscar redes y fotos) no es realista. Con unas 12 por categoría queda una lista de unas 180 fichas que sí se pueden visitar o llamar.

**Ojo: primero hay que decidir lo de las 15 categorías.** Si se corre la unión, los totales cambian así:

| Categoría (15) | Total al unir |
|---|---|
| Restaurantes y comida | 86 |
| Construcción y oficios | 72 |
| Talleres y transporte | 55 |
| Papelerías | 42 |
| Abarrotes / Salud / Belleza / Ropa | 40 c/u |
| Panaderías y botanas | 39 |
| Servicios profesionales y financieros | 37 |
| Agro y agroindustria | 32 |
| Eventos y hospedaje | 26 |
| Tecnología | 24 |
| Educación | 15 |
| Veterinarias | 11 |

Con un tope de 12 por categoría quedan unas **179 fichas visibles**; con 15, unas **221**.

**Cómo hacerlo sin perder nada.** No conviene borrar: lo mejor es marcar nivel C a las que sobran. Así quedan guardadas y se pueden reactivar cuando se confirmen. Criterio para escoger cuáles se quedan:
1. todas las capturadas a mano (nivel A);
2. las del DENUE con más empleados (el CSV trae la columna `personal`): un negocio de 6 a 10 personas tiene más probabilidad de seguir abierto que uno de 0 a 5;
3. las que tienen más años registradas (`alta_inegi`), porque un negocio que lleva tiempo abierto es más estable;
4. las de la zona centro primero, porque son más fáciles de recorrer;
5. descartar teléfonos repetidos y nombres de sucursal sueltos.

**Antes de marcar nivel C hay que arreglar el código** (si no, las fichas "ocultas" siguen en línea):
- `api/categoria/[slug].js`: filtrar `nivel=neq.C` en la consulta;
- `api/negocio/[slug].js`: para nivel C, responder con `noindex` o con un 404 amable ("ficha en revisión");
- `api/sitemap.xml.js`: quitar nivel C del sitemap (hoy tiene 627 URLs, todas las fichas);
- el contador del inicio ("599 negocios registrados") debería contar solo las visibles.

**Flujo de revisión sugerido para cada ficha que se queda:**
1. confirmar que sigue abierto (llamada o recorrido);
2. pedir permiso y foto por WhatsApp (ya existe la pestaña "Fotos pendientes");
3. anotar horario, WhatsApp y redes **que el dueño confirme**;
4. subir a nivel A.

Faltaría una columna `verificado_en` (fecha) para saber cuándo se confirmó cada una y repetir la revisión cada 6 meses.

Sobre las imágenes: tu decisión del 31 de octubre sigue siendo la correcta. Las redes sirven para encontrar el contacto, el horario o el WhatsApp, pero las fotos deben venir del dueño o de tu recorrido. Copiarlas de Facebook o Google Maps sin permiso trae problemas de derechos.

## 3. Errores y riesgos del sitio

### Alta prioridad
1. **Commits sin subir y SQL sin correr.** El sitio en vivo no tiene la unión de categorías ni las miniaturas. Hay que hacer push, correr `categorias-2026-10-31.sql` y luego el botón "Generar miniaturas".
2. **Archivos internos públicos.** Vercel publica toda la carpeta. Hoy se pueden abrir, por ejemplo:
   - `/seguridad-2026-07-27.sql` y `/supabase-esquema.sql`: todas las reglas de seguridad y el correo del admin;
   - `/AUDITORIA-*.md`, `/INSTRUCCIONES-RESEND.md` y `/GUIA-CAPTURA-NEGOCIOS.md`;
   - `/importacion-denue/negocios-denue-revision.csv`: los 879 negocios con nombre, teléfono y número de empleados.

   No hay contraseñas ni llaves secretas en esos archivos, pero no tienen por qué estar en línea. **Solución:** un archivo `.vercelignore` con `*.md`, `*.sql`, `importacion-denue/`, `limpieza-categorias/`, `supabase/` e `impresos/`.
3. **Nivel C ignorado** en categoría, ficha y sitemap (ver arriba).
4. **Teléfono compartido entre Pytr y langosta loca.**

### Media
5. **Textos que prometen más de lo que hay:**
   - la meta de cada categoría dice "con teléfono, dirección, horarios y WhatsApp", pero el 96 % no tiene horario y casi ninguna tiene WhatsApp;
   - el registro dice "miles de personas".

   Conviene ajustar ambos textos.
6. **Falta el aviso de privacidad** y un camino para que un negocio pida quitar su ficha. Es más urgente con 573 fichas que nadie pidió. Basta una página `/privacidad` y un botón "¿Es tu negocio? Corrige o retira esta ficha" en cada ficha.
7. **Vercel Analytics sigue apagado.** `/_vercel/insights/script.js` da 404 y un error de consola en cada página. Se activa en Vercel → Proyecto → Analytics.
8. **`/destacados` sin botón de WhatsApp.** `WHATSAPP_VENTAS` sigue vacío, así que quien quiera comprar no tiene cómo hacerlo desde esa página.
9. **2 papelerías sin categoría** (las arregla el SQL de categorías).

### Baja
10. Las rutas `/mapa`, `/categorias` y `/negocios` (del plan original) dan 404. El menú usa anclas, así que no afecta, pero alguien podría escribirlas a mano. Se pueden redirigir a `/#mapa` y `/#categorias`.
11. `PROYECTO-CONTEXTO.md` dice "Estado: Planificación inicial" y "Firebase" en la parte vieja. Conviene recortar lo obsoleto.
12. El inicio descarga los 599 negocios completos (unos 0.5 s). Hoy está bien; con el recorte a nivel A/B baja solo.

## 4. Lo que está bien
- Las reglas de Supabase funcionan: con la llave pública no se pueden leer `solicitudes`, `eventos` ni `mensajes`, ni las tablas de los otros proyectos de LaPastora (`productos`, `ventas`, etc.).
- Las páginas responden rápido (unos 100 ms con la caché de Vercel) y el 404 de ficha inexistente es correcto, con `noindex`.
- Los slugs son únicos, las coordenadas caen dentro de Martínez y no hay nombres duplicados.
- Ya existe lo necesario para la revisión: niveles, Fotos pendientes, QR y estadísticas.

## 5. Orden sugerido
1. Push y correr el SQL de categorías; agregar `.vercelignore`.
2. Decidir el tope por categoría (12 o 15).
3. Arreglar el filtro de nivel C en categoría, ficha y sitemap.
4. Generar la lista de las que se quedan (con el criterio de arriba) y un SQL reversible que marque C al resto.
5. Aviso de privacidad y botón "corrige o retira esta ficha".
6. Recorrido y WhatsApp para subir esas ~180 a nivel A.

---

## Hecho en esta sesión (después del diagnóstico)
- Tope elegido: **12 por categoría**. Lista y SQL en `revision-negocios/`.
- Nivel C respetado en categoría, ficha (404 "en revisión", con enlace a registro) y sitemap.
- Meta de categoría: ya no promete "horarios y WhatsApp".
- Panel: filtro "Todos los niveles / A / B por revisar / C ocultas" y pastilla de nivel en cada fila. La opción C ahora dice "Oculta (sin confirmar, duplicada o cerrada)".
- `.vercelignore` para no publicar archivos internos.
- El contador de categorías del inicio ya no arranca en "24" fijo.

Siguen pendientes: aviso de privacidad y botón "corrige o retira esta ficha", Analytics, WhatsApp de ventas y el teléfono compartido entre Pytr y langosta loca.
