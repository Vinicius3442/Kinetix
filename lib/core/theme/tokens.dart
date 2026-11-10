import 'package:flutter/material.dart';
import 'package:kinetix_core/kinetix_core.dart';

/// Tokens da paleta "Subterranean Obsidian" (Manual de Identidade Talpa Systems).
abstract final class KxColors {
  static const obsidianPitch = Color(0xFF0B0E14); // fundo
  static const charcoalGlass = Color(0xFF161C26); // cards (85% opacidade)
  static const charcoalSolid = Color(0xFF121821);
  static const borderSlate = Color(0xFF263238);
  static const dotGrid = Color(0xFF1C2432);

  static const talpaLava = Color(0xFFFF5500); // marca, violação, ação principal
  static const cyberCyan = Color(0xFF00E5FF); // telemetria normal, gêmeo, rotas
  static const electricLime = Color(0xFF00E676); // carga intacta (90–100)
  static const telemetryAmber = Color(0xFFFFB300); // avisos leves, buffer offline

  static const textDisplay = Color(0xFFF0F4F8);
  static const textSection = Color(0xFFD0D8E0);
  static const textBody = Color(0xFF94A3B8);
  static const textLog = Color(0xFF64748B);

  static Color forIntegrity(Integrity i) => switch (i) {
        Integrity.ok => electricLime,
        Integrity.attention => telemetryAmber,
        Integrity.problem => talpaLava,
      };

  static Color forSeverity(Severity s) => switch (s) {
        Severity.info => cyberCyan,
        Severity.warning => telemetryAmber,
        Severity.critical => talpaLava,
      };

  static Color forScore(double score) => forIntegrity(Integrity.fromScore(score));
}

abstract final class KxSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class KxRadius {
  static const card = 14.0;
  static const chip = 999.0;
  static const input = 10.0;
}
