import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';
import '../twin/digital_twin.dart';
import 'event_tile.dart';

/// Auditoria da viagem: mapa, temperatura e linha do tempo com RTC + GPS.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, required this.shipmentId, this.focusEventId});
  final String shipmentId;
  final int? focusEventId;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  bool _onlyIncidents = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(shipmentProvider(widget.shipmentId)).value;
    final events = ref.watch(eventsProvider(widget.shipmentId)).value ?? const <CargoEvent>[];
    final readingsAsync = ref.watch(readingsProvider(widget.shipmentId));
    final readings = readingsAsync.value ?? const <Telemetry>[];

    if (!_focused && widget.focusEventId != null && events.isNotEmpty) {
      _focused = true;
      final e = events.where((x) => x.id == widget.focusEventId).firstOrNull;
      if (e != null && s != null) WidgetsBinding.instance.addPostFrameCallback((_) => showEventSheet(context, ref, s, e));
    }

    final list = [...events.where((e) => !_onlyIncidents || e.penalty > 0)]..sort((a, b) => b.ts.compareTo(a.ts));
    final buffered = readings.where((r) => r.buffered).length;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final map = _RouteMap(readings: readings, events: events);
    final chart = s == null ? const SizedBox.shrink() : _TempChart(readings: readings, limits: s.limits);
    final timeline = KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('Linha do tempo',
            trailing: FilterChip(
              label: const Text('Só ocorrências'),
              selected: _onlyIncidents,
              onSelected: (v) => setState(() => _onlyIncidents = v),
            )),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KxSpace.lg),
            child: Text(_onlyIncidents ? 'Nenhuma ocorrência nesta viagem.' : 'Ainda não há registros nesta viagem.', style: KxText.body),
          )
        else
          for (final (i, e) in list.indexed)
            EventTile(event: e, showLine: i < list.length - 1, onTap: s == null ? null : () => showEventSheet(context, ref, s, e)),
        if (s?.startedAt != null)
          Padding(
            padding: const EdgeInsets.only(left: 62 + 44, top: KxSpace.xs),
            child: Text('Viagem iniciada ${Fmt.full(s!.startedAt!)} em ${s.origin}', style: KxText.log),
          ),
      ]),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.shipment(widget.shipmentId)),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Histórico da viagem', style: KxText.h3),
          if (s != null) Text('${s.code} · ${s.description}', style: KxText.log, overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: readingsAsync.isLoading && readings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ContentWidth(
              child: ListView(padding: const EdgeInsets.fromLTRB(KxSpace.lg, 0, KxSpace.lg, KxSpace.xxl), children: [
                if (buffered > 0) ...[_BufferCard(count: buffered), const SizedBox(height: KxSpace.md)],
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(children: [map, const SizedBox(height: KxSpace.md), chart])),
                    const SizedBox(width: KxSpace.md),
                    Expanded(child: timeline),
                  ])
                else ...[
                  map,
                  const SizedBox(height: KxSpace.md),
                  chart,
                  const SizedBox(height: KxSpace.md),
                  timeline,
                ],
              ]),
            ),
    );
  }
}

class _BufferCard extends StatelessWidget {
  const _BufferCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => KxCard(
        glow: KxColors.telemetryAmber,
        child: Row(children: [
          const Icon(Icons.sd_card_outlined, color: KxColors.telemetryAmber),
          const SizedBox(width: KxSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Memória da caixa (sem sinal)', style: KxText.h3.copyWith(color: KxColors.telemetryAmber)),
              Text('$count leituras foram guardadas na caixa em trechos sem internet e enviadas depois. Nenhum dado foi perdido.',
                  style: KxText.body),
            ]),
          ),
        ]),
      );
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.readings, required this.events});
  final List<Telemetry> readings;
  final List<CargoEvent> events;

  @override
  Widget build(BuildContext context) {
    final pts = readings.where((r) => r.hasLocation).map((r) => LatLng(r.lat!, r.lng!)).toList();
    final evs = events.where((e) => e.lat != null && e.lng != null).toList();
    final all = [...pts, ...evs.map((e) => LatLng(e.lat!, e.lng!))];
    return KxCard(
      padding: const EdgeInsets.all(KxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Trajeto (GPS)'),
        ClipRRect(
          borderRadius: BorderRadius.circular(KxRadius.input),
          child: SizedBox(
            height: 260,
            child: all.isEmpty
                ? Center(child: Text('Sem posições registradas ainda.', style: KxText.body))
                : FlutterMap(
                    options: MapOptions(
                      initialCameraFit: all.length == 1
                          ? null
                          : CameraFit.bounds(bounds: LatLngBounds.fromPoints(all), padding: const EdgeInsets.all(36)),
                      initialCenter: all.first,
                      initialZoom: 12,
                      backgroundColor: KxColors.charcoalSolid,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'br.senai.talpa.kinetix',
                        retinaMode: RetinaMode.isHighDensity(context),
                      ),
                      if (pts.length > 1)
                        PolylineLayer(polylines: [Polyline(points: pts, color: KxColors.cyberCyan, strokeWidth: 3)]),
                      MarkerLayer(markers: [
                        if (pts.isNotEmpty)
                          Marker(point: pts.first, width: 14, height: 14, child: const _Dot(color: KxColors.textDisplay)),
                        if (pts.isNotEmpty)
                          Marker(point: pts.last, width: 26, height: 26, child: const Icon(Icons.local_shipping_rounded, color: KxColors.cyberCyan, size: 22)),
                        for (final e in evs)
                          Marker(
                            point: LatLng(e.lat!, e.lng!),
                            width: 26,
                            height: 26,
                            child: Tooltip(
                              message: '${Fmt.hm(e.ts)} · ${e.title}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: KxColors.obsidianPitch,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: KxColors.forSeverity(e.severity), width: 2),
                                ),
                                child: Icon(eventIcon(e.type), size: 14, color: KxColors.forSeverity(e.severity)),
                              ),
                            ),
                          ),
                      ]),
                      const SimpleAttributionWidget(source: Text('OpenStreetMap · CARTO')),
                    ],
                  ),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: KxColors.obsidianPitch, width: 2)));
}

