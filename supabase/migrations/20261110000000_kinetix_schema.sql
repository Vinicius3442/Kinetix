-- =============================================================================
-- KINETIX — Schema do banco (Supabase / PostgreSQL)
-- Como aplicar: Supabase → SQL Editor → cole este arquivo inteiro → Run.
-- Depois rode supabase/seed.sql para criar caixas e cargas de exemplo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tipos
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum ('admin', 'gestor', 'motorista', 'destinatario');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.shipment_status as enum ('preparando', 'em_transito', 'entregue', 'recusada');
exception when duplicate_object then null; end $$;

-- -----------------------------------------------------------------------------
-- 2. Tabelas
-- -----------------------------------------------------------------------------

-- Perfil de cada usuário (1:1 com auth.users)
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  email       text,
  role        public.user_role not null default 'motorista',
  company     text default 'TransCargo Express',
  phone       text,
  onboarded   boolean not null default false,
  created_at  timestamptz not null default now()
);

-- Caixas Kinetix (módulos embarcados). O id é o DEVICE_ID do firmware.
create table if not exists public.devices (
  id              text primary key,
  name            text not null,
  status          text not null default 'offline' check (status in ('online', 'offline')),
  last_seen       timestamptz,
  battery         int,
  rssi            int,
  firmware        text,
  last_telemetry  jsonb,
  created_at      timestamptz not null default now()
);

-- Cargas (uma viagem de uma caixa)
create table if not exists public.shipments (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique,
  description      text not null,
  category         text not null default 'Geral',
  origin           text not null,
  destination      text not null,
  device_id        text references public.devices (id) on delete set null,
  driver_id        uuid references public.profiles (id) on delete set null,
  vehicle_plate    text,
  recipient_name   text,
  status           public.shipment_status not null default 'preparando',
  score            numeric(5, 2) not null default 100 check (score between 0 and 100),
  -- faixas seguras desta carga
  temp_min         numeric not null default 15,
  temp_max         numeric not null default 30,
  hum_max          numeric not null default 80,
  impact_g         numeric not null default 2.0,
  tilt_deg         numeric not null default 30,
  light_pct        numeric not null default 20,
  -- estado do motor do score (mantido pelo serviço ponte)
  engine_state     jsonb,
  qr_token         text not null unique default replace(gen_random_uuid()::text, '-', ''),
  started_at       timestamptz,
  delivered_at     timestamptz,
  created_by       uuid references public.profiles (id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Uma caixa só pode estar em uma carga ativa por vez
create unique index if not exists shipments_one_active_per_device
  on public.shipments (device_id)
  where status in ('preparando', 'em_transito');

create index if not exists shipments_driver_idx on public.shipments (driver_id);

-- Leituras de telemetria (histórico; o serviço ponte grava ~1 a cada 5 s)
create table if not exists public.readings (
  id           bigint generated always as identity primary key,
  shipment_id  uuid references public.shipments (id) on delete cascade,
  device_id    text not null,
  ts           timestamptz not null,
  roll         real, pitch real, yaw real,
  accel_g      real, peak_g real,
  temp         real, hum real, light real,
  lat          double precision, lng double precision,
  battery      int,
  buffered     boolean not null default false
);
create index if not exists readings_shipment_ts_idx on public.readings (shipment_id, ts desc);

-- Ocorrências (impacto, abertura, temperatura...) com texto pronto para o usuário
create table if not exists public.events (
  id               bigint generated always as identity primary key,
  shipment_id      uuid references public.shipments (id) on delete cascade,
  device_id        text not null,
  ts               timestamptz not null,
  type             text not null check (type in ('impact', 'tilt', 'opening', 'temperature', 'humidity', 'connection', 'delivery')),
  severity         text not null check (severity in ('info', 'warning', 'critical')),
  title            text not null,
  detail           text not null default '',
  value            double precision,
  penalty          double precision not null default 0,
  score_after      double precision,
  lat              double precision, lng double precision,
  roll             real, pitch real, yaw real,
  buffered         boolean not null default false,
  acknowledged_at  timestamptz,
  acknowledged_by  uuid references public.profiles (id) on delete set null,
  created_at       timestamptz not null default now()
);
create index if not exists events_shipment_ts_idx on public.events (shipment_id, ts desc);

-- Comprovante de recebimento (assinatura do destinatário via QR Code)
create table if not exists public.receipts (
  id             uuid primary key default gen_random_uuid(),
  shipment_id    uuid not null unique references public.shipments (id) on delete cascade,
  signer_name    text not null,
  signature_svg  text,
  approved       boolean not null,
  notes          text,
  signed_at      timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 3. Funções de apoio
-- -----------------------------------------------------------------------------
create or replace function public.my_role() returns public.user_role
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('admin', 'gestor') from public.profiles where id = auth.uid()), false)
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false)
$$;

