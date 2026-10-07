# Auditoría EnMartinez — 6 de octubre de 2026

Revisión del sitio en vivo (celular 390 px y escritorio 1280 px), del código y de los datos reales (26 negocios).

## Arreglado en esta ronda

### Críticos
1. **Mapa roto.** Desde octubre de 2026 CARTO exige API key y cada mosaico mostraba "API KEY REQUIRED". El home y el panel ahora usan mosaicos de OpenStreetMap, que no piden clave. En `index.html` quedó la constante `CARTO_KEY`: si se saca una clave gratis en carto.com/basemaps/apikey (1M de peticiones al mes en el plan comercial gratuito), basta con ponerla ahí para volver a Voyager retina. La CSP en `vercel.json` ahora permite `tile.openstreetmap.org` (antes solo `*.tile.openstreetmap.org`, que no cubre ese dominio).
2. **Fichas en celular.** En 2 columnas de unos 170 px, "langosta loca" se partía letra por letra (la etiqueta "Destacado" competía por el ancho), "MASCOTAS" se cortaba y los botones se apachurraban. Ahora:
   - debajo de 560 px las fichas van en una columna;
   - la etiqueta "Destacado" va junto a la categoría y ya no compite con el nombre;
   - los botones miden 44 px de alto, que es el mínimo cómodo para el dedo.
3. **WhatsApp que no abría.** "La parrilla de Math" está guardado como `52 1 232 323 8605` y el sitio le volvía a pegar el 52 (`wa.me/52521...`). Ahora los números se normalizan a 10 dígitos en las 3 vistas, y el panel los guarda ya normalizados.
4. **Teléfonos que no son teléfonos.** Nabaro Dress tiene "sin numero" y aun así mostraba "Llamar". Ahora el botón solo aparece si hay al menos 7 dígitos.

### Ficha individual `/negocio/:slug`
- "Llamar" salía en gris y parecía desactivado. Ahora es verde y tiene al lado los botones **WhatsApp**, **Cómo llegar** (Google Maps al punto exacto si hay coordenadas) y **Compartir** (abre el menú nativo del celular o WhatsApp). Compartir es clave para la estrategia de mandarle su ficha a cada dueño.
- La ruta (breadcrumb) ahora lleva a `/categoria/<slug>`; antes llevaba a `/#categorias`.
- Sin dirección se mostraba "Servicio a domicilio", que era un dato inventado. Ahora dice "Sin dirección registrada".
- Si no hay descripción ya no aparece la caja de relleno.
- El nombre es `<h1>` (antes no había ningún h1, malo para SEO).
- El pie de página trae enlaces a registro y contacto.

### Home
- Los teléfonos se muestran como `232 143 7891` en vez de `+522321437891` (aplica también en ficha y categoría).
- En el modal:
  - se ocultan descripción, teléfono y horario cuando están vacíos;
  - sin WhatsApp aparece un botón "Llamar" que sí marca, en lugar del botón gris desactivado;
  - el enlace de la web muestra solo el dominio (la URL de Instagram de 7 Fuegos medía 300 caracteres).
- **Buscador:**
  - ya no distingue acentos ("cafe" encuentra Vanila, "estetica" encuentra 3 negocios);
  - busca también por categoría y servicios, y acepta varias palabras;
  - el buscador del encabezado también filtra el mapa.
- **Categorías en celular:** pasan a 3 columnas compactas (antes ocupaban unas 3 pantallas) y las que tienen negocios salen primero.
- **Filtros (chips):** se quitaron los de categorías vacías, que no se podían tocar. En celular quedan en una sola fila deslizable; antes eran 10 renglones.
- El menú móvil no tenía "Contacto"; ya lo tiene.
- El logo apuntaba a `#`; ahora va a `/`.
- **Accesibilidad:**
  - categorías y chips son `<button>` y las fichas se abren con Enter;
  - el modal tiene `role="dialog"`;
  - el botón ✕ tiene etiqueta para lector de pantalla;
  - la hamburguesa tiene `aria-expanded`.

### Categoría `/categoria/:slug`
- En celular el encabezado se desacomodaba: el botón naranja "Registra tu negocio" se partía en dos renglones y montaba el logo. Ahora en pantallas chicas dice "＋ Registra" en un solo renglón.
- Las fichas sin WhatsApp muestran "Llamar".
- Se usan los mismos teléfonos normalizados que en el resto del sitio.

### Nueva categoría
- **📚 Papelerías y regalos** (`papelerias`), agregada en los 9 lugares y verificada con script. Hay 2 papelerías ("las toronjitas" y "DABEGIS") **sin categoría**, que no salen en ningún filtro: falta asignársela desde el panel.

### Otros
- Los enlaces `*.html` ahora son rutas limpias (`/registro`, `/contacto`, `/`). Con `cleanUrls` cada clic hacía una redirección 308 extra.
- Se quitó `formspree.io` de `form-action` en la CSP; ya no se usa.
- Contacto en celular trae un enlace "← Directorio" (el menú estaba oculto y no había forma de volver salvo el logo).

## Pendientes que requieren a Pedro (no se pueden hacer desde código)
1. **Activar Vercel Analytics** (Proyecto → Analytics → Enable). El script sigue dando 404 y genera un error en la consola en todas las páginas.
2. **Asignar la categoría** "Papelerías y regalos" a las 2 papelerías desde el panel.
3. **Datos a completar en el panel:**
   - Nabaro Dress: el teléfono dice "sin numero" (mejor dejarlo vacío);
   - 7 Fuegos: el "sitio web" es un enlace de Instagram con rastreo `fbclid`, mejor pegar solo `https://www.instagram.com/7fuegosgrill_mx`;
   - 7 negocios sin descripción;
   - Pytr sin coordenadas.
4. **Opcional, mapa más bonito:** sacar la clave gratis de CARTO y ponerla en `CARTO_KEY` (index.html). Más adelante también se puede poner en el panel.

## Observaciones sin cambiar (decisión de producto)
- "Restaurantes y comida" y "Comida" conviven y pueden confundir al visitante.
- `registro.html` promete "miles de personas" y "te avisamos por WhatsApp". Conviene que el texto refleje lo que de verdad pasa hoy.
- Las fotos pesan 100–230 KB para mostrarse a 120–150 px de alto. Supabase puede redimensionar al vuelo, pero solo en plan Pro. Una alternativa gratis es que el panel guarde también una miniatura de unos 600 px.
