# Configurar notificaciones de correo con Resend

Sigue estos pasos **en orden**. Tarda unos 10 minutos en total.

---

## PASO 1 — Crear cuenta en Resend y obtener API Key

1. Ve a **https://resend.com** y crea una cuenta gratuita (3,000 correos/mes gratis).
2. Una vez dentro, ve a **API Keys → Create API Key**.
3. Dale el nombre `EnMartinez` y permisos `Full access`.
4. **Copia la clave** — la necesitarás en el Paso 2. Solo se muestra una vez.

---

## PASO 2 — Agregar el secret en Supabase

1. Ve a tu proyecto en **https://supabase.com/dashboard** → proyecto **LaPastora**.
2. En el menú izquierdo: **Edge Functions → Secrets**.
3. Clic en **New secret**.
4. Nombre: `RESEND_API_KEY`
5. Valor: pega la clave de Resend.
6. Guarda.

---

## PASO 3 — Desplegar la Edge Function

### Opción A — Desde el dashboard (sin instalar nada)

1. En Supabase: **Edge Functions → New Function**.
2. Nombre: `notify-nueva-solicitud` (exactamente así, sin espacios).
3. Se abre un editor de código. **Borra todo** el contenido por defecto.
4. Copia y pega el contenido del archivo:
   `supabase/functions/notify-nueva-solicitud/index.ts`
5. Clic en **Deploy**.
6. Copia la **URL de la función** que aparece (algo como `https://ygeuqlohycckwngcmmxl.supabase.co/functions/v1/notify-nueva-solicitud`).

### Opción B — Desde la terminal (si tienes Supabase CLI)

```bash
supabase functions deploy notify-nueva-solicitud
```

---

## PASO 4 — Crear el Database Webhook

Esto hace que Supabase llame a la función automáticamente cada vez que llega una solicitud nueva.

1. En Supabase: **Database → Webhooks → Create a new hook**.
2. Configura así:
   - **Name:** `aviso-nueva-solicitud`
   - **Table:** `solicitudes`
   - **Events:** ✅ `INSERT` (solo este)
   - **Type:** `HTTP Request`
   - **Method:** `POST`
   - **URL:** la URL que copiaste en el Paso 3
   - **HTTP Headers:** agrega uno:
     - Key: `Authorization`
     - Value: `Bearer TU_SUPABASE_SERVICE_ROLE_KEY`
     
     *(La Service Role Key está en Supabase → Settings → API → service_role)*
3. Guarda el webhook.

---

## PASO 5 — Probar

1. Ve a **https://enmartinez-directorio.vercel.app/registro** y llena el formulario con datos de prueba.
2. Revisa tu correo `enmartinez1@outlook.com` — debería llegar en menos de 30 segundos.
3. Si no llega, ve a Supabase → Edge Functions → `notify-nueva-solicitud` → **Logs** para ver si hubo algún error.

---

## Notas

- El correo sale desde `onboarding@resend.dev` (dirección de prueba de Resend). Funciona perfecto para recibir notificaciones.
- Si en el futuro consigues un dominio propio (ej. `enmartinez.com`), puedes verificarlo en Resend y cambiar la dirección origen a `notificaciones@enmartinez.com`.
- Los datos de la solicitud siempre se guardan en Supabase, incluso si el correo falla.
