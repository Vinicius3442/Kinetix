import 'dart:math' as math;

import 'cargo_event.dart';
import 'cargo_limits.dart';
import 'telemetry.dart';

/// Motor do Score de Integridade.
///
/// O score começa em 100 e cada **ocorrência** desconta pontos uma única vez,
/// conforme a gravidade. Uma ocorrência longa (ex.: caixa aberta por 2 minutos)
/// conta como um só episódio: só volta a descontar depois que a situação se
/// normaliza por alguns segundos. Isso evita que leituras repetidas zerem o
/// score, como acontecia no protótipo.
///
/// | Ocorrência                | Desconto                          |
/// |---------------------------|-----------------------------------|
/// | Impacto leve (≥ limite)   | 5  (forte ≥ 3 G: 10; severo ≥ 4,5 G: 20) |
/// | Caixa inclinada (≥ 30°)   | 8  (tombada ≥ 60°: +7)            |
/// | Caixa aberta (luz)        | 25                                |
/// | Temperatura fora da faixa | 5  (mais de 5 °C fora: +5)        |
/// | Umidade alta              | 3                                 |
class ScoreEngine {
  ScoreEngine({this.limits = const CargoLimits(), double score = 100, ScoreEngineState? state})
      : _score = score.clamp(0, 100).toDouble(),
        _s = state ?? ScoreEngineState();

  final CargoLimits limits;
  double _score;
  final ScoreEngineState _s;

  /// Intervalo mínimo entre dois impactos distintos.
  static const impactGap = Duration(seconds: 2);

  /// Tempo em situação normal para encerrar um episódio.
  static const clearAfter = Duration(seconds: 5);
  static const tempClearAfter = Duration(seconds: 10);

  double get score => _score;
  ScoreEngineState get state => _s;

  /// Processa uma leitura e devolve as novas ocorrências (pode ser vazio).
  List<CargoEvent> process(Telemetry t) {
    final out = <CargoEvent>[];
    _impact(t, out);
    _tilt(t, out);
    _opening(t, out);
    _temperature(t, out);
    _humidity(t, out);
    return out;
  }

  // ---------------------------------------------------------------- regras

  void _impact(Telemetry t, List<CargoEvent> out) {
    if (t.peakG < limits.impactG) return;
    final last = _s.lastImpact;
    if (last != null && t.ts.difference(last).abs() < impactGap) return;
    _s.lastImpact = t.ts;
    final g = t.peakG;
    final (penalty, sev, title) = g >= 4.5
        ? (20.0, Severity.critical, 'Impacto severo')
        : g >= 3.0
            ? (10.0, Severity.warning, 'Impacto forte')
            : (5.0, Severity.warning, 'Impacto leve');
    out.add(_event(t, EventType.impact, sev, title, 'A caixa sofreu um solavanco de ${_fmt(g, 1)} G.', g, penalty));
  }

  void _tilt(Telemetry t, List<CargoEvent> out) {
    final deg = t.tiltDeg;
    final ep = _s.tilt;
    if (deg >= limits.tiltDeg) {
      ep.lastAbnormal = t.ts;
      if (!ep.active) {
        ep.active = true;
        ep.level = 0;
        out.add(_event(t, EventType.tilt, Severity.warning, 'Caixa inclinada',
            'A caixa ficou inclinada ${deg.round()}° fora da posição em pé.', deg, 8));
      }
      if (deg >= 60 && ep.level < 1) {
        ep.level = 1;
        out.add(
            _event(t, EventType.tilt, Severity.critical, 'Caixa tombada', 'A caixa tombou (${deg.round()}°). Verifique a carga.', deg, 7));
      }
    } else if (ep.active && deg < limits.tiltDeg - 5 && _cleared(ep, t, clearAfter)) {
      ep.active = false;
    }
  }

  void _opening(Telemetry t, List<CargoEvent> out) {
    final ep = _s.opening;
    if (t.light >= limits.lightPct) {
      ep.lastAbnormal = t.ts;
      if (!ep.active) {
        ep.active = true;
        out.add(_event(t, EventType.opening, Severity.critical, 'Caixa aberta',
            'Entrou luz dentro da caixa: o lacre pode ter sido violado.', t.light, 25));
      }
    } else if (ep.active && t.light < limits.lightPct - 5 && _cleared(ep, t, clearAfter)) {
      ep.active = false;
    }
  }

