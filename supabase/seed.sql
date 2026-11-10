-- =============================================================================
-- KINETIX — Dados de exemplo
-- Rode depois do schema. Pode rodar de novo: ele não duplica nada.
-- =============================================================================

-- Caixas (o id precisa ser igual ao DEVICE_ID do firmware / simulador)
insert into public.devices (id, name, firmware) values
  ('kx-01', 'Caixa Kinetix 01', 'esp32-wokwi 2.0'),
  ('kx-02', 'Caixa Kinetix 02', 'esp32-wokwi 2.0'),
  ('kx-03', 'Caixa Kinetix 03', 'esp32-wokwi 2.0')
on conflict (id) do nothing;

-- Cargas ativas (ligadas às caixas)
insert into public.shipments
  (code, description, category, origin, destination, device_id, vehicle_plate, recipient_name,
   status, temp_min, temp_max, hum_max, started_at, qr_token)
values
  ('TC-8902', 'Vacinas termossensíveis', 'Farmacêutico', 'São José dos Campos-SP', 'Taubaté-SP',
   'kx-01', 'FKT-3B21', 'Hospital Regional de Taubaté', 'em_transito', 15, 30, 80, now() - interval '2 hours', 'demo-tc8902'),
  ('TC-7741', 'Servidores e placas eletrônicas', 'Eletrônicos', 'São José dos Campos-SP', 'Taubaté-SP',
   'kx-02', 'GHT-9A10', 'Data Center Vale', 'em_transito', 10, 35, 70, now() - interval '40 minutes', 'demo-tc7741'),
  ('TC-6610', 'Lentes ópticas de precisão', 'Óptico', 'São José dos Campos-SP', 'Taubaté-SP',
   'kx-03', 'BRA-2E19', 'Óptica Paulista', 'preparando', 15, 30, 75, null, 'demo-tc6610')
on conflict (code) do nothing;

-- Uma carga já entregue, com histórico, para a tela de auditoria não começar vazia
with s as (
  insert into public.shipments
    (code, description, category, origin, destination, device_id, vehicle_plate, recipient_name,
     status, score, started_at, delivered_at, qr_token)
  values
    ('TC-5120', 'Medicamentos controlados', 'Farmacêutico', 'São José dos Campos-SP', 'Caçapava-SP',
     null, 'FKT-3B21', 'Farmácia Central', 'entregue', 87, now() - interval '1 day 4 hours', now() - interval '1 day 2 hours', 'demo-tc5120')
  on conflict (code) do nothing
  returning id
)
insert into public.events (shipment_id, device_id, ts, type, severity, title, detail, value, penalty, score_after, lat, lng, roll, pitch, yaw)
select s.id, 'kx-01', e.ts, e.type, e.severity, e.title, e.detail, e.value, e.penalty, e.score_after, e.lat, e.lng, e.roll, e.pitch, e.yaw
from s, (values
  (now() - interval '1 day 3 hours 40 minutes', 'impact', 'warning', 'Impacto forte', 'A caixa sofreu um solavanco de 3,2 G.', 3.2, 10, 90, -23.1712, -45.8392, 6.0, 1.0, 72.0),
  (now() - interval '1 day 3 hours 5 minutes', 'humidity', 'warning', 'Umidade alta', 'O ar dentro da caixa chegou a 84% de umidade (máximo 80%).', 84, 3, 87, -23.1418, -45.7896, 0.5, 0.2, 70.0)
) as e(ts, type, severity, title, detail, value, penalty, score_after, lat, lng, roll, pitch, yaw);

insert into public.receipts (shipment_id, signer_name, approved, notes, signed_at)
select id, 'Ana Souza', true, 'Conferido, embalagem íntegra.', now() - interval '1 day 2 hours'
from public.shipments where code = 'TC-5120'
on conflict (shipment_id) do nothing;
