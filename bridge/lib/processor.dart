import 'package:kinetix_core/kinetix_core.dart';

import 'store.dart';

/// Recebe as mensagens MQTT, calcula o score e grava no banco.
///
/// - Guarda uma leitura a cada [readingEvery] (e sempre que houver ocorrência),
///   para não encher o banco gratuito do Supabase.
/// - Registra quando a caixa perde e recupera o sinal, com quantas leituras
///   vieram da memória da placa (buffer offline).
class TelemetryProcessor {
  TelemetryProcessor(
    this.store, {
    this.readingEvery = const Duration(seconds: 5),
    this.shipmentCacheTtl = const Duration(seconds: 20),
    this.onScore,
    DateTime Function()? now,
    this.log = print,
  }) : _now = now ?? DateTime.now;

  final BridgeStore store;
  final Duration readingEvery;
  final Duration shipmentCacheTtl;

  /// Chamado quando o score muda (o serviço publica no tópico `score`).
  final void Function(String deviceId, double score)? onScore;
  final void Function(String) log;
  final DateTime Function() _now;

  final _devices = <String, _DeviceState>{};

  _DeviceState _dev(String id) => _devices.putIfAbsent(id, () => _DeviceState());

  Future<List<CargoEvent>> handleTelemetry(Telemetry t) async {
    final d = _dev(t.deviceId);
    final now = _now();

    // 1. status da caixa (no máximo a cada 2 s)
    if (d.lastDeviceUpdate == null || now.difference(d.lastDeviceUpdate!) >= const Duration(seconds: 2)) {
      d.lastDeviceUpdate = now;
      await store.upsertDevice(t.deviceId, {
        'status': 'online',
        'last_seen': now.toUtc().toIso8601String(),
        'battery': t.battery,
        'rssi': t.rssi,
        'last_telemetry': t.toJson(),
      });
    }

    // 2. carga ativa desta caixa
    final sh = await _shipment(t.deviceId, d, now);
    if (sh == null) return const [];

    // 3. score
    final engine = d.engine!;
    final scoreBefore = engine.score;
    final events = engine.process(t).map((e) => e.copyWithShipment(sh.id)).toList();

    // 4. sinal recuperado (buffer offline)
    final extra = <CargoEvent>[];
    if (t.buffered) {
      d.bufferedCount++;
    } else if (d.bufferedCount > 0) {
      extra.add(CargoEvent(
        shipmentId: sh.id,
        deviceId: t.deviceId,
        ts: t.ts,
        type: EventType.connection,
        severity: Severity.info,
        title: 'Sinal restabelecido',
        detail: 'A caixa ficou sem internet e enviou ${d.bufferedCount} leituras guardadas na memória. Nenhum dado foi perdido.',
        value: d.bufferedCount.toDouble(),
        scoreAfter: engine.score,
        lat: t.lat,
        lng: t.lng,
      ));
      d.bufferedCount = 0;
    }

    // 5. leitura para o histórico
    if (events.isNotEmpty || d.lastReading == null || t.ts.difference(d.lastReading!).abs() >= readingEvery) {
      d.lastReading = t.ts;
      await store.insertReadings([_readingRow(sh.id, t)]);
    }

    final saved = await store.insertEvents([...events, ...extra]);
    for (final e in events) {
      log('[${t.deviceId}] ${sh.code}: ${e.title} (-${e.penalty.toStringAsFixed(0)}) → score ${e.scoreAfter?.toStringAsFixed(0)}');
    }

    // 6. score e estado do motor na carga
    // (o estado também é salvo a cada 15 s, para retomar se o serviço reiniciar)
    final changed = engine.score != scoreBefore || events.isNotEmpty;
    if (changed || d.lastStateSave == null || now.difference(d.lastStateSave!) >= const Duration(seconds: 15)) {
      d.lastStateSave = now;
      await store.updateShipment(sh.id, {'score': engine.score, 'engine_state': engine.state.toJson()});
      if (changed) onScore?.call(t.deviceId, engine.score);
    }
    return saved;
  }

  Future<void> handleStatus(String deviceId, String status) async {
    final online = status.trim().toLowerCase() == 'online';
    final d = _dev(deviceId);
    await store.upsertDevice(deviceId, {
      'status': online ? 'online' : 'offline',
      if (online) 'last_seen': _now().toUtc().toIso8601String(),
    });
    if (online) return;
    final sh = await _shipment(deviceId, d, _now());
    if (sh == null) return;
    await store.insertEvents([
      CargoEvent(
        shipmentId: sh.id,
        deviceId: deviceId,
        ts: _now().toUtc(),
        type: EventType.connection,
        severity: Severity.warning,
        title: 'Caixa sem sinal',
        detail: 'A caixa perdeu a conexão. Ela continua registrando tudo e envia quando o sinal voltar.',
        scoreAfter: d.engine?.score,
      )
    ]);
  }

  Future<ActiveShipment?> _shipment(String deviceId, _DeviceState d, DateTime now) async {
    final fresh = d.shipmentCheckedAt != null && now.difference(d.shipmentCheckedAt!) < shipmentCacheTtl;
    if (fresh) return d.shipment;
    d.shipmentCheckedAt = now;
    final sh = await store.activeShipment(deviceId);
    if (sh?.id != d.shipment?.id) {
      d.engine = sh == null
          ? null
          : ScoreEngine(
              limits: sh.limits,
              score: sh.score,
              state: ScoreEngineState.fromJson(sh.engineState),
            );
      d.lastReading = null;
      if (sh != null) log('[$deviceId] monitorando a carga ${sh.code} (score ${sh.score.toStringAsFixed(0)})');
    }
    d.shipment = sh;
    return sh;
  }

  Map<String, dynamic> _readingRow(String shipmentId, Telemetry t) => {
        'shipment_id': shipmentId,
        'device_id': t.deviceId,
        'ts': t.ts.toUtc().toIso8601String(),
        'roll': t.roll,
        'pitch': t.pitch,
        'yaw': t.yaw,
        'accel_g': t.accelG,
        'peak_g': t.peakG,
        'temp': t.temp,
        'hum': t.hum,
        'light': t.light,
        'lat': t.lat,
        'lng': t.lng,
        'battery': t.battery,
        'buffered': t.buffered,
      };
}

class _DeviceState {
  ActiveShipment? shipment;
  DateTime? shipmentCheckedAt;
  ScoreEngine? engine;
  DateTime? lastReading;
  DateTime? lastDeviceUpdate;
  DateTime? lastStateSave;
  int bufferedCount = 0;
}

extension on CargoEvent {
  CargoEvent copyWithShipment(String id) => copyWith(shipmentId: id);
}
