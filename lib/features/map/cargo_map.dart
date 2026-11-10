import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';
import '../shell/app_shell.dart';

/// Estrada prevista: aparece quando o caminhão está nela (até 1,5 km de distância).
DemoRoute? routeFor(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  final r = DemoRoute.dutra;
  return r.progressOf(lat, lng).offRouteMeters <= 1500 ? r : null;
}

/// Mapa da viagem com o caminhão andando sobre a estrada real.
///
/// - linha tracejada: estrada prevista; linha ciano: trecho já percorrido;
/// - o caminhão desliza de uma leitura para a outra e vira na direção da estrada;
/// - [live] = câmera segue o caminhão (desliga ao arrastar o mapa).
class CargoMap extends StatefulWidget {
  const CargoMap({
    super.key,
    required this.trail,
    this.current,
    this.events = const [],
    this.live = false,
    this.height = 300,
    this.onEventTap,
  });

  final List<Telemetry> trail;
  final Telemetry? current;
  final List<CargoEvent> events;
  final bool live;
  final double height;
  final void Function(CargoEvent)? onEventTap;

  @override
  State<CargoMap> createState() => _CargoMapState();
}

class _CargoMapState extends State<CargoMap> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
    ..addListener(_onFrame);
  bool _ready = false;
  late bool _follow = widget.live;
  LatLng? _from, _to;
  double _heading = 0;

  LatLng? get _target {
    final c = widget.current;
    if (c != null && c.hasLocation) return LatLng(c.lat!, c.lng!);
    final t = widget.trail.where((e) => e.hasLocation).lastOrNull;
    return t == null ? null : LatLng(t.lat!, t.lng!);
  }

  LatLng? get _truck {
    if (_from == null || _to == null) return _to;
    final u = Curves.easeInOut.transform(_anim.value);
    return LatLng(_from!.latitude + (_to!.latitude - _from!.latitude) * u, _from!.longitude + (_to!.longitude - _from!.longitude) * u);
  }

  @override
  void initState() {
    super.initState();
    _to = _target;
    final r = _to == null ? null : routeFor(_to!.latitude, _to!.longitude);
    if (r != null) {
      final p = r.progressOf(_to!.latitude, _to!.longitude);
      _heading = r.headingAt(p.fraction);
    }
  }

  @override
  void didUpdateWidget(covariant CargoMap old) {
    super.didUpdateWidget(old);
    final t = _target;
    if (t == null || t == _to) return;
    final shown = _truck ?? t;
    final moved = const Distance().as(LengthUnit.Meter, shown, t);
    if (moved > 3) _heading = DemoRoute.bearing(shown.latitude, shown.longitude, t.latitude, t.longitude);
    _from = shown;
    _to = t;
    if (moved > 5000 || MediaQuery.of(context).disableAnimations) {
      _anim.value = 1; // salto grande (ex.: leituras antigas): não anima
      _onFrame();
    } else {
      _anim.forward(from: 0);
    }
  }

  void _onFrame() {
    if (!mounted) return;
    setState(() {});
    final p = _truck;
    if (_follow && _ready && p != null) _map.move(p, _map.camera.zoom);
  }

  void _fitAll() {
    final pts = _allPoints();
    if (pts.length < 2) return;
    _map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(40)));
  }

  List<LatLng> _allPoints() {
    final t = _target;
    final r = t == null ? null : routeFor(t.latitude, t.longitude);
    return [
      if (r != null) ...r.path.map((p) => LatLng(p.$1, p.$2)),
      ...widget.trail.where((e) => e.hasLocation).map((e) => LatLng(e.lat!, e.lng!)),
      ...widget.events.where((e) => e.lat != null).map((e) => LatLng(e.lat!, e.lng!)),
    ];
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final truck = _truck;
    final route = truck == null ? null : routeFor(truck.latitude, truck.longitude);
    final planned = route?.path.map((p) => LatLng(p.$1, p.$2)).toList() ?? const <LatLng>[];
    final trail = [
      ...widget.trail.where((e) => e.hasLocation).map((e) => LatLng(e.lat!, e.lng!)),
      if (truck != null) truck,
    ];
    final evs = widget.events.where((e) => e.lat != null && e.lng != null).toList();
    final all = _allPoints();

    if (all.isEmpty && truck == null) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('Ainda sem posição de GPS.', style: KxText.body)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(KxRadius.input),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: truck ?? all.first,
              initialZoom: widget.live ? 13.5 : 11,
              initialCameraFit: widget.live || all.length < 2
                  ? null
                  : CameraFit.bounds(bounds: LatLngBounds.fromPoints(all), padding: const EdgeInsets.all(36)),
              backgroundColor: KxColors.charcoalSolid,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapReady: () => _ready = true,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _follow) setState(() => _follow = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: Env.mapTilesUrl,
                userAgentPackageName: 'br.senai.talpa.kinetix',
                maxNativeZoom: 19,
                tileBuilder: Env.mapTilesUrl == Env.osmTiles ? _darkTiles : null,
              ),
              if (planned.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: planned,
                    color: KxColors.textBody.withValues(alpha: 0.7),
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [10, 8]),
                  ),
                ]),
              if (trail.length > 1)
                PolylineLayer(polylines: [
                  Polyline(points: trail, color: KxColors.cyberCyan.withValues(alpha: 0.25), strokeWidth: 9),
                  Polyline(points: trail, color: KxColors.cyberCyan, strokeWidth: 3.5),
                ]),
              MarkerLayer(markers: [
                if (planned.isNotEmpty) ...[
                  Marker(point: planned.first, width: 16, height: 16, child: const _Pin(color: KxColors.textDisplay, icon: null)),
                  Marker(
                    point: planned.last,
                    width: 30,
                    height: 30,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.place, color: KxColors.talpaLava, size: 30),
                  ),
                ] else if (trail.isNotEmpty)
                  Marker(point: trail.first, width: 16, height: 16, child: const _Pin(color: KxColors.textDisplay, icon: null)),
                for (final e in evs)
                  Marker(
                    point: LatLng(e.lat!, e.lng!),
                    width: 28,
                    height: 28,
                    child: GestureDetector(
                      onTap: widget.onEventTap == null ? null : () => widget.onEventTap!(e),
                      child: Tooltip(
                        message: '${Fmt.hm(e.ts)} · ${e.title}',
                        child: _Pin(color: KxColors.forSeverity(e.severity), icon: eventIcon(e.type)),
                      ),
                    ),
                  ),
                if (truck != null)
                  Marker(
                    point: truck,
                    width: 44,
                    height: 44,
                    child: _Truck(heading: _heading, live: widget.live),
                  ),
              ]),
              const SimpleAttributionWidget(source: Text('colaboradores do OpenStreetMap')),
            ],
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Column(children: [
              if (widget.live)
                _MapButton(
                  icon: _follow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                  tooltip: _follow ? 'Seguindo o caminhão' : 'Seguir o caminhão',
                  active: _follow,
                  onTap: () {
                    setState(() => _follow = true);
                    final p = _truck;
                    if (p != null) _map.move(p, math.max(_map.camera.zoom, 13));
                  },
                ),
              const SizedBox(height: 6),
              _MapButton(
                icon: Icons.zoom_out_map_rounded,
                tooltip: 'Ver a viagem inteira',
                onTap: () {
                  setState(() => _follow = false);
                  _fitAll();
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Deixa o mapa claro do OpenStreetMap escuro, no tom azul-obsidiana do app:
/// tira a cor, inverte o brilho (ruas claras sobre fundo escuro) e tinge de azul.
const _darkMatrix = <double>[
  -0.0638, -0.2146, -0.0217, 0, 84.0, //
  -0.0723, -0.2432, -0.0245, 0, 98.7,
  -0.0893, -0.3004, -0.0303, 0, 127.1,
  0, 0, 0, 1, 0,
];

Widget _darkTiles(BuildContext context, Widget tile, TileImage image) =>
    ColorFiltered(colorFilter: const ColorFilter.matrix(_darkMatrix), child: tile);

/// Barra de progresso da viagem: quanto já andou, quanto falta e onde está.
class TripProgress extends StatelessWidget {
  const TripProgress({super.key, required this.current, required this.destination});
  final Telemetry? current;
  final String destination;

  /// Velocidade média usada só para estimar a chegada.
  static const avgKmh = 80.0;

  @override
  Widget build(BuildContext context) {
    final c = current;
    final route = routeFor(c?.lat, c?.lng);
    if (c == null || route == null) return const SizedBox.shrink();
    final p = route.progressOf(c.lat!, c.lng!);
    final arrived = p.fraction >= 0.995;
    final minutes = (p.remainingKm / avgKmh * 60).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(arrived ? Icons.flag_rounded : Icons.local_shipping_rounded,
            size: 18, color: arrived ? KxColors.electricLime : KxColors.cyberCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            arrived ? 'Chegou ao destino ($destination)' : 'Perto de ${route.nearest(c.lat!, c.lng!)}',
            style: KxText.h3.copyWith(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!arrived) Text('chega em ~${minutes < 1 ? 1 : minutes} min', style: KxText.log.copyWith(color: KxColors.textSection)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: p.fraction,
          minHeight: 8,
          backgroundColor: KxColors.borderSlate,
          color: arrived ? KxColors.electricLime : KxColors.cyberCyan,
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        Text('${Fmt.num(p.km)} km percorridos', style: KxText.log),
        const Spacer(),
        Text(arrived ? '${Fmt.num(p.totalKm)} km no total' : 'faltam ${Fmt.num(p.remainingKm)} km', style: KxText.log),
      ]),
    ]);
  }
}

class _Truck extends StatelessWidget {
  const _Truck({required this.heading, required this.live});
  final double heading;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KxColors.obsidianPitch,
          border: Border.all(color: KxColors.cyberCyan, width: 2),
          boxShadow: [BoxShadow(color: KxColors.cyberCyan.withValues(alpha: live ? 0.6 : 0.3), blurRadius: 12)],
        ),
      ),
      // seta de direção (0° = norte)
      Transform.rotate(
        angle: heading * math.pi / 180,
        child: const Icon(Icons.navigation_rounded, color: KxColors.cyberCyan, size: 22),
      ),
    ]);
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color, required this.icon});
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: KxColors.obsidianPitch,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: icon == null ? null : Icon(icon, size: 14, color: color),
      );
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onTap, this.active = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: KxColors.obsidianPitch.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: active ? KxColors.cyberCyan : KxColors.borderSlate),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: active ? KxColors.cyberCyan : KxColors.textSection)),
          ),
        ),
      );
}
