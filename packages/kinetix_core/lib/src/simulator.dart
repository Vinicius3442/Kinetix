import 'dart:math' as math;

import 'route.dart';
import 'telemetry.dart';

/// Ocorrências que podem ser provocadas manualmente no simulador
/// (botões "Simular" do modo demonstração).
enum SimIncident { impact, tilt, opening, heat, signalLoss }

/// Gera leituras realistas de uma caixa em viagem, uma por segundo.
///
/// Serve para apresentar o sistema sem a placa (modo demonstração do app e
/// `bridge/bin/simulate.dart`). Roda um roteiro que se repete a cada
/// [cycle] segundos com um impacto, uma inclinação, uma abertura, um pico de
/// calor e um trecho sem sinal. Também aceita ocorrências manuais com
/// [trigger].
class TelemetrySimulator {
  TelemetrySimulator({
    required this.deviceId,
    DemoRoute? route,
    this.tripSeconds = 1800,
    this.scripted = true,
    this.baseTemp = 22,
    int seed = 7,
    DateTime? start,
  })  : route = route ?? DemoRoute.dutra,
        _rnd = math.Random(seed),
        _clock = (start ?? DateTime.now()).toUtc();

  final String deviceId;
  final DemoRoute route;

  /// Duração da viagem da origem ao destino, em segundos (padrão: 30 min,
  /// ~83 km/h nos 41,5 km da Dutra). Ao chegar, o caminhão fica parado no destino.
  final int tripSeconds;

  /// Se `true`, roda o roteiro automático de ocorrências.
  final bool scripted;
  final double baseTemp;

  static const cycle = 240;

  final math.Random _rnd;
  DateTime _clock;
  int _t = 0;
  int _seq = 0;
  double _battery = 100;
  double _temp = 0;

  // ocorrências manuais: tipo -> segundos restantes
  final Map<SimIncident, int> _manual = {};
  bool _pendingImpact = false;

  int get elapsed => _t;

  /// `false` = caminhão parado na origem (carga ainda não saiu).
  bool driving = true;
  int _tripStart = 0;

  /// Começa a viagem agora, a partir da origem.
  void startTrip() {
    driving = true;
    _tripStart = _t;
  }

  void trigger(SimIncident i) {
    switch (i) {
      case SimIncident.impact:
        _pendingImpact = true;
      case SimIncident.tilt:
        _manual[i] = 9;
      case SimIncident.opening:
        _manual[i] = 7;
      case SimIncident.heat:
        _manual[i] = 40;
      case SimIncident.signalLoss:
        _manual[i] = 12;
    }
  }

  /// Avança um segundo e devolve a leitura.
  Telemetry next() {
    _t++;
    _seq++;
    _clock = _clock.add(const Duration(seconds: 1));
    final c = scripted ? _t % cycle : -1;
    bool on(SimIncident i) => (_manual[i] ?? 0) > 0;

    // balanço normal do caminhão
    var roll = math.sin(_t / 3.1) * 1.6 + _noise(0.4);
    var pitch = math.sin(_t / 4.7) * 1.1 + _noise(0.3);
    var accel = 1 + _noise(0.03).abs();
    var peak = accel + _rnd.nextDouble() * 0.25;

    // impacto
    if (c == 30 || _pendingImpact) {
      peak = _pendingImpact ? 3.4 + _rnd.nextDouble() : 3.2;
      accel = 1.6;
      roll += 6;
      _pendingImpact = false;
    }

    // inclinação: sobe até 45°, segura e volta
    final tiltPhase = on(SimIncident.tilt) ? 9 - _manual[SimIncident.tilt]! : (c >= 70 && c < 79 ? c - 70 : -1);
    if (tiltPhase >= 0) {
      final k = tiltPhase < 3 ? tiltPhase / 3 : (tiltPhase < 6 ? 1.0 : (9 - tiltPhase) / 3);
      roll += 45 * k;
    }

    // luz (abertura)
    var light = (2 + _rnd.nextDouble() * 2);
    if (on(SimIncident.opening) || (c >= 115 && c < 121)) light = 70 + _rnd.nextDouble() * 15;

    // temperatura com inércia
    final hot = on(SimIncident.heat) || (c >= 150 && c < 185);
    final target = hot ? baseTemp + 12 : baseTemp;
    if (_temp == 0) _temp = baseTemp;
    _temp += (target - _temp) * 0.12 + _noise(0.05);
    final hum = 52 + math.sin(_t / 37) * 4 + _noise(0.5);

    // posição na estrada: avança até o destino e para lá
    final f = driving ? math.min(1.0, (_t - _tripStart) / tripSeconds) : 0.0;
    final (lat, lng) = route.at(f);
    final yaw = route.headingAt(f) + _noise(0.6);

    _battery = math.max(5, _battery - 0.004);
    final buffered = on(SimIncident.signalLoss) || (c >= 200 && c < 212);

    for (final k in _manual.keys.toList()) {
      _manual[k] = _manual[k]! - 1;
      if (_manual[k]! <= 0) _manual.remove(k);
    }

    return Telemetry(
      deviceId: deviceId,
      ts: _clock,
      seq: _seq,
      roll: roll,
      pitch: pitch,
      yaw: yaw,
      accelG: accel,
      peakG: peak,
      temp: _temp,
      hum: hum,
      light: light,
      lat: lat,
      lng: lng,
      battery: _battery.round(),
      rssi: buffered ? null : -55 - _rnd.nextInt(15),
      buffered: buffered,
    );
  }

  double _noise(double amp) => (_rnd.nextDouble() * 2 - 1) * amp;
}