create or replace function public.can_see_shipment(sid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_staff() or exists (
    select 1 from public.shipments s where s.id = sid and s.driver_id = auth.uid()
  )
$$;

-- updated_at automático
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at := now(); return new; end $$;

drop trigger if exists shipments_touch on public.shipments;
create trigger shipments_touch before update on public.shipments
  for each row execute function public.touch_updated_at();

-- Cria o perfil quando alguém se cadastra. O PRIMEIRO usuário vira admin.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.email,
    case when exists (select 1 from public.profiles) then 'motorista'::public.user_role
         else 'admin'::public.user_role end
  );
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 4. RPCs (ações chamadas pelo app)
-- -----------------------------------------------------------------------------

-- Admin muda o perfil de acesso de alguém
create or replace function public.set_user_role(target uuid, new_role public.user_role) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Apenas administradores podem mudar perfis.'; end if;
  if target = auth.uid() and new_role <> 'admin' then
    raise exception 'Você não pode remover o seu próprio acesso de administrador.';
  end if;
  update public.profiles set role = new_role where id = target;
end $$;

-- Motorista ou gestor inicia a viagem
create or replace function public.start_shipment(sid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.can_see_shipment(sid) then raise exception 'Sem permissão para esta carga.'; end if;
  update public.shipments
     set status = 'em_transito', started_at = coalesce(started_at, now())
   where id = sid and status = 'preparando';
end $$;

-- Marca uma ocorrência como "vista / tratada"
create or replace function public.acknowledge_event(eid bigint) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
  select shipment_id into sid from public.events where id = eid;
  if sid is null or not public.can_see_shipment(sid) then raise exception 'Sem permissão.'; end if;
  update public.events set acknowledged_at = now(), acknowledged_by = auth.uid()
   where id = eid and acknowledged_at is null;
end $$;

-- PÚBLICO: resumo da carga a partir do QR Code (destinatário não precisa de conta)
create or replace function public.get_receipt_summary(token text) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare s public.shipments; result jsonb;
begin
  select * into s from public.shipments where qr_token = token;
  if not found then return null; end if;
  select jsonb_build_object(
    'shipment', jsonb_build_object(
      'id', s.id, 'code', s.code, 'description', s.description, 'category', s.category,
      'origin', s.origin, 'destination', s.destination, 'status', s.status, 'score', s.score,
      'device_id', s.device_id, 'vehicle_plate', s.vehicle_plate, 'recipient_name', s.recipient_name,
      'temp_min', s.temp_min, 'temp_max', s.temp_max, 'hum_max', s.hum_max,
      'started_at', s.started_at, 'delivered_at', s.delivered_at, 'qr_token', s.qr_token
    ),
    'events', coalesce((
      select jsonb_agg(to_jsonb(e) - 'acknowledged_by' order by e.ts)
        from public.events e where e.shipment_id = s.id
    ), '[]'::jsonb),
    'stats', (
      select jsonb_build_object(
        'readings', count(*), 'temp_min', min(temp), 'temp_max', max(temp),
        'hum_max', max(hum), 'peak_g', max(peak_g)
      ) from public.readings r where r.shipment_id = s.id
    ),
    'receipt', (select to_jsonb(r) from public.receipts r where r.shipment_id = s.id)
  ) into result;
  return result;
end $$;

-- PÚBLICO: destinatário assina e aprova (ou recusa) o recebimento
create or replace function public.confirm_receipt(
  token text, signer text, signature text, is_approved boolean, note text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare s public.shipments;
begin
  select * into s from public.shipments where qr_token = token for update;
  if not found then raise exception 'QR Code não encontrado.'; end if;
  if s.status in ('entregue', 'recusada') then raise exception 'Esta carga já foi recebida.'; end if;
  if coalesce(trim(signer), '') = '' then raise exception 'Informe o nome de quem está recebendo.'; end if;

  insert into public.receipts (shipment_id, signer_name, signature_svg, approved, notes)
  values (s.id, trim(signer), signature, is_approved, nullif(trim(note), ''));

  update public.shipments
     set status = case when is_approved then 'entregue'::public.shipment_status else 'recusada'::public.shipment_status end,
         delivered_at = now()
   where id = s.id;

  insert into public.events (shipment_id, device_id, ts, type, severity, title, detail, score_after)
  values (s.id, coalesce(s.device_id, '-'), now(), 'delivery',
          case when is_approved then 'info' else 'critical' end,
          case when is_approved then 'Recebimento aprovado' else 'Recebimento recusado' end,
          trim(signer) || case when is_approved then ' conferiu e aprovou a entrega.' else ' recusou a entrega.' end
            || coalesce(' Observação: ' || nullif(trim(note), ''), ''),
          s.score);

  return public.get_receipt_summary(token);
end $$;

-- -----------------------------------------------------------------------------
-- 5. Segurança (Row Level Security)
-- -----------------------------------------------------------------------------
alter table public.profiles  enable row level security;
alter table public.devices   enable row level security;
alter table public.shipments enable row level security;
alter table public.readings  enable row level security;
alter table public.events    enable row level security;
alter table public.receipts  enable row level security;

-- profiles: cada um vê o seu; gestor/admin veem todos. Só nome/telefone/empresa são editáveis.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff());
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated, anon;
grant update (full_name, phone, company, onboarded) on public.profiles to authenticated;

-- devices: todos os logados veem; gestor/admin gerenciam
drop policy if exists devices_select on public.devices;
create policy devices_select on public.devices for select to authenticated using (true);
drop policy if exists devices_write on public.devices;
create policy devices_write on public.devices for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- shipments: gestor/admin veem e editam tudo; motorista vê as cargas dele
drop policy if exists shipments_select on public.shipments;
create policy shipments_select on public.shipments for select to authenticated
  using (public.is_staff() or driver_id = auth.uid());
drop policy if exists shipments_write on public.shipments;
create policy shipments_write on public.shipments for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- readings / events / receipts: quem vê a carga vê o histórico (escrita só pelo serviço ponte e RPCs)
drop policy if exists readings_select on public.readings;
create policy readings_select on public.readings for select to authenticated
  using (public.can_see_shipment(shipment_id));
drop policy if exists events_select on public.events;
create policy events_select on public.events for select to authenticated
  using (public.can_see_shipment(shipment_id));
drop policy if exists receipts_select on public.receipts;
create policy receipts_select on public.receipts for select to authenticated
  using (public.can_see_shipment(shipment_id));

grant execute on function public.get_receipt_summary(text) to anon, authenticated;
grant execute on function public.confirm_receipt(text, text, text, boolean, text) to anon, authenticated;
revoke execute on function public.set_user_role(uuid, public.user_role) from anon;
revoke execute on function public.start_shipment(uuid) from anon;
revoke execute on function public.acknowledge_event(bigint) from anon;

-- -----------------------------------------------------------------------------
-- 6. Tempo real (o app recebe mudanças em < 2 s)
-- -----------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['shipments', 'events', 'devices', 'readings', 'profiles'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;
