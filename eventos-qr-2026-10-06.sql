-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez.com — Contar escaneos de códigos QR
--  Generado: 6 de octubre de 2026  (requiere eventos-2026-10-06.sql)
--
--  QUÉ RESUELVE:
--  Los QR impresos llevan a /qr (directorio) o /q/<negocio>. Al llegar
--  así se registra un evento tipo 'qr'. El del directorio no pertenece a
--  ningún negocio, por eso negocio_id ahora puede ir vacío.
--
--  CÓMO USARLO: SQL Editor → pegar todo → Run. Se puede repetir.
-- ═══════════════════════════════════════════════════════════════════

alter table public.eventos alter column negocio_id drop not null;

alter table public.eventos drop constraint if exists eventos_tipo_valido;
alter table public.eventos add constraint eventos_tipo_valido
  check (tipo in ('vista', 'whatsapp', 'llamar', 'como_llegar', 'compartir', 'web', 'facebook', 'qr'));

-- El resumen gana la columna qr (cambia el tipo de retorno: hay que recrearla)
drop function if exists public.resumen_eventos(timestamptz, timestamptz);

create function public.resumen_eventos(desde timestamptz, hasta timestamptz default now())
returns table (
  negocio_id bigint, vistas bigint, whatsapp bigint, llamar bigint,
  como_llegar bigint, compartir bigint, web bigint, facebook bigint, qr bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.es_admin_enmartinez() then
    raise exception 'Solo el administrador' using errcode = 'insufficient_privilege';
  end if;
  return query
    select e.negocio_id,
           count(*) filter (where e.tipo = 'vista'),
           count(*) filter (where e.tipo = 'whatsapp'),
           count(*) filter (where e.tipo = 'llamar'),
           count(*) filter (where e.tipo = 'como_llegar'),
           count(*) filter (where e.tipo = 'compartir'),
           count(*) filter (where e.tipo = 'web'),
           count(*) filter (where e.tipo = 'facebook'),
           count(*) filter (where e.tipo = 'qr')
      from public.eventos e
     where e.creado_en >= desde and e.creado_en < hasta
     group by e.negocio_id;   -- la fila con negocio_id vacío = QR del directorio
end;
$$;

revoke all on function public.resumen_eventos(timestamptz, timestamptz) from public, anon;
grant execute on function public.resumen_eventos(timestamptz, timestamptz) to authenticated;

notify pgrst, 'reload schema';
