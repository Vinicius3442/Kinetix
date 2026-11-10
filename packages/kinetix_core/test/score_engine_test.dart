import 'package:kinetix_core/kinetix_core.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 11, 10, 14, 0, 0);

Telemetry reading(int sec,
        {double roll = 0, double pitch = 0, double peak = 1, double light = 2, double temp = 22, double hum = 50}) =>
    Telemetry(
      deviceId: 'kx-01',
      ts: t0.add(Duration(seconds: sec)),
      roll: roll,
      pitch: pitch,
      peakG: peak,
      light: light,
      temp: temp,
      hum: hum,
    );

void main() {
  group('ScoreEngine', () {
    test('viagem tranquila mantém 100', () {
      final e = ScoreEngine();
      for (var s = 0; s < 120; s++) {
        expect(e.process(reading(s)), isEmpty);
      }
      expect(e.score, 100);
    });

    test('impacto desconta pela gravidade', () {
      final e = ScoreEngine();
      expect(e.process(reading(1, peak: 2.2)).single.penalty, 5);
      expect(e.process(reading(5, peak: 3.5)).single.title, 'Impacto forte');
      final severe = e.process(reading(9, peak: 5)).single;
      expect(severe.severity, Severity.critical);
      expect(e.score, 100 - 5 - 10 - 20);
      expect(severe.scoreAfter, e.score);
    });

    test('impactos colados contam uma vez só', () {
      final e = ScoreEngine();
      e.process(reading(1, peak: 2.5));
      expect(e.process(reading(2, peak: 2.5)), isEmpty);
      expect(e.process(reading(4, peak: 2.5)), hasLength(1));
    });

    test('caixa aberta por muito tempo desconta uma vez (não zera o score)', () {
      final e = ScoreEngine();
      final events = <CargoEvent>[];
      for (var s = 0; s < 300; s++) {
        events.addAll(e.process(reading(s, light: 80)));
      }
      expect(events, hasLength(1));
      expect(events.single.type, EventType.opening);
      expect(e.score, 75);
    });

    test('nova abertura depois de fechar por 5 s conta de novo', () {
      final e = ScoreEngine();
      e.process(reading(0, light: 80));
      for (var s = 1; s <= 6; s++) {
        e.process(reading(s, light: 1));
      }
      expect(e.process(reading(7, light: 80)), hasLength(1));
      expect(e.score, 50);
    });

    test('piscada de escuro não encerra o episódio', () {
      final e = ScoreEngine();
      e.process(reading(0, light: 80));
      e.process(reading(1, light: 1));
      expect(e.process(reading(2, light: 80)), isEmpty);
    });

    test('inclinação e tombamento', () {
      final e = ScoreEngine();
      final a = e.process(reading(0, roll: 35));
      expect(a.single.title, 'Caixa inclinada');
      final b = e.process(reading(1, roll: 70));
      expect(b.single.title, 'Caixa tombada');
      expect(e.process(reading(2, roll: 80)), isEmpty);
      expect(e.score, 85);
    });

    test('inclinação combina roll e pitch', () {
      expect(reading(0, roll: 25, pitch: 25).tiltDeg, greaterThan(30));
    });

    test('temperatura fora da faixa e crítica', () {
      final e = ScoreEngine(limits: const CargoLimits(tempMin: 2, tempMax: 8));
      expect(e.process(reading(0, temp: 9)).single.title, 'Temperatura fora da faixa');
      expect(e.process(reading(1, temp: 14)).single.title, 'Temperatura crítica');
      expect(e.process(reading(2, temp: 15)), isEmpty);
      final cold = ScoreEngine(limits: const CargoLimits(tempMin: 2, tempMax: 8));
      expect(cold.process(reading(0, temp: 1)).single.detail, contains('fria'));
    });

    test('umidade alta', () {
      final e = ScoreEngine(limits: const CargoLimits(humMax: 70));
      expect(e.process(reading(0, hum: 85)).single.type, EventType.humidity);
      expect(e.score, 97);
    });

    test('score nunca fica negativo', () {
      final e = ScoreEngine(score: 10);
      e.process(reading(0, light: 90));
      expect(e.score, 0);
    });

    test('estado pode ser salvo e retomado', () {
      final e = ScoreEngine();
      e.process(reading(0, light: 90));
      final saved = e.state.toJson();
      final resumed = ScoreEngine(score: e.score, state: ScoreEngineState.fromJson(saved));
      expect(resumed.process(reading(1, light: 90)), isEmpty);
      expect(resumed.score, 75);
    });
  });

  group('Telemetry', () {
    test('lê o JSON do contrato v1', () {
      final t = Telemetry.fromJson({
        'device_id': 'kx-01',
        'ts': '2026-11-10T14:32:05Z',
        'roll': 1.5,
        'accel_g': 1.2,
        'peak_g': 2.4,
        'temp': 24.6,
        'light': 3,
        'buffered': true,
      });
      expect(t.deviceId, 'kx-01');
      expect(t.ts, DateTime.utc(2026, 11, 10, 14, 32, 5));
      expect(t.peakG, 2.4);
      expect(t.buffered, isTrue);
      expect(Telemetry.fromJson(t.toJson()).roll, 1.5);
    });

    test('peak_g nunca é menor que accel_g', () {
      expect(Telemetry.fromJson({'device_id': 'x', 'accel_g': 3, 'peak_g': 1}).peakG, 3);
    });

    test('tópicos', () {
      expect(KinetixTopics.telemetry('kx-01'), 'kinetix/v1/kx-01/telemetry');
      expect(KinetixTopics.deviceFrom('kinetix/v1/kx-01/status'), 'kx-01');
      expect(KinetixTopics.deviceFrom('outro/topico'), isNull);
    });
  });

  group('Simulador', () {
    test('roteiro gera cada tipo de ocorrência e o score cai sem zerar', () {
      final sim = TelemetrySimulator(deviceId: 'kx-01', start: t0);
      final e = ScoreEngine();
      final types = <EventType>{};
      for (var i = 0; i < TelemetrySimulator.cycle; i++) {
        types.addAll(e.process(sim.next()).map((ev) => ev.type));
      }
      expect(types, containsAll([EventType.impact, EventType.tilt, EventType.opening, EventType.temperature]));
      expect(e.score, inInclusiveRange(30, 80));
    });

    test('ocorrência manual', () {
      final sim = TelemetrySimulator(deviceId: 'kx-01', scripted: false, start: t0);
      final e = ScoreEngine();
      for (var i = 0; i < 10; i++) {
        e.process(sim.next());
      }
      expect(e.score, 100);
      sim.trigger(SimIncident.opening);
      expect(e.process(sim.next()).single.type, EventType.opening);
    });
  });
}
