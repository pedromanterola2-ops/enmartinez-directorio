# Auditoría técnica — EnMartinez.com
**Fecha:** 11 de junio de 2026 · **Alcance:** index.html, registro.html, admin.html, contacto.html, vercel.json y sitio en vivo (enmartinez-directorio.vercel.app)

---

## Resumen ejecutivo

El sitio funciona bien como vitrina estática: el diseño es sólido, responsivo y el mapa con clusters está bien resuelto. Pero hay un problema de fondo que afecta todo lo demás: **el sitio no tiene base de datos real**. Todo vive en `localStorage`, que es almacenamiento privado de cada navegador. Esto provoca tres fallas graves de funcionamiento que detallo abajo, además de un bug que puede tumbar la página completa y carencias serias de SEO para un proyecto cuya meta es ser la referencia local #1.

Calificación general: **6/10** — buen frontend, arquitectura de datos que no escala más allá de demo.

---

## 🔴 Hallazgos críticos

### 1. Los cambios del panel admin nunca llegan a los visitantes
`index.html` carga negocios desde `localStorage('em_negocios')` y, si no existe, usa la lista fija `NEGOCIOS_FALLBACK` (13 negocios escritos en el código). El panel admin guarda en el `localStorage` **de tu navegador**. Resultado: cuando agregas, editas o destacas un negocio en `/admin`, solo tú lo ves. Todos los visitantes ven siempre los 13 negocios hardcodeados. La única forma real de publicar cambios hoy es editar el código y redesplegar.

### 2. Las solicitudes de registro nunca llegan al panel admin
`registro.html` guarda la solicitud en el `localStorage` **del visitante que llenó el formulario** — un navegador al que tú no tienes acceso. La pestaña "Solicitudes" del admin solo mostraría solicitudes que tú mismo llenes desde tu navegador. El único canal que sí funciona es el correo vía FormSubmit. El comentario del código ("panel admin + backup") describe algo que no puede funcionar.

### 3. Un negocio sin coordenadas rompe toda la página
En `index.html` línea ~1381 se ejecuta `L.marker([n.lat, n.lng])` sin verificar nulos. El formulario de registro **no captura lat/lng**, así que si apruebas una solicitud y la importas, Leaflet lanza error y muere todo el JavaScript de la página (búsqueda, categorías, fichas, mapa: pantalla sin contenido). Lo mismo aplica a `n.direccion.toLowerCase()` en `buscar()` si falta dirección. El propio PROYECTO-CONTEXTO.md dice que lat/lng son opcionales; el código no lo respeta.

### 4. Seguridad del admin es solo cosmética
La contraseña por defecto está en el código fuente público: `admin.html` línea 624 (`PASS_DEFAULT = 'enmartinez2026'`), visible para cualquiera que abra "ver código fuente" en `/admin` (ruta pública, enlazada además con el 🔐 del footer). El "login" es solo `display:none`. Como los datos viven en cada navegador, un intruso no daña tu información, pero la contraseña expuesta da falsa sensación de seguridad. Cambiar la contraseña solo la cambia en tu navegador.

### 5. Formulario sin protección anti-spam
`_captcha: 'false'` en FormSubmit + correo `enmartinez1@outlook.com` en texto plano en el HTML. Es cuestión de tiempo para recibir spam de bots, tanto por el formulario como por harvesting del correo. Además, si FormSubmit falla, el usuario igual ve "¡Solicitud enviada!" y la solicitud se pierde para siempre (solo quedó en su localStorage).

---

## 🟠 Funcionamiento y código

**Inyección HTML / XSS.** Todo el render usa plantillas con `innerHTML` sin escapar (`${n.nombre}`, `${n.direccion}`, etc.) y handlers inline como `onclick="abrirWhatsApp('${n.whatsapp}','${n.nombre}')"`. Efectos prácticos: un negocio llamado *"Tacos D'Oro"* rompe el botón de WhatsApp por el apóstrofe, y cualquier dato importado vía "Importar JSON" o aprobado desde una solicitud puede ejecutar scripts. Recomendación: función `esc()` para todo dato dinámico y reemplazar onclick inline por `addEventListener` con data-attributes.

**Datos duplicados.** La lista de 13 negocios existe dos veces (NEGOCIOS_FALLBACK en index, NEGOCIOS_DEFAULT en admin), igual que el catálogo de 20 categorías (index, registro y admin). Ya hay una divergencia esperando a ocurrir con cada edición. Debería existir una sola fuente (un `negocios.json` y un `categorias.js` compartidos).

**Errores silenciados.** Varios `catch(e) {}` vacíos ocultan fallas (datos corruptos en localStorage pasan desapercibidos).

**vercel.json desactualizado.** Usa el formato legacy `builds`/`routes`. Con `"cleanUrls": true` logras lo mismo en una línea. Faltan headers de seguridad (`X-Content-Type-Options`, `Referrer-Policy`, CSP básica) y un header `X-Robots-Tag: noindex` para `/admin`.

