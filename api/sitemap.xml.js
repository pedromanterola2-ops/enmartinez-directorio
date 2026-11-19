// Sitemap dinámico: /sitemap.xml (ver rewrite en vercel.json)
//
// Reemplaza al sitemap.xml estático, que solo listaba 3 URLs con una fecha
// congelada. Este consulta Supabase y publica una entrada por cada negocio
// y por cada categoría que tenga al menos un negocio, con la fecha real.

const SUPABASE_URL = 'https://ygeuqlohycckwngcmmxl.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnZXVxbG9oeWNja3duZ2NtbXhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDE1MTksImV4cCI6MjA5NTgxNzUxOX0.fuFaUcYKaTjBpunDqIc-xMIGm3gA17r5Cn_E_JxFR_Q';
const SITE_URL = 'https://enmartinez-directorio.vercel.app';

// Categorías anteriores a la unión de 2026-10: se cuentan como la nueva.
const ANTIGUAS = { comida: 'restaurantes', cafes: 'restaurantes', botanas: 'panaderias', oficios: 'construccion', transporte: 'talleres', profesionales: 'servicios', bancos: 'servicios', hoteles: 'eventos', agroindustria: 'agro' };

function esc(v) {
  return String(v == null ? '' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}

function soloFecha(valor) {
  const d = valor ? new Date(valor) : new Date();
  return (isNaN(d.getTime()) ? new Date() : d).toISOString().slice(0, 10);
}

function entrada(loc, lastmod, changefreq, priority) {
  return `  <url>
    <loc>${esc(loc)}</loc>
    <lastmod>${lastmod}</lastmod>
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
  </url>`;
}

module.exports = async (req, res) => {
  const hoy = soloFecha();
  let negocios = [];

  try {
    const h = { headers: { apikey: SUPABASE_ANON, Authorization: 'Bearer ' + SUPABASE_ANON } };
    let r = await fetch(`${SUPABASE_URL}/rest/v1/negocios?select=slug,categoria,creado_en,nivel&order=nombre.asc`, h);
    // Si la columna `nivel` no existiera, se pide sin ella (todas cuentan como visibles)
    if (!r.ok) r = await fetch(`${SUPABASE_URL}/rest/v1/negocios?select=slug,categoria,creado_en&order=nombre.asc`, h);
    if (r.ok) {
      const filas = await r.json();
      // Nivel C = oculta: fuera del sitemap
      if (Array.isArray(filas)) negocios = filas.filter(n => n.nivel !== 'C');
    }
  } catch (e) {
    // Si Supabase falla seguimos publicando las páginas fijas: un sitemap
    // parcial es mucho mejor que devolver un error a Google.
  }

  const urls = [
    entrada(`${SITE_URL}/`,         hoy, 'daily',   '1.0'),
    entrada(`${SITE_URL}/registro`, hoy, 'monthly', '0.7'),
    entrada(`${SITE_URL}/destacados`, hoy, 'monthly', '0.6'),
    entrada(`${SITE_URL}/contacto`, hoy, 'monthly', '0.5'),
  ];

  // Una página por categoría que tenga negocios (evita publicar páginas vacías)
  const categoriasConNegocios = [...new Set(
    negocios.map(n => ANTIGUAS[n.categoria] || n.categoria).filter(Boolean)
  )].sort();

  for (const cat of categoriasConNegocios) {
    urls.push(entrada(`${SITE_URL}/categoria/${encodeURIComponent(cat)}`, hoy, 'weekly', '0.8'));
  }

  // Una página por negocio con slug
  for (const n of negocios) {
    if (!n.slug) continue;
    urls.push(entrada(
      `${SITE_URL}/negocio/${encodeURIComponent(n.slug)}`,
      soloFecha(n.creado_en),
      'weekly',
      '0.9'
    ));
  }

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>
`;

  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/xml; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate=86400');
  res.end(xml);
};
