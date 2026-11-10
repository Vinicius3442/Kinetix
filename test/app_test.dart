import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kinetix/data/models/models.dart';
import 'package:kinetix/data/providers.dart';
import 'package:kinetix/data/repositories/demo_repository.dart';
import 'package:kinetix/data/repositories/kinetix_repository.dart';
import 'package:kinetix/features/shipment_detail/cargo_readout.dart';
import 'package:kinetix/features/shipment_detail/qr_sheet.dart';
import 'package:kinetix/main.dart';

Future<void> pumpFor(WidgetTester t, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('DemoRepository', () {
    late DemoRepository repo;
    setUp(() => repo = DemoRepository(autoTick: false));
    tearDown(() => repo.dispose());

    test('motorista só vê as cargas dele', () async {
      await repo.signIn('motorista@kinetix.app', 'kinetix');
      final list = await repo.watchShipments().first;
      expect(list.map((s) => s.code), containsAll(['TC-8902', 'TC-5120']));
      expect(list.map((s) => s.code), isNot(contains('TC-7741')));
    });

    test('gestor vê todas e pode cadastrar', () async {
      await repo.signIn('gestor@kinetix.app', 'kinetix');
      expect(await repo.watchShipments().first, hasLength(4));
      final s = await repo.createShipment(ShipmentDraft(code: 'tc-1', description: 'Teste', origin: 'A', destination: 'B'));
      expect(s.code, 'TC-1');
      expect(s.status, ShipmentStatus.preparing);
    });

    test('não deixa usar a mesma caixa em duas cargas ativas', () async {
      await repo.signIn('gestor@kinetix.app', 'kinetix');
      expect(
        () => repo.createShipment(ShipmentDraft(code: 'X', description: 'x', origin: 'a', destination: 'b', deviceId: 'kx-01')),
        throwsA(isA<KxException>()),
      );
    });

    test('ocorrência simulada derruba o score e vira alerta', () async {
      await repo.signIn('gestor@kinetix.app', 'kinetix');
      final before = (await repo.watchShipments().first).firstWhere((s) => s.code == 'TC-8902').score;
      repo.simulate('kx-01', SimIncident.opening);
      repo.tick();
      final after = (await repo.watchShipments().first).firstWhere((s) => s.code == 'TC-8902').score;
      expect(after, before - 25);
      final alerts = await repo.watchAlerts().first;
      expect(alerts.first.type, EventType.opening);
      await repo.acknowledge(alerts.first.id!);
      expect((await repo.watchAlerts().first).where((a) => a.type == EventType.opening), isEmpty);
    });

    test('recebimento pelo QR fecha a carga e não aceita duas vezes', () async {
      final summary = await repo.receiptSummary('demo-tc8902');
      expect(summary!.shipment.code, 'TC-8902');
      expect(summary.receipt, isNull);
      final done = await repo.confirmReceipt(token: 'demo-tc8902', signer: 'Ana', signatureSvg: '<svg/>', approved: true);
      expect(done.receipt!.approved, isTrue);
      expect(done.shipment.status, ShipmentStatus.delivered);
      expect(done.events.last.type, EventType.delivery);
      expect(
        () => repo.confirmReceipt(token: 'demo-tc8902', signer: 'Ana', signatureSvg: null, approved: true),
        throwsA(isA<KxException>()),
      );
    });

    test('só admin muda perfis', () async {
      await repo.signIn('gestor@kinetix.app', 'kinetix');
      final users = await repo.watchProfiles().first;
      expect(() => repo.setRole(users.first.id, UserRole.admin), throwsA(isA<KxException>()));
    });
  });

  group('QR Code', () {
    test('lê link, código com prefixo e código puro', () {
      expect(tokenFromScan('https://kinetix.app/#/r/abc123def'), 'abc123def');
      expect(tokenFromScan('KINETIX:abc123def'), 'abc123def');
      expect(tokenFromScan('demo-tc8902'), 'demo-tc8902');
      expect(tokenFromScan('olá mundo'), isNull);
    });
  });

  group('CargoReadout', () {
    Telemetry t({double roll = 0, double light = 2, double temp = 22, double peak = 1}) =>
        Telemetry(deviceId: 'kx', ts: DateTime.now(), roll: roll, light: light, temp: temp, peakG: peak);

    test('traduz os números em frases simples', () {
      const l = CargoLimits();
      expect(CargoReadout(t(), l).positionLabel, 'Em pé');
      expect(CargoReadout(t(roll: 40), l).positionLabel, 'Inclinada');
      expect(CargoReadout(t(roll: 75), l).positionLabel, 'Tombada');
      expect(CargoReadout(t(light: 60), l).sealLabel, 'Aberta');
      expect(CargoReadout(t(temp: 35), l).climateLabel, 'Quente demais');
      expect(CargoReadout(t(peak: 3), l).motionLabel, 'Impacto agora');
      expect(CargoReadout(t(), l).anyAlert, isFalse);
    });

    test('estado da conexão', () {
      final now = DateTime.now();
      expect(LinkState.of(now, now: now), LinkState.live);
      expect(LinkState.of(now.subtract(const Duration(seconds: 20)), now: now), LinkState.delayed);
      expect(LinkState.of(now.subtract(const Duration(minutes: 2)), now: now), LinkState.offline);
      expect(LinkState.of(null), LinkState.waiting);
    });
  });

  testWidgets('entra pelo atalho de demonstração e abre uma carga', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = DemoRepository(autoTick: false);
    addTearDown(repo.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const KinetixApp(),
    ));
    await pumpFor(tester);
    expect(find.text('Entrar'), findsWidgets);

    await tester.tap(find.text('Gestor logístico'));
    await pumpFor(tester, 1200);
    expect(find.text('Cargas da operação'), findsOneWidget);
    expect(find.text('TC-8902'), findsOneWidget);

    await tester.tap(find.text('Vacinas termossensíveis'));
    await pumpFor(tester, 1200);
    expect(find.text('GÊMEO DIGITAL'), findsOneWidget);
    expect(find.text('SCORE DE INTEGRIDADE'), findsOneWidget);
    expect(find.text('Atenção'), findsWidgets);
  });
}