  void _temperature(Telemetry t, List<CargoEvent> out) {
    final temp = t.temp;
    if (temp == null) return;
    final ep = _s.temperature;
    final above = temp > limits.tempMax, below = temp < limits.tempMin;
    if (above || below) {
      ep.lastAbnormal = t.ts;
      final off = above ? temp - limits.tempMax : limits.tempMin - temp;
      final word = above ? 'quente' : 'fria';
      final range = '${_fmt(limits.tempMin, 0)}–${_fmt(limits.tempMax, 0)} °C';
      if (!ep.active) {
        ep.active = true;
        ep.level = 0;
        out.add(_event(t, EventType.temperature, Severity.warning, 'Temperatura fora da faixa',
            'A carga ficou $word: ${_fmt(temp, 1)} °C (faixa segura $range).', temp, 5));
      }
      if (off > 5 && ep.level < 1) {
        ep.level = 1;
        out.add(_event(t, EventType.temperature, Severity.critical, 'Temperatura crítica',
            'A carga está muito $word: ${_fmt(temp, 1)} °C (faixa segura $range).', temp, 5));
      }
    } else if (ep.active && temp <= limits.tempMax - 0.5 && temp >= limits.tempMin + 0.5 && _cleared(ep, t, tempClearAfter)) {
      ep.active = false;
    }
  }

  void _humidity(Telemetry t, List<CargoEvent> out) {
    final hum = t.hum;
    if (hum == null) return;
    final ep = _s.humidity;
    if (hum > limits.humMax) {
      ep.lastAbnormal = t.ts;
      if (!ep.active) {
        ep.active = true;
        out.add(_event(t, EventType.humidity, Severity.warning, 'Umidade alta',
            'O ar dentro da caixa chegou a ${hum.round()}% de umidade (máximo ${limits.humMax.round()}%).', hum, 3));
      }
    } else if (ep.active && hum < limits.humMax - 3 && _cleared(ep, t, tempClearAfter)) {
      ep.active = false;
    }
  }

  // ---------------------------------------------------------------- apoio

  /// Encerra o episódio só depois de [after] em situação normal.
  bool _cleared(Episode ep, Telemetry t, Duration after) {
    ep.normalSince ??= t.ts;
    final ok = t.ts.difference(ep.normalSince!) >= after;
    if (ok) ep.normalSince = null;
    return ok;
  }

  CargoEvent _event(Telemetry t, EventType type, Severity sev, String title, String detail, double value, double penalty) {
    _score = math.max(0, _score - penalty);
    return CargoEvent(
      deviceId: t.deviceId,
      ts: t.ts,
      type: type,
      severity: sev,
      title: title,
      detail: detail,
      value: value,
      penalty: penalty,
      scoreAfter: _score,
      lat: t.lat,
      lng: t.lng,
      roll: t.roll,
      pitch: t.pitch,
      yaw: t.yaw,
      buffered: t.buffered,
    );
  }

  static String _fmt(double v, int places) => v.toStringAsFixed(places).replaceAll('.', ',');
}

/// Estado de um episódio (ocorrência contínua).
class Episode {
  bool active = false;
  int level = 0;
  DateTime? lastAbnormal;
  DateTime? normalSince;

  Map<String, dynamic> toJson() => {
        'active': active,
        'level': level,
        'last_abnormal': lastAbnormal?.toIso8601String(),
        'normal_since': normalSince?.toIso8601String(),
      };

  static Episode fromJson(Map<String, dynamic>? j) {
    final e = Episode();
    if (j == null) return e;
    e.active = j['active'] == true;
    e.level = (j['level'] as num?)?.toInt() ?? 0;
    e.lastAbnormal = j['last_abnormal'] == null ? null : DateTime.tryParse(j['last_abnormal']);
    e.normalSince = j['normal_since'] == null ? null : DateTime.tryParse(j['normal_since']);
    return e;
  }
}

/// Estado completo do motor, serializável para ser salvo no banco e
/// retomado se o serviço ponte reiniciar.
class ScoreEngineState {
  ScoreEngineState();

  DateTime? lastImpact;
  Episode tilt = Episode();
  Episode opening = Episode();
  Episode temperature = Episode();
  Episode humidity = Episode();

  Map<String, dynamic> toJson() => {
        'last_impact': lastImpact?.toIso8601String(),
        'tilt': tilt.toJson(),
        'opening': opening.toJson(),
        'temperature': temperature.toJson(),
        'humidity': humidity.toJson(),
      };

  factory ScoreEngineState.fromJson(Map<String, dynamic>? j) {
    final s = ScoreEngineState();
    if (j == null) return s;
    s.lastImpact = j['last_impact'] == null ? null : DateTime.tryParse(j['last_impact']);
    s.tilt = Episode.fromJson(j['tilt'] as Map<String, dynamic>?);
    s.opening = Episode.fromJson(j['opening'] as Map<String, dynamic>?);
    s.temperature = Episode.fromJson(j['temperature'] as Map<String, dynamic>?);
    s.humidity = Episode.fromJson(j['humidity'] as Map<String, dynamic>?);
    return s;
  }
}
