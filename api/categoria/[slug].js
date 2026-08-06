// Página de categoría: /categoria/:slug (ver rewrite en vercel.json)
//
// Son 20 páginas de aterrizaje para búsquedas del tipo "restaurantes en
// Martínez de la Torre". Se generan en el servidor para que Google lea el
// listado real, no un contenedor vacío que se llena con JavaScript.

const SUPABASE_URL = 'https://ygeuqlohycckwngcmmxl.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnZXVxbG9oeWNja3duZ2NtbXhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDE1MTksImV4cCI6MjA5NTgxNzUxOX0.fuFaUcYKaTjBpunDqIc-xMIGm3gA17r5Cn_E_JxFR_Q';
const SITE_URL = 'https://enmartinez-directorio.vercel.app';
const CIUDAD = 'Martínez de la Torre, Veracruz';

// Cada categoría con el texto que se usa en título, descripción y encabezado.
const CATEGORIAS = {
  restaurantes:  { icono: '🍽️', nombre: 'Restaurantes y comida',        plural: 'restaurantes y lugares para comer' },
  abarrotes:     { icono: '🛒', nombre: 'Abarrotes y súper',            plural: 'tiendas de abarrotes y supermercados' },
  salud:         { icono: '🏥', nombre: 'Salud y farmacias',            plural: 'farmacias y servicios de salud' },
  talleres:      { icono: '🔧', nombre: 'Talleres y refacciones',       plural: 'talleres mecánicos y refaccionarias' },
  belleza:       { icono: '💇', nombre: 'Belleza y estética',           plural: 'salones de belleza y estéticas' },
  hoteles:       { icono: '🏨', nombre: 'Hoteles y hospedaje',          plural: 'hoteles y lugares de hospedaje' },
  construccion:  { icono: '🏗️', nombre: 'Construcción y ferretería',    plural: 'ferreterías y materiales de construcción' },
  veterinarias:  { icono: '🐾', nombre: 'Veterinarias y mascotas',      plural: 'veterinarias y tiendas de mascotas' },
  ropa:          { icono: '👗', nombre: 'Ropa y calzado',               plural: 'tiendas de ropa y calzado' },
  servicios:     { icono: '⚡', nombre: 'Servicios Profesionales',      plural: 'servicios profesionales' },
  agro:          { icono: '🌿', nombre: 'Agro y viveros',               plural: 'negocios agrícolas y viveros' },
  educacion:     { icono: '🏫', nombre: 'Educación',                    plural: 'escuelas y centros educativos' },
  tecnologia:    { icono: '💻', nombre: 'Tecnología',                   plural: 'negocios de tecnología y cómputo' },
  eventos:       { icono: '🎉', nombre: 'Eventos',                      plural: 'servicios para eventos y fiestas' },
  transporte:    { icono: '🚕', nombre: 'Transporte',                   plural: 'servicios de transporte' },
  panaderias:    { icono: '🥐', nombre: 'Panaderías y pastelerías',     plural: 'panaderías y pastelerías' },
  bancos:        { icono: '🏦', nombre: 'Bancos y financieros',         plural: 'bancos y servicios financieros' },
  profesionales: { icono: '⚖️', nombre: 'Profesionales',                plural: 'despachos y profesionistas' },
  agroindustria: { icono: '🍊', nombre: 'Agroindustria',                plural: 'empresas agroindustriales' },
  oficios:       { icono: '🔩', nombre: 'Oficios y servicios del hogar', plural: 'oficios y servicios para el hogar' },
};

