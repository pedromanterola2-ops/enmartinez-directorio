// Página individual por negocio: /negocio/:slug (ver rewrite en vercel.json)
// Genera HTML completo en el servidor (SSR) para que Google y las vistas
// previas de WhatsApp/Facebook lean el contenido real de cada negocio.

const SUPABASE_URL = 'https://ygeuqlohycckwngcmmxl.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnZXVxbG9oeWNja3duZ2NtbXhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDE1MTksImV4cCI6MjA5NTgxNzUxOX0.fuFaUcYKaTjBpunDqIc-xMIGm3gA17r5Cn_E_JxFR_Q';
const SITE_URL = 'https://enmartinez-directorio.vercel.app';

const CAT_LABELS = {
  restaurantes: '🍽️ Restaurantes', abarrotes: '🛒 Abarrotes', salud: '🏥 Salud',
  talleres: '🔧 Talleres', belleza: '💇 Belleza', hoteles: '🏨 Hoteles',
  construccion: '🏗️ Construcción', veterinarias: '🐾 Veterinarias', ropa: '👗 Ropa',
  servicios: '⚡ Servicios Profesionales', agro: '🌿 Agro', educacion: '🏫 Educación',
  tecnologia: '💻 Tecnología', eventos: '🎉 Eventos', transporte: '🚕 Transporte',
  panaderias: '🥐 Panaderías', bancos: '🏦 Bancos', profesionales: '⚖️ Profesionales',
  agroindustria: '🍊 Agroindustria', oficios: '🔩 Oficios y servicios del hogar'
};

const SCHEMA_TIPO = {
  hoteles: 'LodgingBusiness', restaurantes: 'Restaurant', veterinarias: 'VeterinaryCare',
  salud: 'MedicalBusiness', bancos: 'BankOrCreditUnion', belleza: 'BeautySalon',
  talleres: 'AutoRepair', construccion: 'HomeAndConstructionBusiness'
};

const PAGO_ICONOS = { Efectivo: '💵', Tarjeta: '💳', Transferencia: '📲', Crédito: '🤝' };

