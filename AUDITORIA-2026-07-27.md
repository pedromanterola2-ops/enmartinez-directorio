# Auditoría EnMartinez.com — 27 de julio de 2026

Revisión de código local, base de datos Supabase en vivo y sitio en producción
(`https://enmartinez-directorio.vercel.app`).

**Veredicto corto:** la base técnica es sólida (RLS correcta, escapado de HTML,
headers de seguridad, SSR con SEO bien hecho). El problema no es el código: es que
la funcionalidad más importante que construiste está **rota en producción** y el
directorio está **prácticamente vacío**. Nada de lo demás importa hasta arreglar eso.

---

## 🔴 Críticos — arreglar esta semana

### 1. Las páginas individuales `/negocio/:slug` devuelven error 500

La migración `negocios-slug-migracion-2026-07-04.sql` **nunca se ejecutó** en Supabase.
Verificado en vivo:

```
GET /rest/v1/negocios?select=slug
→ {"code":"42703","message":"column negocios.slug does not exist"}

GET https://enmartinez-directorio.vercel.app/negocio/hotel-vicans
→ HTTP 500
```

Consecuencias en cadena:

- Todo el trabajo del commit `17cec1d` (SSR + JSON-LD + Open Graph por negocio) está muerto.
- En `index.html:1318` el botón "Ver página" nunca aparece, porque `n.slug` siempre llega vacío.
- En `admin.html:964` el ícono 🔗 de página pública nunca se muestra.
- Google no puede indexar ningún negocio individual — que era justo el objetivo de SEO.

**Arreglo:** pegar `negocios-slug-migracion-2026-07-04.sql` completo en Supabase →
SQL Editor → Run. Son 5 minutos. Verificar después con
`https://enmartinez-directorio.vercel.app/negocio/langosta-loca`.

### 2. Solo hay 2 negocios en la base de datos

Estado real hoy:

| Negocio | Categoría | Coordenadas | Destacado |
|---|---|---|---|
| langosta loca | restaurantes | sí | sí |
| Pytr | tecnologia | no | no |

El archivo `negocios-reales-2026-07-04.sql` (con ~19 negocios reales investigados)
**tampoco se ejecutó** — solo corrió la parte del `delete` que borró los 13 de ejemplo.

Un directorio con dos fichas, una de las cuales es tu propia empresa, no le sirve
a ningún visitante. Este es el bloqueador real del proyecto: no es técnico, es de contenido.

**Arreglo:** correr `negocios-reales-2026-07-04.sql`, y después meterle horas a
cargar negocios reales desde el panel admin. Meta mínima razonable para lanzar
en serio: **50 negocios con teléfono y ubicación**.

### 3. Datos falsos como respaldo (`NEGOCIOS_FALLBACK`)

`index.html:814` todavía contiene los 13 negocios inventados ("Taquería El Buen Taco",
teléfono 232 123 4567…). Si Supabase falla o tarda, `cargarNegociosIndex()` los muestra
al público como si fueran reales, con teléfonos que no existen.

Riesgo de credibilidad directo, en un proyecto cuyo único activo es la confianza local.

**Arreglo:** borrar el array y mostrar un estado de error honesto
("No pudimos cargar el directorio, intenta de nuevo en unos minutos"). Ahorra
además ~15 KB en cada carga.

---

## 🟠 Alto impacto — próximas 2 semanas

### 4. Sin `og:image` en ninguna página

Verificado: 0 ocurrencias en `index.html`, `registro.html`, `contacto.html` y
`api/negocio/[slug].js`.

Cuando alguien comparte el directorio por WhatsApp — que va a ser el canal
principal de difusión en Martínez — aparece un enlace gris sin imagen. La diferencia
en clics entre un enlace con y sin previsualización es enorme.

**Arreglo:** una imagen 1200×630 en `/og-image.png` + la etiqueta en cada página.
Para las fichas individuales, generar una OG dinámica con `@vercel/og` (nombre del
negocio + categoría sobre fondo verde) sería el mejor retorno por esfuerzo del proyecto.

### 5. Formulario de contacto probablemente no funciona

`contacto.html:203` usa `https://formspree.io/f/enmartinez1@outlook.com`. Ese formato
con el correo en la URL es el endpoint legacy de Formspree, descontinuado hace años
para cuentas nuevas. Es muy probable que los mensajes se estén perdiendo en silencio.

**Arreglo:** crear un form en Formspree, obtener el ID real (`/f/xxxxxxx`) y probar
enviando un mensaje de prueba. O mejor: mandar contacto a la tabla `solicitudes`
también, para no depender de terceros.

### 6. Sin notificación cuando llega una solicitud

Existe `supabase/functions/notify-nueva-solicitud/index.ts`, pero no hay evidencia de
que esté desplegada. Si un negocio se registra hoy, no te enteras hasta que abras el
panel. Ese retraso mata registros.

**Arreglo:** confirmar despliegue (`supabase functions deploy notify-nueva-solicitud`)
siguiendo `INSTRUCCIONES-RESEND.md`, o como alternativa rápida: un correo con Formspree
en paralelo al insert.

### 7. Sitemap estático e incompleto

`sitemap.xml` tiene 3 URLs fijas con `lastmod` congelado en 2026-07-04, y no incluye
ninguna ficha de negocio. Una vez arreglado el slug, cada negocio es una página que
Google debería indexar.