---

## 🟡 Semántica y accesibilidad

La base es correcta (`lang="es"`, un solo H1, H2 en secciones, `<header>`, `<nav>`, `<footer>`), pero:

- Las secciones Categorías, Negocios y Mapa son `<div>`; deberían ser `<section>` y cada ficha un `<article>` con el nombre en `<h3>`.
- Elementos clickeables que no son botones: las tarjetas de categoría y los chips son `div`/`span` con `onclick` — invisibles para teclado y lectores de pantalla. Deberían ser `<button>` o `<a>`.
- El modal no tiene `role="dialog"`, `aria-modal="true"` ni manejo de foco (el foco se queda detrás del modal).
- Inputs de búsqueda sin `<label>` ni `aria-label`.
- Emojis usados como iconos informativos sin alternativa textual (`aria-hidden` o `role="img"` + `aria-label`).

---

## 🟡 SEO — el punto más débil para tu objetivo

Para un directorio que quiere ser "la referencia local #1", hoy Google casi no tiene nada que indexar:

- **No hay meta description**, ni Open Graph/Twitter Cards (al compartir en WhatsApp/Facebook —tu principal canal local— el enlace sale sin imagen ni descripción), ni favicon, ni canonical.
- **No hay robots.txt ni sitemap.xml.**
- **Cero datos estructurados.** Un directorio es el caso de uso ideal para JSON-LD `LocalBusiness`/`ItemList`; con eso los negocios pueden aparecer con rich results.
- **Cada negocio no tiene URL propia.** Todo vive en un modal de la portada; nadie puede llegar por Google buscando "farmacia martínez de la torre" a una ficha. La estructura `/negocio/[slug]` del plan original es la pieza SEO más valiosa pendiente.
- Title mejorable: incluir la ciudad — *"Directorio de Negocios de Martínez de la Torre, Veracruz | EnMartinez"*.
- `/admin` es indexable y está enlazado desde el footer; conviene noindex y quitar el enlace.

---

## 🟢 Rendimiento

Es lo mejor parado: página única de 74 KB, sin frameworks, fuentes del sistema, Leaflet desde CDN con SRI faltante pero versión correcta, tiles de OSM gratuitos. Observaciones menores: los `<script>` de Leaflet podrían llevar `defer`; el CSS (~500 líneas) se repite en las 4 páginas en lugar de un archivo cacheable compartido; y el mapa se inicializa siempre aunque el visitante nunca baje hasta él (candidato a inicialización perezosa con IntersectionObserver). Nada de esto es urgente con el tamaño actual.

---

## Lo que está bien hecho

Diseño visual coherente y profesional, mobile-first real con menú hamburguesa y autocompletado en tres buscadores, mapa con clusters e iconos por categoría que escalan con el zoom, manejo decente del caso "negocio sin WhatsApp", `scroll-margin-top` para el header fijo, validación de formulario con feedback visual, y separación clara de datos públicos/privados en el registro. El frontend está por encima del promedio de proyectos de esta etapa.

---

## Plan de acción recomendado

| # | Acción | Resuelve | Esfuerzo |
|---|--------|----------|----------|
| 1 | Migrar datos a backend real (Firebase Firestore como estaba planeado, o Supabase). Alternativa mínima: un `negocios.json` en el repo que el admin exporta y se redespliega | Críticos 1 y 2 | Medio-alto |
| 2 | Proteger contra null: `if (n.lat == null \|\| n.lng == null) return;` antes de crear marcador, y `(n.direccion \|\| '')` en búsqueda | Crítico 3 | 15 min |
| 3 | Escapar HTML en todos los renders y eliminar onclick inline con datos | XSS / nombres con apóstrofe | 1-2 h |
| 4 | Activar `_captcha: 'true'` en FormSubmit y mostrar error real si el envío falla | Crítico 5 | 15 min |
| 5 | SEO básico: meta description, OG + imagen, favicon, JSON-LD ItemList, robots.txt, sitemap, title con ciudad | SEO | 2-3 h |
| 6 | Quitar enlace 🔐 del footer, noindex en /admin, eliminar PASS_DEFAULT del código (o protección real con backend) | Crítico 4 | 30 min |
| 7 | Unificar negocios y categorías en una sola fuente de datos | Mantenibilidad | 1-2 h |
| 8 | Páginas por negocio `/negocio/[slug]` (requiere #1; ideal con Next.js o generación estática) | SEO de fondo | Alto |
| 9 | Semántica: section/article/h3, botones reales, ARIA en modal | Accesibilidad | 2-3 h |
| 10 | vercel.json moderno con cleanUrls y headers de seguridad | Infraestructura | 30 min |

Los puntos 2, 4 y 6 son arreglos del mismo día. El punto 1 es la decisión estructural: sin él, el directorio no puede crecer ni recibir registros reales, y conviene tomarla antes de invertir en el resto.