function esc(v) {
  return String(v == null ? '' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function paginaNoEncontrada(res) {
  res.statusCode = 404;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Negocio no encontrado | EnMartinez.com</title>
<meta name="robots" content="noindex">
<style>body{font-family:'Segoe UI',system-ui,sans-serif;background:#f8faf8;color:#1f2937;text-align:center;padding:4rem 1.5rem}
a{color:#1a6b3c;font-weight:700;text-decoration:none}a:hover{text-decoration:underline}</style>
</head><body>
<h1>🌿 No encontramos este negocio</h1>
<p>Puede que ya no esté disponible o el enlace esté mal escrito.</p>
<a href="/">← Volver al directorio</a>
</body></html>`);
}

function paginaError(res, mensaje) {
  res.statusCode = 500;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
<title>Error | EnMartinez.com</title><meta name="robots" content="noindex"></head>
<body style="font-family:sans-serif;text-align:center;padding:4rem"><h1>Ocurrió un error</h1>
<p>${esc(mensaje)}</p><a href="/">← Volver al directorio</a></body></html>`);
}

module.exports = async (req, res) => {
  const slug = (req.query && req.query.slug) || '';
  if (!slug) return paginaNoEncontrada(res);

  let rows;
  try {
    const r = await fetch(
      `${SUPABASE_URL}/rest/v1/negocios?select=*&slug=eq.${encodeURIComponent(slug)}&limit=1`,
      { headers: { apikey: SUPABASE_ANON, Authorization: 'Bearer ' + SUPABASE_ANON } }
    );
    if (!r.ok) return paginaError(res, 'No se pudo consultar la base de datos (HTTP ' + r.status + ').');
    rows = await r.json();
  } catch (e) {
    return paginaError(res, e.message || 'Error de conexión con Supabase.');
  }

  if (!Array.isArray(rows) || rows.length === 0) return paginaNoEncontrada(res);
  const n = rows[0];

  const catLabel = n.cat_label || CAT_LABELS[n.categoria] || n.categoria || 'Negocio';
  const icono = n.icono || '🏪';
  const nombre = n.nombre || 'Negocio';
  const descripcion = n.descripcion || `${nombre} en Martínez de la Torre, Veracruz.`;
  const tieneCoords = typeof n.lat === 'number' && typeof n.lng === 'number' && isFinite(n.lat) && isFinite(n.lng);
  const url = `${SITE_URL}/negocio/${encodeURIComponent(n.slug)}`;
  const metaDesc = descripcion.length > 155 ? descripcion.slice(0, 152) + '...' : descripcion;

  const mapsUrl = n.direccion
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(nombre + ' ' + n.direccion + ' Martínez de la Torre')}`
    : null;

  const dirHtml = n.direccion
    ? `<a href="${esc(mapsUrl)}" target="_blank" rel="noopener">${esc(n.direccion)}</a>`
    : 'Servicio a domicilio · Contacto por teléfono o WhatsApp';

  const telDigits = String(n.telefono || '').replace(/\s/g, '');
  const telRow = n.telefono
    ? `<div class="info-row"><div class="info-icon azul">📞</div><div><a href="tel:${esc(telDigits)}">${esc(n.telefono)}</a></div></div>`
    : '';

  const horarioRow = n.horario
    ? `<div class="info-row"><div class="info-icon naranja">🕐</div><div>${esc(n.horario)}</div></div>`
    : '';

  const webRow = n.web
    ? `<div class="info-row"><div class="info-icon morado">🌐</div><div><a href="${esc(n.web)}" target="_blank" rel="noopener">${esc(n.web.replace('https://', ''))}</a></div></div>`
    : '';

  const fbRow = n.facebook
    ? `<div class="info-row"><div class="info-icon azul">👍</div><div><a href="${esc(n.facebook)}" target="_blank" rel="noopener">Ver página en Facebook</a></div></div>`
    : '';

  const servicios = Array.isArray(n.servicios) ? n.servicios : [];
  const serviciosHtml = servicios.length
    ? `<div><div class="section-title">Servicios</div><div class="tags">${servicios.map(s => `<span class="tag verde">${esc(s)}</span>`).join('')}</div></div>`
    : '';

  const pago = Array.isArray(n.pago) ? n.pago : [];
  const pagoHtml = (pago.length && pago[0] !== 'N/A')
    ? `<div><div class="section-title">Métodos de pago</div><div class="tags">${pago.map(p => `<span class="tag">${PAGO_ICONOS[p] || ''} ${esc(p)}</span>`).join('')}</div></div>`
    : '';

  const wspDigits = String(n.whatsapp || '').replace(/\D/g, '');
  const wspBtn = wspDigits
    ? `<a class="btn-wsp" href="https://wa.me/52${esc(wspDigits)}?text=${encodeURIComponent('Hola, vi tu negocio en EnMartinez.com y quisiera más información sobre ' + nombre)}" target="_blank" rel="noopener">💬 Enviar WhatsApp</a>`
    : (n.telefono ? `<a class="btn-wsp disabled" href="tel:${esc(telDigits)}">📞 Llamar</a>` : '');

  const destacadoBadge = n.destacado ? '<span class="badge">⭐ Destacado</span>' : '';

  const catKey = n.categoria || '';
  const schemaTipo = SCHEMA_TIPO[catKey] || 'LocalBusiness';
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': schemaTipo,
    name: nombre,
    description: descripcion,
    url,
    ...(n.telefono ? { telephone: n.telefono } : {}),
    ...(n.direccion ? {
      address: {
        '@type': 'PostalAddress',
        streetAddress: n.direccion,
        addressLocality: 'Martínez de la Torre',
        addressRegion: 'Veracruz',
        addressCountry: 'MX'
      }
    } : {}),
    ...(tieneCoords ? { geo: { '@type': 'GeoCoordinates', latitude: n.lat, longitude: n.lng } } : {})
  };

  const catSlugParaBreadcrumb = esc(catLabel.replace(/^\S+\s/, ''));

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(nombre)} — Martínez de la Torre, Veracruz | EnMartinez.com</title>
<meta name="description" content="${esc(metaDesc)}">
<link rel="canonical" href="${esc(url)}">
<meta property="og:type" content="business.business">
<meta property="og:title" content="${esc(nombre)} — Martínez de la Torre, Veracruz">
<meta property="og:description" content="${esc(metaDesc)}">
<meta property="og:url" content="${esc(url)}">
<meta property="og:locale" content="es_MX">
<meta property="og:site_name" content="EnMartinez.com">
<meta name="twitter:card" content="summary">
<meta name="theme-color" content="#1a6b3c">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
<style>
:root{--verde:#1a6b3c;--verde-bg:#f0f7f2;--naranja:#f97316;--texto:#1f2937;--texto-muted:#6b7280;--borde:#e5e7eb}
*{box-sizing:border-box}
body{margin:0;font-family:'Segoe UI',system-ui,sans-serif;background:#f8faf8;color:var(--texto)}
header{background:var(--verde);padding:0 1.5rem;position:sticky;top:0;z-index:10;box-shadow:0 2px 8px rgba(0,0,0,0.2)}
.header-inner{max-width:1100px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;height:60px}
.logo{color:#fff;font-weight:800;font-size:1.25rem;text-decoration:none}
.logo span{color:var(--naranja)}
nav a{color:rgba(255,255,255,0.85);text-decoration:none;padding:0.4rem 0.9rem;border-radius:6px;font-size:0.9rem;font-weight:500}
nav a.reg{background:var(--naranja);color:#fff;font-weight:700;margin-left:0.5rem}
@media (max-width:820px){nav{display:none}}
.breadcrumb{max-width:800px;margin:1.25rem auto 0;padding:0 1.5rem;font-size:0.82rem;color:var(--texto-muted)}
.breadcrumb a{color:var(--verde);text-decoration:none}
.ficha{max-width:800px;margin:1rem auto 3rem;padding:0 1.5rem}
.card{background:#fff;border-radius:18px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)}
.card-header{background:linear-gradient(135deg,var(--verde-bg),#d1fae5);padding:2rem 1.75rem 1.5rem;display:flex;gap:1.25rem}
.card-icon{font-size:4rem;line-height:1}
.cat{display:inline-block;font-size:0.75rem;font-weight:600;color:var(--verde);background:rgba(26,107,60,0.12);padding:0.25rem 0.7rem;border-radius:20px;margin-bottom:0.5rem}
.nombre{font-size:1.7rem;font-weight:900;line-height:1.2}
.badge{display:inline-block;background:var(--naranja);color:#fff;padding:0.2rem 0.6rem;border-radius:20px;font-size:0.72rem;font-weight:700;margin-left:0.5rem}
.card-body{padding:1.75rem;display:flex;flex-direction:column;gap:1.5rem}
.desc{font-size:0.98rem;line-height:1.65;background:#f9fafb;border-radius:10px;padding:1rem 1.1rem;border-left:3px solid var(--verde)}
.section-title{font-size:0.75rem;font-weight:700;text-transform:uppercase;letter-spacing:0.05em;color:var(--texto-muted);margin-bottom:0.6rem}
.info-grid{display:flex;flex-direction:column;gap:0.7rem}
.info-row{display:flex;align-items:flex-start;gap:0.85rem;font-size:0.94rem}
.info-row a{color:var(--verde);text-decoration:none;font-weight:600}
.info-row a:hover{text-decoration:underline}
.info-icon{width:34px;height:34px;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:1.05rem}
.info-icon.verde{background:var(--verde-bg)}.info-icon.azul{background:#dbeafe}
.info-icon.naranja{background:#ffedd5}.info-icon.morado{background:#ede9fe}
.tags{display:flex;flex-wrap:wrap;gap:0.4rem}
.tag{background:#f3f4f6;color:var(--texto);border-radius:20px;padding:0.25rem 0.7rem;font-size:0.82rem;font-weight:500}
.tag.verde{background:var(--verde-bg);color:var(--verde)}
.footer-btns{padding:1.25rem 1.75rem;border-top:1px solid var(--borde);display:flex;gap:0.7rem;flex-wrap:wrap}
.btn-wsp{flex:1;min-width:180px;background:#25D366;color:#fff;padding:0.85rem;border-radius:10px;font-size:0.95rem;font-weight:700;text-align:center;text-decoration:none}
.btn-wsp.disabled{background:#6b7280}
.volver{display:inline-block;margin-top:1.25rem;color:var(--verde);text-decoration:none;font-weight:600;font-size:0.9rem}
.volver:hover{text-decoration:underline}
footer{background:#0f2d1c;color:rgba(255,255,255,0.7);padding:2rem 1.5rem;margin-top:2rem;text-align:center;font-size:0.8rem}
</style>
</head>
<body>
<header>
  <div class="header-inner">
    <a href="/" class="logo">🌿 EnMartinez<span>.com</span></a>
    <nav>
      <a href="/#inicio">Inicio</a>
      <a href="/#categorias">Categorías</a>
      <a href="/#negocios">Negocios</a>
      <a href="/#mapa-section">Mapa</a>
      <a href="/registro" class="reg">＋ Registra tu negocio</a>
    </nav>
  </div>
</header>

<div class="breadcrumb"><a href="/">Inicio</a> › <a href="/#categorias">${catSlugParaBreadcrumb}</a> › ${esc(nombre)}</div>

<div class="ficha">
  <div class="card">
    <div class="card-header">
      <div class="card-icon">${icono}</div>
      <div>
        <div class="cat">${esc(catLabel)}</div>
        <div class="nombre">${esc(nombre)}${destacadoBadge}</div>
      </div>
    </div>
    <div class="card-body">
      <div class="desc">${esc(descripcion)}</div>
      <div>
        <div class="section-title">Información de contacto</div>
        <div class="info-grid">
          <div class="info-row"><div class="info-icon verde">📍</div><div>${dirHtml}</div></div>
          ${telRow}
          ${horarioRow}
          ${webRow}
          ${fbRow}
        </div>
      </div>
      ${serviciosHtml}
      ${pagoHtml}
    </div>
    <div class="footer-btns">
      ${wspBtn}
    </div>
  </div>
  <a class="volver" href="/">← Volver al directorio</a>
</div>

<footer>© 2026 EnMartinez.com — Martínez de la Torre, Veracruz · Hecho con 💚 para la comunidad</footer>
</body>
</html>`;

  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=86400');
  res.end(html);
};