**Arreglo:** convertirlo en `api/sitemap.xml.js` que consulte Supabase y liste
`/negocio/:slug` de todos los negocios, con `lastmod` real.

### 8. Sin dominio propio

Sigues en `*.vercel.app`. Para un negocio local que se anuncia de boca en boca,
"enmartinez.com" es memorizable y `enmartinez-directorio.vercel.app` no lo es.
Además Google trata mejor los dominios propios para búsqueda local.

**Arreglo:** `.com.mx` o `.com` — unos 200–400 MXN al año. Vercel lo conecta en minutos.

### 9. Cero analítica

No hay forma de saber si alguien visita el sitio, qué categorías busca, o si los
botones de WhatsApp se usan. Estás desarrollando a ciegas.

**Arreglo:** Vercel Web Analytics (gratis en el plan Hobby, una etiqueta `<script>`).
Los eventos que importan: clic en WhatsApp, clic en teléfono, búsquedas sin resultados.

---

## 🟡 Medio — cuando haya tiempo

| # | Hallazgo | Detalle |
|---|---|---|
| 10 | Formulario de registro sin validación | `registro.html`: **0 atributos `required`**. Se puede enviar una solicitud completamente vacía. Falta también validación de teléfono (10 dígitos). |
| 11 | Leaflet bloquea el render inicial | 3 CSS + 2 JS de cdnjs en el `<head>`, cargados aunque el usuario nunca baje al mapa. Cargarlos con `IntersectionObserver` mejoraría notablemente el LCP en móvil. |
| 12 | Sin Content-Security-Policy | `vercel.json` tiene los otros 4 headers bien puestos, falta CSP. Con orígenes conocidos (supabase, cdnjs, tile.openstreetmap) es fácil de escribir. |
| 13 | Archivos monolíticos | `index.html` 1852 líneas / 80 KB, `admin.html` 1747 líneas / 87 KB, todo inline. Funciona, pero cada cambio es más riesgoso. Extraer al menos el CSS y el JS a archivos aparte con `cache-control` largo. |
| 14 | Sin fotos de negocios | Un directorio con puros emojis convierte mucho peor que uno con fachadas. Supabase Storage está incluido en tu plan. |
| 15 | Sin búsqueda por categoría en URL | No existe `/categoria/restaurantes`. Son 20 páginas de aterrizaje SEO regaladas ("restaurantes en Martínez de la Torre"). |
| 16 | Sin `robots`/`noindex` en `ejemplo-pagina-negocio.html` | Archivo de prueba servido públicamente. Borrarlo del repo. |
| 17 | `PROYECTO-CONTEXTO.md` en `.gitignore` | Correcto, pero recuerda: la contraseña vieja `enmartinez2026` sigue en el historial de git. No reutilizarla nunca. |

---

## ✅ Lo que está bien (no tocar)

Verificado en vivo, funcionando correctamente:

- **RLS de Supabase.** Un `POST` anónimo a `negocios` devuelve
  `42501 — new row violates row-level security policy`. Un `SELECT` anónimo a
  `solicitudes` devuelve `[]`. La seguridad de datos está bien resuelta.
- **Escapado de HTML.** La función `esc()` se aplica consistentemente en
  `api/negocio/[slug].js`, `index.html` y `admin.html`. Sin XSS visible.
- **Headers de seguridad.** `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Permissions-Policy` — todos aplicados. `/admin` con `noindex`.
- **Guardas de nulos** en `lat`/`lng` antes de crear marcadores Leaflet.
- **Autenticación del panel** con Supabase Auth (`signInWithPassword` +
  `onAuthStateChange` + `signOut`), no contraseña hardcodeada.
- **SEO base:** meta description, Open Graph, JSON-LD `LocalBusiness` con el tipo
  correcto por categoría (`Restaurant`, `LodgingBusiness`, `AutoRepair`…), canonical,
  robots.txt. Es mejor SEO técnico del que tienen la mayoría de los directorios locales.
- **Rendimiento del servidor:** la home responde en ~310 ms, 80 KB. Bien.
- **Caché del SSR:** `s-maxage=300, stale-while-revalidate=86400` en las fichas. Correcto.

---

## Plan sugerido, en orden

**Hoy (1 hora):**

1. Correr `negocios-slug-migracion-2026-07-04.sql` en Supabase.
2. Correr `negocios-reales-2026-07-04.sql`.
3. Verificar que `/negocio/langosta-loca` abre bien.
4. Borrar `NEGOCIOS_FALLBACK` de `index.html`.

**Esta semana:**

5. Agregar `og:image` (estática primero, dinámica después).
6. Arreglar o reemplazar el formulario de contacto.
7. Confirmar la notificación por correo de solicitudes.
8. Instalar Vercel Analytics.
9. Comprar el dominio.

**Este mes:**

10. Sitemap dinámico + páginas `/categoria/:slug`.
11. `required` y validación en el formulario de registro.
12. Cargar negocios hasta llegar a 50 con datos completos.
13. Fotos de fachada de los negocios destacados.

---

*Auditoría generada el 27 de julio de 2026. Todos los hallazgos verificados contra la
base de datos y el sitio en producción, no solo contra el código local.*
