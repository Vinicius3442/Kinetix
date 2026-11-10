import 'dart:math' as math;

/// Uma leitura enviada pela caixa (contrato MQTT v1).
///
/// JSON publicado em `kinetix/v1/{device_id}/telemetry`:
/// ```json
/// {
///   "v": 1, "device_id": "kx-01", "seq": 42,
///   "ts": "2026-11-10T14:32:05Z",
///   "roll": 1.2, "pitch": -0.4, "yaw": 87.0,
///   "accel_g": 1.01, "peak_g": 2.4,
///   "temp": 24.6, "hum": 55.0, "light": 3,
///   "lat": -23.1896, "lng": -45.8841,
///   "battery": 87, "rssi": -61, "buffered": false
/// }
/// ```
class Telemetry {
  const Telemetry({
    required this.deviceId,
    required this.ts,
    this.seq = 0,
    this.roll = 0,
    this.pitch = 0,
    this.yaw = 0,
    this.accelG = 1,
    this.peakG = 1,
    this.temp,
    this.hum,
    this.light = 0,
    this.lat,
    this.lng,
    this.battery,
    this.rssi,
    this.buffered = false,
  });

  final String deviceId;
  final DateTime ts;
  final int seq;

  /// Orientação da caixa em graus (MPU6050).
  final double roll;
  final double pitch;
  final double yaw;

  /// Aceleração total no momento da leitura, em G (1 G = parada).
  final double accelG;

  /// Maior aceleração registrada desde a leitura anterior, em G.
  /// É o valor usado para detectar impactos que acontecem entre leituras.
  final double peakG;

  /// Temperatura em °C e umidade relativa em % (DHT22).
  final double? temp;
  final double? hum;

  /// Luz dentro da caixa, de 0 (escuro) a 100 (claro) — LDR.
  final double light;

  final double? lat;
  final double? lng;

  /// Bateria em %.
  final int? battery;
  final int? rssi;

  /// `true` quando a leitura ficou guardada na memória da placa por falta de
  /// sinal e foi enviada depois.
  final bool buffered;

  /// Inclinação da caixa em relação à posição em pé, em graus.
  double get tiltDeg {
    final r = roll * math.pi / 180, p = pitch * math.pi / 180;
    final cosTilt = math.cos(r) * math.cos(p);
    return math.acos(cosTilt.clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  bool get hasLocation => lat != null && lng != null;

  factory Telemetry.fromJson(Map<String, dynamic> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    final tsRaw = j['ts'];
    DateTime ts;
    if (tsRaw is String) {
      ts = DateTime.tryParse(tsRaw)?.toUtc() ?? DateTime.now().toUtc();
    } else if (tsRaw is num) {
      ts = DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt() * 1000, isUtc: true);
    } else {
      ts = DateTime.now().toUtc();
    }
    final accel = d('accel_g') ?? 1;
    return Telemetry(
      deviceId: (j['device_id'] ?? '').toString(),
      ts: ts,
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      roll: d('roll') ?? 0,
      pitch: d('pitch') ?? 0,
      yaw: d('yaw') ?? 0,
      accelG: accel,
      peakG: math.max(d('peak_g') ?? accel, accel),
      temp: d('temp'),
      hum: d('hum'),
      light: d('light') ?? 0,
      lat: d('lat'),
      lng: d('lng'),
      battery: (j['battery'] as num?)?.toInt(),
      rssi: (j['rssi'] as num?)?.toInt(),
      buffered: j['buffered'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'device_id': deviceId,
        'seq': seq,
        'ts': ts.toUtc().toIso8601String(),
        'roll': _r(roll),
        'pitch': _r(pitch),
        'yaw': _r(yaw),
        'accel_g': _r(accelG, 2),
        'peak_g': _r(peakG, 2),
        if (temp != null) 'temp': _r(temp!),
        if (hum != null) 'hum': _r(hum!),
        'light': _r(light),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (battery != null) 'battery': battery,
        if (rssi != null) 'rssi': rssi,
        'buffered': buffered,
      };

  Telemetry copyWith({DateTime? ts, int? seq, bool? buffered}) => Telemetry(
        deviceId: deviceId,
        ts: ts ?? this.ts,
        seq: seq ?? this.seq,
        roll: roll,
        pitch: pitch,
        yaw: yaw,
        accelG: accelG,
        peakG: peakG,
        temp: temp,
        hum: hum,
        light: light,
        lat: lat,
        lng: lng,
        battery: battery,
        rssi: rssi,
        buffered: buffered ?? this.buffered,
      );

  static double _r(double v, [int places = 1]) {
    final f = math.pow(10, places);
    return (v * f).roundToDouble() / f;
  }
}
