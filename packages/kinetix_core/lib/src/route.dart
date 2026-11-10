import 'dart:math' as math;

/// Um ponto conhecido de uma rota.
class Waypoint {
  const Waypoint(this.name, this.lat, this.lng);
  final String name;
  final double lat;
  final double lng;
}

/// Rota de exemplo pela Via Dutra (São José dos Campos → Taubaté), usada pelo
/// simulador e pelo modo demonstração. Na versão Wokwi o GPS também é
/// simulado com esta rota, porque o Wokwi não tem módulo GPS.
class DemoRoute {
  const DemoRoute(this.points);

  static const dutra = DemoRoute([
    Waypoint('São José dos Campos-SP', -23.1896, -45.8841),
    Waypoint('Rod. Pres. Dutra km 147', -23.1712, -45.8392),
    Waypoint('Rod. Pres. Dutra km 140', -23.1418, -45.7896),
    Waypoint('Caçapava-SP', -23.1004, -45.7072),
    Waypoint('Rod. Pres. Dutra km 118', -23.0689, -45.6425),
    Waypoint('Rod. Pres. Dutra km 112', -23.0461, -45.5921),
    Waypoint('Taubaté-SP', -23.0264, -45.5553),
  ]);

  final List<Waypoint> points;

  /// Posição ao longo da rota, de 0 (origem) a 1 (destino).
  (double lat, double lng) at(double f) {
    f = f.clamp(0.0, 1.0);
    final seg = f * (points.length - 1);
    final i = math.min(seg.floor(), points.length - 2);
    final u = seg - i;
    final a = points[i], b = points[i + 1];
    return (a.lat + (b.lat - a.lat) * u, a.lng + (b.lng - a.lng) * u);
  }

  /// Direção (graus, 0 = norte) no ponto [f] da rota.
  double headingAt(double f) {
    final (la, lo) = at(math.max(0, f - 0.01));
    final (lb, lob) = at(math.min(1, f + 0.01));
    return (math.atan2(lob - lo, lb - la) * 180 / math.pi + 360) % 360;
  }

  /// Nome do lugar conhecido mais próximo de uma coordenada.
  String nearest(double lat, double lng) {
    Waypoint best = points.first;
    var bestD = double.infinity;
    for (final p in points) {
      final d = math.pow(p.lat - lat, 2) + math.pow(p.lng - lng, 2);
      if (d < bestD) {
        bestD = d.toDouble();
        best = p;
      }
    }
    return best.name;
  }
}
