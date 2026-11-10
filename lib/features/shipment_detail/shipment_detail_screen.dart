import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../timeline/event_tile.dart';
import '../twin/digital_twin.dart';
import 'cargo_readout.dart';
import 'qr_sheet.dart';
import 'sensor_card.dart';

/// Painel de uma carga: gêmeo digital ao vivo, score e sensores (RF 05 / RF 06).
class ShipmentDetailScreen extends ConsumerStatefulWidget {
  const ShipmentDetailScreen({super.key, required this.shipmentId});
  final String shipmentId;

  @override
  ConsumerState<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends ConsumerState<ShipmentDetailScreen> {
  final _temps = <double>[];
  Telemetry? _last;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // atualiza "há X s" e o estado da conexão
    _clock = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _onTelemetry(Telemetry t) {
    if (_last != null && t.ts.isBefore(_last!.ts)) return;
    _last = t;
    if (t.temp != null) {
      _temps.add(t.temp!);
      if (_temps.length > 90) _temps.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(shipmentProvider(widget.shipmentId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorView(error: e)),
      data: (s) => s == null
          ? Scaffold(
              appBar: AppBar(),
              body: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Carga não encontrada',
                message: 'Ela pode ter sido removida ou você não tem acesso a ela.',
                action: FilledButton(onPressed: () => context.go(Routes.shipments), child: const Text('Voltar para as cargas')),
              ),
            )
          : _build(context, s),
    );
  }

  Widget _build(BuildContext context, Shipment s) {
    final me = ref.watch(sessionProvider).value;
    final repo = ref.watch(repositoryProvider);
    final events = ref.watch(eventsProvider(s.id)).value ?? const <CargoEvent>[];
    final device = s.deviceId == null ? null : (ref.watch(devicesProvider).value ?? const <Device>[]).where((d) => d.id == s.deviceId).firstOrNull;

    // histórico inicial do gráfico
    final readings = ref.watch(readingsProvider(s.id)).value;
    if (_temps.isEmpty && readings != null) {
      _temps.addAll(readings.map((r) => r.temp).whereType<double>().toList().reversed.take(90).toList().reversed);
      if (readings.isNotEmpty) _last ??= readings.last;
    }
    if (s.deviceId != null && s.status.isActive) {
      ref.listen(liveTelemetryProvider(s.deviceId!), (_, next) {
        final t = next.value;
        if (t != null) setState(() => _onTelemetry(t));
      });
      final first = ref.watch(liveTelemetryProvider(s.deviceId!)).value;
      if (first != null && _last == null) _onTelemetry(first);
    }
    final t = _last ?? device?.lastTelemetry;
    final readout = t == null ? null : CargoReadout(t, s.limits);
    final link = s.status == ShipmentStatus.inTransit ? LinkState.of(t?.ts) : null;
    final impacts = events.where((e) => e.type == EventType.impact).length;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final twin = _TwinPanel(shipment: s, readout: readout, link: link, impactKey: impacts, lastTs: t?.ts);
    final score = _ScoreCard(shipment: s, events: events);
    final sensors = readout == null ? _NoData(shipment: s) : _SensorGrid(readout: readout, temps: _temps, events: events, wide: wide);
    final recent = _RecentEvents(shipment: s, events: events);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.shipments),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.code, style: KxText.log.copyWith(color: KxColors.cyberCyan)),
          Text(s.description, style: KxText.h3, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          IconButton(tooltip: 'QR Code de recebimento', icon: const Icon(Icons.qr_code_2_rounded), onPressed: () => showQrSheet(context, s)),
          IconButton(tooltip: 'Histórico e mapa', icon: const Icon(Icons.timeline_rounded), onPressed: () => context.go(Routes.timeline(s.id))),
          if (me?.role.isStaff ?? false)
            IconButton(tooltip: 'Editar carga', icon: const Icon(Icons.edit_outlined), onPressed: () => context.go(Routes.editShipment(s.id))),
          const SizedBox(width: KxSpace.sm),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(KxSpace.lg, 0, KxSpace.lg, KxSpace.xxl),
          children: [
            _RouteHeader(shipment: s, device: device),
            const SizedBox(height: KxSpace.md),
            if (s.status == ShipmentStatus.preparing) ...[_StartCard(shipment: s), const SizedBox(height: KxSpace.md)],
            if (s.status.isClosed) ...[_ClosedCard(shipment: s), const SizedBox(height: KxSpace.md)],
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: twin),
                const SizedBox(width: KxSpace.md),
                Expanded(flex: 5, child: Column(children: [score, const SizedBox(height: KxSpace.md), sensors])),
              ])
            else ...[
              twin,
              const SizedBox(height: KxSpace.md),
              score,
              const SizedBox(height: KxSpace.md),
              sensors,
            ],
            if (repo.isDemo && s.status == ShipmentStatus.inTransit && s.deviceId != null) ...[
              const SizedBox(height: KxSpace.md),
              _DemoControls(deviceId: s.deviceId!),
            ],
            const SizedBox(height: KxSpace.md),
            recent,
            if (device != null) ...[const SizedBox(height: KxSpace.md), _DeviceCard(device: device, t: t)],
          ],
        ),
      ),
    );
  }
}

