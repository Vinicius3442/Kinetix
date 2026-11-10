import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';

/// Traduz uma leitura técnica em frases simples para a tela.
class CargoReadout {
  CargoReadout(this.t, this.limits);
  final Telemetry t;
  final CargoLimits limits;

  // ---- posição
  double get tilt => t.tiltDeg;
  bool get toppled => tilt >= 60;
  bool get tilted => tilt >= limits.tiltDeg;
  String get positionLabel => toppled
      ? 'Tombada'
      : tilted
          ? 'Inclinada'
          : tilt >= limits.tiltDeg / 2
              ? 'Levemente inclinada'
              : 'Em pé';
  Color get positionColor => toppled ? KxColors.talpaLava : (tilted ? KxColors.telemetryAmber : KxColors.electricLime);

  // ---- abertura
  bool get open => t.light >= limits.lightPct;
  String get sealLabel => open ? 'Aberta' : 'Fechada';
  Color get sealColor => open ? KxColors.talpaLava : KxColors.electricLime;

  // ---- impacto
  bool get impact => t.peakG >= limits.impactG;
  String get motionLabel => impact
      ? 'Impacto agora'
      : t.peakG >= 1.4
          ? 'Trepidando'
          : 'Estável';
  Color get motionColor => impact ? KxColors.talpaLava : (t.peakG >= 1.4 ? KxColors.telemetryAmber : KxColors.electricLime);

  // ---- clima
  bool get tempOut => t.temp != null && (t.temp! > limits.tempMax || t.temp! < limits.tempMin);
  bool get humOut => t.hum != null && t.hum! > limits.humMax;
  String get climateLabel {
    if (t.temp == null) return 'Sem leitura';
    if (t.temp! > limits.tempMax) return 'Quente demais';
    if (t.temp! < limits.tempMin) return 'Fria demais';
    if (humOut) return 'Úmida demais';
    return 'Na faixa';
  }

  Color get climateColor => tempOut ? KxColors.talpaLava : (humOut ? KxColors.telemetryAmber : KxColors.electricLime);

  bool get anyAlert => toppled || tilted || open || impact || tempOut;

  /// Frase única para o leitor de tela e o topo do gêmeo 3D.
  String get sentence => [
        'Caixa ${positionLabel.toLowerCase()} (${tilt.round()}°)',
        open ? 'aberta' : 'fechada',
        if (t.temp != null) '${Fmt.num(t.temp)} °C',
      ].join(', ');
}

/// Situação da conexão com a caixa.
enum LinkState {
  live('Ao vivo', KxColors.cyberCyan),
  delayed('Sinal fraco', KxColors.telemetryAmber),
  offline('Sem sinal', KxColors.telemetryAmber),
  waiting('Aguardando caixa', KxColors.textBody);

  const LinkState(this.label, this.color);
  final String label;
  final Color color;

  static LinkState of(DateTime? lastTs, {DateTime? now}) {
    if (lastTs == null) return LinkState.waiting;
    final age = (now ?? DateTime.now()).toUtc().difference(lastTs.toUtc()).inSeconds;
    if (age <= 8) return LinkState.live;
    if (age <= 30) return LinkState.delayed;
    return LinkState.offline;
  }
}
