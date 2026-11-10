import 'dart:math' as math;

import 'dutra_path.dart';

/// Um ponto conhecido de uma rota (usado para dizer "perto de onde").
class Waypoint {
  const Waypoint(this.name, this.lat, this.lng);
  final String name;
  final double lat;
  final double lng;
}

/// Posição de um ponto projetada na rota.
class RouteProgress {
  const RouteProgress({required this.fraction, required this.km, required this.totalKm, required this.offRouteMeters});

  /// De 0 (origem) a 1 (destino).
  final double fraction;
  final double km;
  final double totalKm;

  /// Distância do ponto até a estrada. Grande = não está nesta rota.
  final double offRouteMeters;

  double get remainingKm => math.max(0, totalKm - km);
}

/// Rota pela estrada real (traçado do OpenStreetMap), usada pelo simulador,
/// pelo firmware do Wokwi (que não tem GPS) e pelo mapa do app.
class DemoRoute {
  DemoRoute(this.path, this.places) : _cum = _cumulative(path);

  /// Rod. Pres. Dutra: São José dos Campos → Taubaté (~41,5 km).
  static final dutra = DemoRoute(dutraPath, const [
    Waypoint('São José dos Campos-SP', -23.1896, -45.8841),
    Waypoint('Rod. Pres. Dutra km 147', -23.1712, -45.8392),
    Waypoint('Rod. Pres. Dutra km 140', -23.1418, -45.7896),
    Waypoint('Caçapava-SP', -23.1004, -45.7072),
    Waypoint('Rod. Pres. Dutra km 118', -23.0689, -45.6425),
    Waypoint('Rod. Pres. Dutra km 112', -23.0461, -45.5921),
    Waypoint('Taubaté-SP', -23.0264, -45.5553),
  ]);

  /// Pontos (lat, lng) da estrada, em ordem.
  final List<(double, double)> path;
  final List<Waypoint> places;
  final List<double> _cum; // metros acumulados até cada ponto

  /// Pontos nomeados (compatibilidade com a versão anterior).
  List<Waypoint> get points => places;

  double get totalKm => _cum.last / 1000;

  static const _earth = 6371000.0;

  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180;
    final dp = p2 - p1, dl = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dp / 2) * math.sin(dp / 2) + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    return 2 * _earth * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Direção de A para B em graus (0 = norte, 90 = leste).
  static double bearing(double lat1, double lng1, double lat2, double lng2) {
    final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180, dl = (lng2 - lng1) * math.pi / 180;
    final y = math.sin(dl) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static List<double> _cumulative(List<(double, double)> p) {
    final out = <double>[0];
    for (var i = 1; i < p.length; i++) {
      out.add(out.last + distanceMeters(p[i - 1].$1, p[i - 1].$2, p[i].$1, p[i].$2));
    }
    return out;
  }

  int _segmentAt(double meters) {
    var lo = 0, hi = _cum.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_cum[mid] <= meters) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Posição ao longo da estrada, de 0 (origem) a 1 (destino), por distância.
  (double lat, double lng) at(double f) {
    final m = f.clamp(0.0, 1.0) * _cum.last;
    final i = math.min(_segmentAt(m), path.length - 2);
    final segLen = _cum[i + 1] - _cum[i];
    final u = segLen == 0 ? 0.0 : (m - _cum[i]) / segLen;
    final a = path[i], b = path[i + 1];
    return (a.$1 + (b.$1 - a.$1) * u, a.$2 + (b.$2 - a.$2) * u);
  }

  /// Direção da estrada (graus, 0 = norte) no ponto [f] da rota.
  double headingAt(double f) {
    final m = f.clamp(0.0, 1.0) * _cum.last;
    final i = math.min(_segmentAt(m), path.length - 2);
    return bearing(path[i].$1, path[i].$2, path[i + 1].$1, path[i + 1].$2);
  }

  /// Projeta uma coordenada na estrada: quanto já foi percorrido e a que
  /// distância o ponto está da estrada.
  RouteProgress progressOf(double lat, double lng) {
    final kx = 111320 * math.cos(lat * math.pi / 180), ky = 110540.0;
    var best = double.infinity, bestM = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      final ax = path[i].$2 * kx, ay = path[i].$1 * ky;
      final bx = path[i + 1].$2 * kx, by = path[i + 1].$1 * ky;
      final px = lng * kx, py = lat * ky;
      final dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy;
      final u = len2 == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
      final cx = ax + dx * u, cy = ay + dy * u;
      final d = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
      if (d < best) {
        best = d;
        bestM = _cum[i] + (_cum[i + 1] - _cum[i]) * u;
      }
    }
    return RouteProgress(fraction: bestM / _cum.last, km: bestM / 1000, totalKm: totalKm, offRouteMeters: best);
  }

  /// Nome do lugar conhecido mais próximo de uma coordenada.
  String nearest(double lat, double lng) {
    Waypoint best = places.first;
    var bestD = double.infinity;
    for (final p in places) {
      final d = distanceMeters(lat, lng, p.lat, p.lng);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best.name;
  }
}
