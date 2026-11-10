import 'dart:convert';

import 'package:kinetix_bridge/processor.dart';
import 'package:kinetix_bridge/store.dart';
import 'package:kinetix_core/kinetix_core.dart';
import 'package:test/test.dart';

class FakeStore implements BridgeStore {
  ActiveShipment? shipment = ActiveShipment(id: 's1', code: 'TC-1', limits: const CargoLimits(), score: 100);
  final devices = <String, Map<String, dynamic>>{};
  final readings = <Map<String, dynamic>>[];
  final events = <CargoEvent>[];
  final updates = <Map<String, dynamic>>[];

  @override
  Future<ActiveShipment?> activeShipment(String deviceId) async => shipment;
  @override
  Future<void> upsertDevice(String deviceId, Map<String, dynamic> fields) async => devices[deviceId] = {...?devices[deviceId], ...fields};
  @override
  Future<void> insertReadings(List<Map<String, dynamic>> rows) async => readings.addAll(rows);
  @override
  Future<List<CargoEvent>> insertEvents(List<CargoEvent> e) async {
    events.addAll(e);
    return e;
  }

  @override
  Future<void> updateShipment(String shipmentId, Map<String, dynamic> fields) async => updates.add(fields);
}

final t0 = DateTime.utc(2026, 11, 10, 14);
Telemetry tel(int s, {double light = 1, bool buffered = false}) =>
    Telemetry(deviceId: 'kx-01', ts: t0.add(Duration(seconds: s)), light: light, temp: 22, hum: 50, buffered: buffered);

void main() {
  keyTests();
  late FakeStore store;
  late TelemetryProcessor p;
  var clock = t0;
  final scores = <double>[];

  setUp(() {
    store = FakeStore();
    scores.clear();
    clock = t0;
    p = TelemetryProcessor(store, now: () => clock, log: (_) {}, onScore: (_, s) => scores.add(s));
  });

  test('marca a caixa online e guarda leituras a cada 5 s', () async {
    for (var s = 0; s < 20; s++) {
      clock = t0.add(Duration(seconds: s));
      await p.handleTelemetry(tel(s));
    }
    expect(store.devices['kx-01']!['status'], 'online');
    expect(store.readings, hasLength(4));
    expect(store.events, isEmpty);
  });

  test('abertura gera ocorrência, atualiza score e publica', () async {
    await p.handleTelemetry(tel(0));
    final ev = await p.handleTelemetry(tel(1, light: 90));
    expect(ev.single.type, EventType.opening);
    expect(ev.single.shipmentId, 's1');
    expect(store.updates.last['score'], 75);
    expect(scores, [75]);
  });

  test('sem carga em trânsito não grava histórico', () async {
    store.shipment = null;
    await p.handleTelemetry(tel(0, light: 90));
    expect(store.readings, isEmpty);
    expect(store.events, isEmpty);
    expect(store.devices, contains('kx-01'));
  });

  test('registra quando o sinal volta com as leituras do buffer', () async {
    for (var s = 0; s < 5; s++) {
      await p.handleTelemetry(tel(s, buffered: true));
    }
    await p.handleTelemetry(tel(5));
    final e = store.events.single;
    expect(e.type, EventType.connection);
    expect(e.detail, contains('5 leituras'));
  });

  test('caixa offline gera aviso', () async {
    await p.handleStatus('kx-01', 'offline');
    expect(store.devices['kx-01']!['status'], 'offline');
    expect(store.events.single.title, 'Caixa sem sinal');
  });
}

String _jwt(String role) {
  String b(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b({'alg': 'HS256'})}.${b({'role': role})}.assinatura';
}

void keyTests() {
  test('aceita só a chave secreta', () {
    expect(SupabaseStore.checkServiceKey(_jwt('service_role')), isNull);
    expect(SupabaseStore.checkServiceKey('sb_secret_abc'), isNull);
    expect(SupabaseStore.checkServiceKey(_jwt('anon')), contains('"anon"'));
    expect(SupabaseStore.checkServiceKey('sb_publishable_abc'), contains('PÚBLICA'));
    expect(SupabaseStore.checkServiceKey('qualquer-coisa'), isNotNull);
  });
}