class _TempChart extends StatelessWidget {
  const _TempChart({required this.readings, required this.limits});
  final List<Telemetry> readings;
  final CargoLimits limits;

  @override
  Widget build(BuildContext context) {
    final rs = readings.where((r) => r.temp != null).toList();
    if (rs.length < 2) return const SizedBox.shrink();
    final t0 = rs.first.ts;
    double x(Telemetry r) => r.ts.difference(t0).inSeconds / 60;
    final temps = rs.map((r) => r.temp!).toList();
    final lo = [...temps, limits.tempMin].reduce((a, b) => a < b ? a : b) - 2;
    final hi = [...temps, limits.tempMax].reduce((a, b) => a > b ? a : b) + 2;
    return KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Temperatura na viagem'),
        Text('A faixa verde é a temperatura segura para esta carga.', style: KxText.body.copyWith(fontSize: 13)),
        const SizedBox(height: KxSpace.md),
        SizedBox(
          height: 170,
          child: LineChart(LineChartData(
            minY: lo,
            maxY: hi,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: KxColors.borderSlate, strokeWidth: 1, dashArray: [3, 4]),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, m) => Text('${v.round()}°', style: KxText.log.copyWith(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: ((x(rs.last) / 4).ceilToDouble()).clamp(1, 1e9),
                  getTitlesWidget: (v, m) => Text(Fmt.hm(t0.add(Duration(seconds: (v * 60).round()))), style: KxText.log.copyWith(fontSize: 10)),
                ),
              ),
            ),
            rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(y1: limits.tempMin, y2: limits.tempMax, color: KxColors.electricLime.withValues(alpha: 0.07)),
            ]),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => KxColors.charcoalSolid,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${Fmt.num(s.y)} °C\n${Fmt.hm(t0.add(Duration(seconds: (s.x * 60).round())))}',
                          KxText.log.copyWith(color: KxColors.textDisplay),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (final r in rs) FlSpot(x(r), r.temp!)],
                isCurved: true,
                preventCurveOverShooting: true,
                color: KxColors.cyberCyan,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: KxColors.cyberCyan.withValues(alpha: 0.08)),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}

/// Detalhe de uma ocorrência com o "replay" 3D da posição da caixa naquele instante.
Future<void> showEventSheet(BuildContext context, WidgetRef ref, Shipment s, CargoEvent e) {
  final c = KxColors.forSeverity(e.severity);
  final place = e.lat == null ? null : DemoRoute.dutra.nearest(e.lat!, e.lng!);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(KxSpace.xl, 0, KxSpace.xl, KxSpace.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(eventIcon(e.type), color: c),
            const SizedBox(width: KxSpace.sm),
            Expanded(child: Text(e.title, style: KxText.h2.copyWith(color: c))),
            if (e.penalty > 0) StatusPill(label: '−${e.penalty.round()} pontos', color: c),
          ]),
          const SizedBox(height: KxSpace.sm),
          Text(e.detail, style: KxText.body.copyWith(fontSize: 15)),
          if (e.roll != null) ...[
            const SizedBox(height: KxSpace.md),
            Container(
              height: 210,
              decoration: BoxDecoration(
                color: KxColors.obsidianPitch,
                borderRadius: BorderRadius.circular(KxRadius.card),
                border: Border.all(color: KxColors.borderSlate),
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: DigitalTwin(
                    roll: e.roll ?? 0,
                    pitch: e.pitch ?? 0,
                    yaw: e.yaw ?? 0,
                    alert: e.severity != Severity.info,
                    lidOpen: e.type == EventType.opening,
                    impactKey: e.type == EventType.impact ? 1 : 0,
                  ),
                ),
                Positioned(left: 12, top: 10, child: Text('POSIÇÃO DA CAIXA NESTE MOMENTO', style: KxText.label.copyWith(fontSize: 10))),
              ]),
            ),
          ],
          const SizedBox(height: KxSpace.md),
          _kv('Quando', Fmt.full(e.ts)),
          if (place != null) _kv('Onde', '$place (${Fmt.coords(e.lat, e.lng)})'),
          if (e.scoreAfter != null) _kv('Nota depois', '${e.scoreAfter!.round()} de 100'),
          if (e.buffered) _kv('Conexão', 'Registrado sem sinal e enviado depois'),
          if (e.isAcknowledged) _kv('Visto em', Fmt.full(e.acknowledgedAt!)),
          const SizedBox(height: KxSpace.lg),
          if (e.severity != Severity.info && !e.isAcknowledged && e.id != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final ok = await runAction(ctx, () => ref.read(repositoryProvider).acknowledge(e.id!), success: 'Ocorrência marcada como vista.');
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Marcar como visto'),
              ),
            ),
        ]),
      ),
    ),
  );
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(k, style: KxText.body.copyWith(fontSize: 13))),
        Expanded(child: Text(v, style: KxText.log.copyWith(color: KxColors.textSection, fontSize: 13))),
      ]),
    );
