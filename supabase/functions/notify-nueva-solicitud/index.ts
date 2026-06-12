// Supabase Edge Function — notify-nueva-solicitud
// Se dispara via Database Webhook cuando llega un INSERT en la tabla `solicitudes`.
// Envía un correo HTML a enmartinez1@outlook.com usando la API de Resend.
//
// Requiere el secret: RESEND_API_KEY (agregar en Supabase → Settings → Edge Functions → Secrets)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORREO_DESTINO = "enmartinez1@outlook.com";
const CORREO_ORIGEN  = "EnMartinez <onboarding@resend.dev>"; // cambiar luego si se verifica un dominio propio

serve(async (req: Request) => {
  // Verificación de método
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let payload: { record?: Record<string, unknown> };
  try {
    payload = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const r = payload.record;
  if (!r) {
    return new Response("No record in payload", { status: 400 });
  }

  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) {
    console.error("RESEND_API_KEY no configurada");
    return new Response("Server misconfiguration", { status: 500 });
  }

  // ── Construir el HTML del correo ──────────────────────────────────────────
  const destacado = r.solicita_destacado
    ? "⭐ <strong>SÍ quiere ser Negocio Destacado</strong>"
    : "No";

  const htmlBody = `
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f6f8; margin: 0; padding: 20px; }
  .card { background: #fff; border-radius: 12px; max-width: 600px; margin: 0 auto;
          padding: 28px 32px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
  h1 { color: #1a6b3c; font-size: 1.4rem; margin: 0 0 4px; }
  .sub { color: #6b7280; font-size: 0.88rem; margin: 0 0 24px; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 8px 10px; font-size: 0.9rem; vertical-align: top; }
  tr:nth-child(odd) td { background: #f0f7f2; }
  td:first-child { font-weight: 700; color: #374151; width: 38%; white-space: nowrap; }
  td:last-child  { color: #1f2937; }
  .section { margin: 20px 0 6px; font-size: 0.78rem; font-weight: 800;
             text-transform: uppercase; letter-spacing: .5px; color: #9ca3af; }
  .footer { margin-top: 24px; font-size: 0.78rem; color: #9ca3af; text-align: center; }
  .btn { display: inline-block; margin-top: 20px; background: #1a6b3c; color: #fff;
         text-decoration: none; padding: 10px 22px; border-radius: 8px;
         font-weight: 700; font-size: 0.9rem; }
</style></head>
<body>
<div class="card">
  <h1>📋 Nueva solicitud de negocio</h1>
  <p class="sub">Llegó una nueva solicitud en EnMartinez.com — revísala en el panel admin.</p>

  <div class="section">🏪 Datos del negocio</div>
  <table>
    <tr><td>Nombre</td><td>${r.nombre ?? "—"}</td></tr>
    <tr><td>Categoría</td><td>${r.categoria ?? "—"}</td></tr>
    <tr><td>Dirección</td><td>${r.direccion ?? "—"}</td></tr>
    <tr><td>Horario</td><td>${r.horario ?? "—"}</td></tr>
    <tr><td>Descripción</td><td>${r.descripcion ?? "—"}</td></tr>
  </table>

  <div class="section">📞 Contacto público</div>
  <table>
    <tr><td>Teléfono</td><td>${r.telefono ?? "—"}</td></tr>
    <tr><td>WhatsApp</td><td>${r.whatsapp || "No proporcionado"}</td></tr>
    <tr><td>Facebook</td><td>${r.facebook || "No proporcionado"}</td></tr>
    <tr><td>Sitio web</td><td>${r.web || "No proporcionado"}</td></tr>
  </table>

  <div class="section">⚙️ Servicios y pago</div>
  <table>
    <tr><td>Servicios</td><td>${r.servicios || "No especificado"}</td></tr>
    <tr><td>Métodos de pago</td><td>${r.metodospago ?? "—"}</td></tr>
  </table>

  <div class="section">⭐ Destacado</div>
  <table>
    <tr><td>¿Quiere destacado?</td><td>${destacado}</td></tr>
  </table>

  <div class="section">👤 Propietario (privado)</div>
  <table>
    <tr><td>Nombre</td><td>${r.propietario ?? "—"}</td></tr>
    <tr><td>Correo</td><td>${r.email_contacto ?? "—"}</td></tr>
    <tr><td>Celular</td><td>${r.celular_contacto ?? "—"}</td></tr>
  </table>

  <a class="btn" href="https://enmartinez-directorio.vercel.app/admin.html">Ir al panel admin →</a>

  <div class="footer">EnMartinez.com · Martínez de la Torre, Veracruz</div>
</div>
</body>
</html>`;

  // ── Llamada a Resend API ─────────────────────────────────────────────────
  const resendRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from:    CORREO_ORIGEN,
      to:      [CORREO_DESTINO],
      subject: `📋 Nueva solicitud: ${r.nombre ?? "sin nombre"}`,
      html:    htmlBody,
    }),
  });

  const resendBody = await resendRes.text();

  if (!resendRes.ok) {
    console.error("Error Resend:", resendRes.status, resendBody);
    return new Response(`Resend error: ${resendBody}`, { status: 500 });
  }

  console.log("Correo enviado OK:", resendBody);
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