// ============================================================================ partes

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.shipment, required this.device});
  final Shipment shipment;
  final Device? device;

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    return Wrap(spacing: KxSpace.md, runSpacing: KxSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text.rich(TextSpan(children: [
        const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.trip_origin, size: 14, color: KxColors.cyberCyan)),
        TextSpan(text: '  ${s.origin}  '),
        const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.arrow_forward_rounded, size: 16, color: KxColors.textLog)),
        const TextSpan(text: '  '),
        const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.place, size: 15, color: KxColors.talpaLava)),
        TextSpan(text: ' ${s.destination}'),
      ]), style: KxText.body.copyWith(color: KxColors.textSection)),
      StatusPill(label: s.status.label, color: s.status.isActive ? KxColors.cyberCyan : KxColors.textBody, icon: Icons.local_shipping_outlined),
      if (s.vehiclePlate != null) StatusPill(label: s.vehiclePlate!, color: KxColors.textBody, icon: Icons.directions_car_outlined),
    ]);
  }
}

class _TwinPanel extends StatelessWidget {
  const _TwinPanel({required this.shipment, required this.readout, required this.link, required this.impactKey, required this.lastTs});
  final Shipment shipment;
  final CargoReadout? readout;
  final LinkState? link;
  final int impactKey;
  final DateTime? lastTs;

