-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez.com — Endurecimiento de seguridad
--  Generado: 27 de julio de 2026
--
--  EL PROBLEMA QUE RESUELVE:
--  La política de la tabla `solicitudes` es "with check (true)": cualquiera
--  con la anon key (que es pública, y tiene que serlo) puede insertar filas
--  sin límite, con el contenido que quiera y en cualquier columna. Eso
--  permite tres cosas que no queremos:
--    a) inundar la tabla y agotar la cuota de Supabase,
--    b) mandar textos gigantes,
--    c) insertar solicitudes ya marcadas como `estado='aprobado'`,
--       que no aparecerían en tu lista de pendientes.
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--
--  Es seguro correrlo más de una vez.
--  Se puede correr antes o después de migracion-2026-07-27.sql, da igual.
-- ═══════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 1 — El remitente ya no decide el estado de su solicitud
-- ═══════════════════════════════════════════════════════════════════

-- Solo estos tres valores son válidos, vengan de donde vengan.
alter table public.solicitudes drop constraint if exists solicitudes_estado_valido;
alter table public.solicitudes add constraint solicitudes_estado_valido
  check (estado in ('pendiente','aprobado','rechazado'));


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 2 — Validación y freno de inserciones
-- ═══════════════════════════════════════════════════════════════════

create or replace function public.validar_solicitud_publica()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  ultimo_minuto int;
  ultima_hora   int;
  mismo_correo  int;
begin
  -- ── a) Toda solicitud nueva nace pendiente ──
  -- Aunque el remitente mande estado='aprobado', aquí se ignora.
  new.estado     := 'pendiente';
  new.creado_en  := now();

  -- ── b) El admin no pasa por los frenos de abajo ──
  if public.es_admin_enmartinez() then
    return new;
  end if;

  -- ── c) Campos mínimos con sentido ──
  if new.nombre is null or length(trim(new.nombre)) < 3 then
    raise exception 'El nombre del negocio es obligatorio.'
      using errcode = 'check_violation';
  end if;

  -- ── d) Límites de longitud ──
  -- Evita que alguien mande un texto de 10 MB por campo.
  if length(coalesce(new.nombre,''))       > 120  or
     length(coalesce(new.categoria,''))    > 40   or
     length(coalesce(new.direccion,''))    > 200  or
     length(coalesce(new.descripcion,''))  > 600  or
     length(coalesce(new.horario,''))      > 120  or
     length(coalesce(new.telefono,''))     > 30   or
     length(coalesce(new.whatsapp,''))     > 30   or
     length(coalesce(new.facebook,''))     > 300  or
     length(coalesce(new.web,''))          > 300  or
     length(coalesce(new.servicios,''))    > 500  or
     length(coalesce(new.metodospago,''))  > 120  or
     length(coalesce(new.propietario,''))  > 120  or
     length(coalesce(new.email_contacto,''))   > 160 or
     length(coalesce(new.celular_contacto,'')) > 30
  then
    raise exception 'Uno de los campos excede el largo permitido.'
      using errcode = 'check_violation';
  end if;

  -- ── e) Freno de inundación ──
  -- El sitio recibe unas pocas solicitudes al día. Estos topes no estorban
  -- al uso normal, pero cortan en seco un script que intente meter miles.
  select count(*) into ultimo_minuto
    from public.solicitudes where creado_en > now() - interval '1 minute';
  if ultimo_minuto >= 5 then
    raise exception 'Demasiadas solicitudes seguidas. Espera un minuto e intenta de nuevo.'
      using errcode = 'check_violation';
  end if;

  select count(*) into ultima_hora
    from public.solicitudes where creado_en > now() - interval '1 hour';
  if ultima_hora >= 40 then
    raise exception 'Demasiadas solicitudes en la última hora. Intenta más tarde.'
      using errcode = 'check_violation';
  end if;

  -- ── f) Tope por correo: nadie necesita registrar 5 negocios en una hora ──
  if new.email_contacto is not null and length(trim(new.email_contacto)) > 0 then
    select count(*) into mismo_correo
      from public.solicitudes
      where lower(email_contacto) = lower(trim(new.email_contacto))
        and creado_en > now() - interval '1 hour';
    if mismo_correo >= 3 then
      raise exception 'Ya enviaste varias solicitudes con este correo. Te contactaremos pronto.'
        using errcode = 'check_violation';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_solicitud_publica on public.solicitudes;
create trigger trg_validar_solicitud_publica
before insert on public.solicitudes
for each row execute function public.validar_solicitud_publica();


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 3 — search_path fijo en la función de admin
-- ═══════════════════════════════════════════════════════════════════
-- Sin search_path fijo, la resolución de nombres depende del contexto de
-- quien la llama. Aquí el riesgo es bajo porque la función no es
-- SECURITY DEFINER, pero es la recomendación de Supabase y su linter
-- lo marca como advertencia.

create or replace function public.es_admin_enmartinez()
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'pedromanterola2@gmail.com';
$$;


-- ═══════════════════════════════════════════════════════════════════
--  PARTE 4 — Índice para que el freno no sea lento
-- ═══════════════════════════════════════════════════════════════════
-- El trigger consulta por fecha en cada inserción; sin índice eso
-- empeora conforme crece la tabla.

create index if not exists solicitudes_creado_en_idx
  on public.solicitudes (creado_en desc);


-- ═══════════════════════════════════════════════════════════════════
--  VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════

-- 1. Debe insertar bien y quedar en 'pendiente' aunque pidamos 'aprobado':
insert into public.solicitudes (nombre, categoria, estado, email_contacto)
values ('PRUEBA SEGURIDAD — se borra abajo', 'test', 'aprobado', 'prueba@ejemplo.com');

select nombre, estado as "estado_debe_decir_pendiente"
  from public.solicitudes where nombre like 'PRUEBA SEGURIDAD%';

-- 2. Limpieza de la prueba:
delete from public.solicitudes where nombre like 'PRUEBA SEGURIDAD%';

-- 3. Resumen de lo aplicado:
select 'Constraint de estado' as control,
       count(*)::text as instalado
  from pg_constraint where conname = 'solicitudes_estado_valido'
union all
select 'Trigger de validación',
       count(*)::text from pg_trigger where tgname = 'trg_validar_solicitud_publica'
union all
select 'Índice de fecha',
       count(*)::text from pg_indexes where indexname = 'solicitudes_creado_en_idx';