function esc(v) {
  return String(v == null ? '' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function urlSegura(v) {
  const s = String(v == null ? '' : v).trim();
  if (!s) return '';
  try {
    const u = new URL(s);
    return (u.protocol === 'http:' || u.protocol === 'https:') ? u.href : '';
  } catch (e) { return ''; }
}

function paginaSimple(res, codigo, titulo, mensaje) {
  res.statusCode = codigo;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(titulo)} | EnMartinez.com</title><meta name="robots" content="noindex">
<style>body{font-family:'Segoe UI',system-ui,sans-serif;background:#f8faf8;color:#1f2937;text-align:center;padding:4rem 1.5rem}
a{color:#1a6b3c;font-weight:700;text-decoration:none}a:hover{text-decoration:underline}</style>
</head><body><h1>🌿 ${esc(titulo)}</h1><p>${esc(mensaje)}</p>
<a href="/">← Volver al directorio</a></body></html>`);
}

module.exports = async (req, res) => {
  const slug = String((req.query && req.query.slug) || '').toLowerCase();
  const cat = CATEGORIAS[slug];

  if (!cat) {
    return paginaSimple(res, 404, 'Categoría no encontrada',
      'Revisa el enlace o vuelve al directorio para ver todas las categorías.');
  }

  let negocios = [];
  try {
    const r = await fetch(
      `${SUPABASE_URL}/rest/v1/negocios?select=*&categoria=eq.${encodeURIComponent(slug)}&order=destacado.desc,nombre.asc`,
      { headers: { apikey: SUPABASE_ANON, Authorization: 'Bearer ' + SUPABASE_ANON } }
    );
    if (!r.ok) throw new Error('HTTP ' + r.status);
    const filas = await r.json();
    if (Array.isArray(filas)) negocios = filas;
  } catch (e) {
    return paginaSimple(res, 500, 'Ocurrió un error',
      'No pudimos consultar el directorio en este momento. Intenta de nuevo en unos minutos.');
  }

  const titulo = `${cat.nombre} en ${CIUDAD}`;
  const url = `${SITE_URL}/categoria/${encodeURIComponent(slug)}`;
  const metaDesc = negocios.length
    ? `Directorio de ${cat.plural} en Martínez de la Torre: ${negocios.length} ${negocios.length === 1 ? 'negocio' : 'negocios'} con teléfono, dirección, horarios y WhatsApp.`
    : `Directorio de ${cat.plural} en Martínez de la Torre, Veracruz. Registra tu negocio gratis en EnMartinez.com.`;

  // Las categorías sin negocios existen (el enlace no se rompe) pero no se
  // indexan: una página vacía en Google perjudica más de lo que ayuda.
  const robots = negocios.length ? 'index, follow' : 'noindex, follow';

  const tarjetas = negocios.map(n => {
    const nombre = n.nombre || 'Negocio';
    const enlace = n.slug ? `/negocio/${encodeURIComponent(n.slug)}` : null;
    const foto = urlSegura(n.foto);
    const wsp = String(n.whatsapp || '').replace(/\D/g, '');
    const desc = n.descripcion
      ? (n.descripcion.length > 150 ? n.descripcion.slice(0, 147) + '…' : n.descripcion)
      : '';

    const titHtml = enlace
      ? `<a class="nombre" href="${esc(enlace)}">${esc(nombre)}</a>`
      : `<span class="nombre">${esc(nombre)}</span>`;

    return `<article class="card">
      ${foto ? `<img class="card-foto" src="${esc(foto)}" alt="Fachada de ${esc(nombre)}" loading="lazy" decoding="async">` : ''}
      <div class="card-body">
        <div class="card-top">
          <span class="icono">${esc(n.icono || cat.icono)}</span>
          <div>
            ${titHtml}
            ${n.destacado ? '<span class="badge">⭐ Destacado</span>' : ''}
          </div>
        </div>
        ${desc ? `<p class="desc">${esc(desc)}</p>` : ''}
        <ul class="datos">
          ${n.direccion ? `<li>📍 ${esc(n.direccion)}</li>` : ''}
          ${n.telefono ? `<li>📞 <a href="tel:${esc(String(n.telefono).replace(/\s/g,''))}">${esc(n.telefono)}</a></li>` : ''}
          ${n.horario ? `<li>🕐 ${esc(n.horario)}</li>` : ''}
        </ul>
        <div class="acciones">
          ${wsp ? `<a class="btn-wsp" href="https://wa.me/52${esc(wsp)}" target="_blank" rel="noopener noreferrer">💬 WhatsApp</a>` : ''}
          ${enlace ? `<a class="btn-ver" href="${esc(enlace)}">Ver ficha →</a>` : ''}
        </div>
      </div>
    </article>`;
  }).join('\n');

  const vacio = `<div class="vacio">
    <div class="vacio-icono">${esc(cat.icono)}</div>
    <h2>Todavía no hay ${esc(cat.plural)} registrados</h2>
    <p>Estamos construyendo el directorio negocio por negocio.
       Si tienes uno de esta categoría, aparecer es gratis.</p>
    <a class="btn-reg" href="/registro">＋ Registra tu negocio</a>
  </div>`;

  // JSON-LD: lista ordenada de los negocios de la categoría
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: titulo,
    description: metaDesc,
    url,
    isPartOf: { '@type': 'WebSite', name: 'EnMartinez.com', url: SITE_URL },
    ...(negocios.length ? {
      mainEntity: {
        '@type': 'ItemList',
        numberOfItems: negocios.length,
        itemListElement: negocios.slice(0, 50).map((n, i) => ({
          '@type': 'ListItem',
          position: i + 1,
          name: n.nombre || 'Negocio',
          ...(n.slug ? { url: `${SITE_URL}/negocio/${encodeURIComponent(n.slug)}` } : {})
        }))
      }
    } : {})
  };

  // Escapado obligatorio: el JSON va dentro de un <script> y un nombre con
  // "</script>" partiría el documento.
  const jsonLdSeguro = JSON.stringify(jsonLd)
    .replace(/</g, '\\u003c').replace(/>/g, '\\u003e').replace(/&/g, '\\u0026');

  const otrasCategorias = Object.entries(CATEGORIAS)
    .filter(([k]) => k !== slug)
    .map(([k, c]) => `<a class="chip" href="/categoria/${encodeURIComponent(k)}">${esc(c.icono)} ${esc(c.nombre)}</a>`)
    .join('');

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(titulo)} | EnMartinez.com</title>
<meta name="description" content="${esc(metaDesc)}">
<meta name="robots" content="${robots}">
<link rel="canonical" href="${esc(url)}">
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(titulo)}">
<meta property="og:description" content="${esc(metaDesc)}">
<meta property="og:url" content="${esc(url)}">
<meta property="og:locale" content="es_MX">
<meta property="og:site_name" content="EnMartinez.com">
<meta property="og:image" content="${SITE_URL}/og-image.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#1a6b3c">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<script type="application/ld+json">${jsonLdSeguro}</script>
<style>
:root{--verde:#1a6b3c;--verde-bg:#f0f7f2;--naranja:#f97316;--texto:#1f2937;--muted:#6b7280;--borde:#e5e7eb}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#f8faf8;color:var(--texto)}
header{background:var(--verde);padding:0 1.5rem;position:sticky;top:0;z-index:10;box-shadow:0 2px 8px rgba(0,0,0,.2)}
.header-inner{max-width:1100px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;height:60px;gap:1rem}
.logo{color:#fff;font-weight:800;font-size:1.25rem;text-decoration:none}.logo span{color:var(--naranja)}
nav a{color:rgba(255,255,255,.85);text-decoration:none;padding:.4rem .9rem;border-radius:6px;font-size:.9rem}
nav a.reg{background:var(--naranja);color:#fff;font-weight:700}
@media(max-width:820px){nav a:not(.reg){display:none}}
.hero{background:linear-gradient(135deg,var(--verde),#0f4d2b);padding:2.5rem 1.5rem;text-align:center;color:#fff}
.hero .icono{font-size:3rem;display:block;margin-bottom:.5rem}
.hero h1{font-size:1.85rem;font-weight:900;margin-bottom:.5rem;line-height:1.2}
.hero p{color:rgba(255,255,255,.82);font-size:.98rem;max-width:600px;margin:0 auto}
.breadcrumb{max-width:1100px;margin:1.1rem auto 0;padding:0 1.5rem;font-size:.82rem;color:var(--muted)}
.breadcrumb a{color:var(--verde);text-decoration:none}
main{max-width:1100px;margin:1.25rem auto 3rem;padding:0 1.5rem}
.conteo{font-size:.88rem;color:var(--muted);margin-bottom:1rem;font-weight:600}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:1.1rem}
.card{background:#fff;border:1px solid var(--borde);border-radius:14px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.06);display:flex;flex-direction:column}
.card-foto{width:100%;height:165px;object-fit:cover;display:block;background:#e5e7eb}
.card-body{padding:1.1rem;display:flex;flex-direction:column;gap:.65rem;flex:1}
.card-top{display:flex;gap:.7rem;align-items:flex-start}
.icono{font-size:1.7rem;line-height:1}
.nombre{font-size:1.05rem;font-weight:800;color:var(--texto);text-decoration:none;display:block}
a.nombre:hover{color:var(--verde);text-decoration:underline}
.badge{display:inline-block;background:var(--naranja);color:#fff;padding:.12rem .5rem;border-radius:20px;font-size:.68rem;font-weight:700;margin-top:.25rem}
.desc{font-size:.86rem;color:var(--muted);line-height:1.5}
.datos{list-style:none;display:flex;flex-direction:column;gap:.3rem;font-size:.84rem}
.datos a{color:var(--verde);font-weight:600;text-decoration:none}
.acciones{display:flex;gap:.5rem;margin-top:auto;padding-top:.4rem;flex-wrap:wrap}
.btn-wsp{background:#25D366;color:#fff;padding:.5rem .85rem;border-radius:8px;font-size:.83rem;font-weight:700;text-decoration:none}
.btn-ver{background:var(--verde-bg);color:var(--verde);padding:.5rem .85rem;border-radius:8px;font-size:.83rem;font-weight:700;text-decoration:none}
.vacio{background:#fff;border:1px solid var(--borde);border-radius:14px;padding:3rem 1.5rem;text-align:center}
.vacio-icono{font-size:3.2rem;margin-bottom:.75rem}
.vacio h2{font-size:1.15rem;margin-bottom:.5rem}
.vacio p{color:var(--muted);font-size:.9rem;max-width:420px;margin:0 auto 1.25rem;line-height:1.6}
.btn-reg{display:inline-block;background:var(--naranja);color:#fff;padding:.75rem 1.5rem;border-radius:10px;font-weight:700;text-decoration:none;font-size:.92rem}
.otras{margin-top:2.5rem}
.otras h2{font-size:1rem;margin-bottom:.85rem}
.chips{display:flex;flex-wrap:wrap;gap:.45rem}
.chip{background:#fff;border:1px solid var(--borde);border-radius:20px;padding:.4rem .85rem;font-size:.82rem;color:var(--texto);text-decoration:none}
.chip:hover{border-color:var(--verde);color:var(--verde)}
footer{background:#0f2d1c;color:rgba(255,255,255,.7);padding:2rem 1.5rem;text-align:center;font-size:.8rem}
footer a{color:inherit}
</style>
</head>
<body>
<header>
  <div class="header-inner">
    <a href="/" class="logo">🌿 EnMartinez<span>.com</span></a>
    <nav>
      <a href="/">Inicio</a>
      <a href="/#categorias">Categorías</a>
      <a href="/#mapa-section">Mapa</a>
      <a href="/registro" class="reg">＋ Registra tu negocio</a>
    </nav>
  </div>
</header>

<div class="hero">
  <span class="icono">${esc(cat.icono)}</span>
  <h1>${esc(cat.nombre)} en Martínez de la Torre</h1>
  <p>${esc(metaDesc)}</p>
</div>

<div class="breadcrumb"><a href="/">Inicio</a> › <a href="/#categorias">Categorías</a> › ${esc(cat.nombre)}</div>

<main>
  ${negocios.length ? `<div class="conteo">${negocios.length} ${negocios.length === 1 ? 'negocio registrado' : 'negocios registrados'}</div>
  <div class="grid">${tarjetas}</div>` : vacio}

  <section class="otras">
    <h2>Explora otras categorías</h2>
    <div class="chips">${otrasCategorias}</div>
  </section>
</main>

<footer>© 2026 EnMartinez.com — ${esc(CIUDAD)} · Hecho con 💚 para la comunidad</footer>
<script defer src="/_vercel/insights/script.js"></script>
</body>
</html>`;

  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=86400');
  res.end(html);
};