  @override
  Widget build(BuildContext context) {
    final r = readout;
    final alert = r?.anyAlert ?? false;
    return KxCard(
      glow: alert ? KxColors.talpaLava : null,
      padding: const EdgeInsets.all(KxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.view_in_ar_rounded, size: 18, color: KxColors.cyberCyan),
          const SizedBox(width: 6),
          Expanded(child: Text('GÊMEO DIGITAL', style: KxText.label, overflow: TextOverflow.ellipsis)),
          if (link != null)
            StatusPill(
              label: link == LinkState.live ? link!.label : '${link!.label}${lastTs == null ? '' : ' · ${Fmt.ago(lastTs!)}'}',
              color: link!.color,
              pulse: link == LinkState.live,
              icon: Icons.wifi_off_rounded,
            ),
        ]),
        SizedBox(
          height: 300,
          child: Stack(children: [
            Positioned.fill(
              child: DigitalTwin(
                roll: r?.t.roll ?? 0,
                pitch: r?.t.pitch ?? 0,
                yaw: r?.t.yaw ?? 30,
                alert: alert,
                impactKey: impactKey,
                lidOpen: r?.open ?? false,
                semanticLabel: r?.sentence,
              ),
            ),
            if (r != null)
              Positioned(
                left: 0,
                bottom: 0,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.positionLabel, style: KxText.h2.copyWith(color: r.positionColor)),
                  Text('Inclinação ${r.tilt.round()}°', style: KxText.log),
                ]),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text('Arraste para girar', style: KxText.log.copyWith(fontSize: 11)),
            ),
            if (link == LinkState.offline)
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: KxColors.obsidianPitch.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(KxRadius.input),
                      border: Border.all(color: KxColors.telemetryAmber.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      'A caixa está sem internet. Ela guarda tudo na memória\ne envia assim que o sinal voltar.',
                      style: KxText.body.copyWith(color: KxColors.telemetryAmber, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.shipment, required this.events});
  final Shipment shipment;
  final List<CargoEvent> events;

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    final incidents = events.where((e) => e.penalty > 0).length;
    final color = KxColors.forIntegrity(s.integrity);
    return KxCard(
      child: Row(children: [
        ScoreGauge(score: s.score, size: 112),
        const SizedBox(width: KxSpace.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE DE INTEGRIDADE', style: KxText.label),
            const SizedBox(height: 4),
            Text(s.integrity.label, style: KxText.h2.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(
              incidents == 0
                  ? 'Nenhuma ocorrência na viagem até agora.'
                  : '$incidents ${incidents == 1 ? 'ocorrência' : 'ocorrências'} na viagem. ${s.integrity.hint}',
              style: KxText.body,
            ),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
              onPressed: () => _explain(context),
              child: const Text('Como a nota é calculada?'),
            ),
          ]),
        ),
      ]),
    );
  }

  void _explain(BuildContext context) {
    Widget row(String what, String pts) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [Expanded(child: Text(what, style: KxText.body)), Text(pts, style: KxText.log.copyWith(color: KxColors.talpaLava))]),
        );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Como a nota é calculada'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Toda carga começa com 100. Cada ocorrência tira pontos uma única vez, conforme a gravidade:', style: KxText.body),
            const SizedBox(height: KxSpace.md),
            row('Impacto leve / forte / severo', '−5 / −10 / −20'),
            row('Caixa inclinada (tombada: mais 7)', '−8'),
            row('Caixa aberta', '−25'),
            row('Temperatura fora da faixa (crítica: mais 5)', '−5'),
            row('Umidade alta', '−3'),
            const SizedBox(height: KxSpace.md),
            Text('90 a 100: Carga OK · 70 a 89: Atenção · abaixo de 70: Problema', style: KxText.body.copyWith(color: KxColors.textSection)),
          ]),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi'))],
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.readout, required this.temps, required this.events, required this.wide});
  final CargoReadout readout;
  final List<double> temps;
  final List<CargoEvent> events;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final r = readout, t = r.t, l = r.limits;
    final lastImpact = events.where((e) => e.type == EventType.impact).firstOrNull;
    final cards = [
      SensorCard(
        icon: Icons.vibration_rounded,
        title: 'Movimento',
        state: r.motionLabel,
        color: r.motionColor,
        value: '${Fmt.num(t.peakG)} G',
        detail: lastImpact == null ? 'Sem impactos · MPU6050' : 'Último impacto ${Fmt.hm(lastImpact.ts)} · MPU6050',
        alert: r.impact,
      ),
      SensorCard(
        icon: Icons.screen_rotation_alt_rounded,
        title: 'Posição',
        state: r.positionLabel,
        color: r.positionColor,
        value: '${r.tilt.round()}°',
        detail: 'Limite ${l.tiltDeg.round()}° · giroscópio',
        alert: r.tilted,
      ),
      SensorCard(
        icon: r.open ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        title: 'Lacre',
        state: r.sealLabel,
        color: r.sealColor,
        value: 'Luz ${t.light.round()}%',
        detail: r.open ? 'Entrou luz na caixa · LDR' : 'Escuro dentro da caixa · LDR',
        alert: r.open,
      ),
      SensorCard(
        icon: Icons.thermostat_rounded,
        title: 'Clima',
        state: r.climateLabel,
        color: r.climateColor,
        value: '${Fmt.num(t.temp)} °C · ${t.hum?.round() ?? '—'}%',
        detail: 'Faixa ${Fmt.num(l.tempMin, 0)}–${Fmt.num(l.tempMax, 0)} °C · DHT22',
        alert: r.tempOut,
        chart: Sparkline(values: temps, min: l.tempMin, max: l.tempMax, color: r.tempOut ? KxColors.talpaLava : KxColors.cyberCyan),
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 300 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * KxSpace.md) / cols;
      return Wrap(spacing: KxSpace.md, runSpacing: KxSpace.md, children: [for (final card in cards) SizedBox(width: w, child: card)]);
    });
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) => KxCard(
        child: EmptyState(
          icon: Icons.sensors_off_rounded,
          title: shipment.deviceId == null ? 'Nenhuma caixa ligada' : 'Aguardando a primeira leitura',
          message: shipment.deviceId == null
              ? 'Edite a carga e escolha qual caixa Kinetix vai monitorá-la.'
              : 'Assim que a caixa ${shipment.deviceId} enviar dados, os sensores aparecem aqui.',
        ),
      );
}

class _RecentEvents extends ConsumerWidget {
  const _RecentEvents({required this.shipment, required this.events});
  final Shipment shipment;
  final List<CargoEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = [...events]..sort((a, b) => b.ts.compareTo(a.ts));
    return KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('Últimas ocorrências',
            trailing: TextButton(onPressed: () => context.go(Routes.timeline(shipment.id)), child: const Text('Ver histórico e mapa'))),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KxSpace.md),
            child: Row(children: [
              const Icon(Icons.verified_outlined, color: KxColors.electricLime),
              const SizedBox(width: KxSpace.sm),
              Expanded(child: Text('Tudo tranquilo: nenhuma ocorrência registrada.', style: KxText.body)),
            ]),
          )
        else
          for (final e in list.take(4))
            EventTile(
              event: e,
              onTap: () => context.go(Routes.timeline(shipment.id, eventId: e.id)),
              trailing: e.severity != Severity.info && !e.isAcknowledged
                  ? IconButton(
                      tooltip: 'Marcar como visto',
                      icon: const Icon(Icons.done_rounded, color: KxColors.textBody),
                      onPressed: e.id == null ? null : () => runAction(context, () => ref.read(repositoryProvider).acknowledge(e.id!)),
                    )
                  : null,
            ),
      ]),
    );
  }
}

class _StartCard extends ConsumerWidget {
  const _StartCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KxCard(
        glow: KxColors.cyberCyan,
        child: Row(children: [
          const Icon(Icons.flag_outlined, color: KxColors.cyberCyan, size: 28),
          const SizedBox(width: KxSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Esta carga ainda não saiu', style: KxText.h3),
              Text('Quando o caminhão partir, toque em "Iniciar viagem" para a nota começar a contar.', style: KxText.body),
            ]),
          ),
          const SizedBox(width: KxSpace.md),
          FilledButton.icon(
            onPressed: shipment.deviceId == null
                ? null
                : () => runAction(context, () => ref.read(repositoryProvider).startShipment(shipment.id), success: 'Viagem iniciada. Boa estrada!'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar viagem'),
          ),
        ]),
      );
}

class _ClosedCard extends StatelessWidget {
  const _ClosedCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final ok = shipment.status == ShipmentStatus.delivered;
    final c = ok ? KxColors.electricLime : KxColors.talpaLava;
    return KxCard(
      onTap: () => context.push(Routes.receipt(shipment.qrToken)),
      child: Row(children: [
        Icon(ok ? Icons.verified_rounded : Icons.block_rounded, color: c, size: 28),
        const SizedBox(width: KxSpace.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ok ? 'Entrega aprovada' : 'Entrega recusada', style: KxText.h3.copyWith(color: c)),
            Text(
              '${shipment.deliveredAt == null ? '' : '${Fmt.full(shipment.deliveredAt!)}. '}Toque para ver o comprovante.',
              style: KxText.body,
            ),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: KxColors.textBody),
      ]),
    );
  }
}

class _DemoControls extends ConsumerWidget {
  const _DemoControls({required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void sim(SimIncident i, String msg) {
      ref.read(repositoryProvider).simulate(deviceId, i);
      showSnack(context, msg);
    }

    return KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Simular ocorrência (modo demonstração)'),
        Text('Provoque um evento na caixa para ver o gêmeo, os alertas e a nota reagirem.', style: KxText.body),
        const SizedBox(height: KxSpace.md),
        Wrap(spacing: KxSpace.sm, runSpacing: KxSpace.sm, children: [
          ActionChip(avatar: const Icon(Icons.vibration_rounded, size: 18), label: const Text('Impacto'), onPressed: () => sim(SimIncident.impact, 'Impacto enviado.')),
          ActionChip(avatar: const Icon(Icons.screen_rotation_alt_rounded, size: 18), label: const Text('Inclinar'), onPressed: () => sim(SimIncident.tilt, 'Inclinando a caixa…')),
          ActionChip(avatar: const Icon(Icons.light_mode_rounded, size: 18), label: const Text('Abrir caixa'), onPressed: () => sim(SimIncident.opening, 'Abrindo a caixa…')),
          ActionChip(avatar: const Icon(Icons.thermostat_rounded, size: 18), label: const Text('Esquentar'), onPressed: () => sim(SimIncident.heat, 'Temperatura subindo…')),
          ActionChip(avatar: const Icon(Icons.signal_wifi_off_rounded, size: 18), label: const Text('Perder sinal'), onPressed: () => sim(SimIncident.signalLoss, 'Caixa sem sinal por 12 s.')),
        ]),
      ]),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.t});
  final Device device;
  final Telemetry? t;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String label, String value) => Padding(
          padding: const EdgeInsets.only(right: KxSpace.xl, bottom: KxSpace.sm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 16, color: KxColors.textBody),
            const SizedBox(width: 6),
            Text('$label ', style: KxText.body.copyWith(fontSize: 13)),
            Text(value, style: KxText.log.copyWith(color: KxColors.textSection)),
          ]),
        );
    return KxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(device.name),
        Wrap(children: [
          item(Icons.memory_rounded, 'Código', device.id),
          item(Icons.battery_5_bar_rounded, 'Bateria', device.battery == null ? '—' : '${device.battery}%'),
          item(Icons.network_cell_rounded, 'Sinal', device.rssi == null ? '—' : '${device.rssi} dBm'),
          item(Icons.schedule_rounded, 'Última leitura', t == null ? '—' : Fmt.time(t!.ts)),
          item(Icons.place_outlined, 'GPS', Fmt.coords(t?.lat, t?.lng)),
        ]),
      ]),
    );
  }
}
