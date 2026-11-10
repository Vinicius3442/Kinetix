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

enum _Filter {
  active('Em andamento'),
  attention('Com ocorrências'),
  done('Finalizadas'),
  all('Todas');

  const _Filter(this.label);
  final String label;
}

/// Tela inicial: as cargas que a pessoa acompanha.
class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  _Filter _filter = _Filter.active;
  String _query = '';

  bool _matches(Shipment s) {
    final ok = switch (_filter) {
      _Filter.active => s.status.isActive,
      _Filter.attention => s.integrity != Integrity.ok,
      _Filter.done => s.status.isClosed,
      _Filter.all => true,
    };
    if (!ok) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return [s.code, s.description, s.origin, s.destination, s.vehiclePlate ?? '', s.recipientName ?? '']
        .any((f) => f.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider).value;
    final async = ref.watch(shipmentsProvider);
    final alerts = ref.watch(alertsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (me?.role.isStaff ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.go(Routes.newShipment),
              icon: const Icon(Icons.add),
              label: const Text('Nova carga'),
            )
          : null,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(shipmentsProvider)),
          data: (all) {
            final list = all.where(_matches).toList()
              ..sort((a, b) {
                // ativas primeiro, depois as com pior score
                if (a.status.isActive != b.status.isActive) return a.status.isActive ? -1 : 1;
                return a.score.compareTo(b.score);
              });
            final inTransit = all.where((s) => s.status == ShipmentStatus.inTransit).length;
            final problems = all.where((s) => s.status.isActive && s.integrity == Integrity.problem).length;
            return ContentWidth(
              child: CustomScrollView(slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(KxSpace.lg, KxSpace.lg, KxSpace.lg, 0),
                  sliver: SliverList.list(children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Olá, ${me?.firstName ?? ''}', style: KxText.body),
                          Text(me?.role.isStaff ?? false ? 'Cargas da operação' : 'Minhas cargas', style: KxText.h1),
                        ]),
                      ),
                      const KxLogo(height: 26, showName: false),
                    ]),
                    const SizedBox(height: KxSpace.lg),
                    _Summary(inTransit: inTransit, problems: problems, alerts: alerts.length),
                    const SizedBox(height: KxSpace.lg),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar carga',
                        hintText: 'Código, produto, cidade ou placa',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: KxSpace.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final f in _Filter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: KxSpace.sm),
                            child: ChoiceChip(
                              label: Text(f.label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: KxSpace.lg),
                  ]),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: all.isEmpty ? 'Nenhuma carga ainda' : 'Nada por aqui',
                      message: all.isEmpty
                          ? (me?.role.isStaff ?? false)
                              ? 'Cadastre a primeira carga e ligue uma caixa Kinetix a ela.'
                              : 'Quando um gestor colocar você como motorista de uma carga, ela aparece aqui.'
                          : 'Nenhuma carga combina com a busca ou o filtro escolhido.',
                      action: all.isEmpty && (me?.role.isStaff ?? false)
                          ? FilledButton.icon(onPressed: () => context.go(Routes.newShipment), icon: const Icon(Icons.add), label: const Text('Cadastrar carga'))
                          : (all.isNotEmpty
                              ? OutlinedButton(onPressed: () => setState(() => _filter = _Filter.all), child: const Text('Ver todas'))
                              : null),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(KxSpace.lg, 0, KxSpace.lg, 96),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 560,
                        mainAxisExtent: 176,
                        crossAxisSpacing: KxSpace.md,
                        mainAxisSpacing: KxSpace.md,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ShipmentCard(
                          shipment: list[i],
                          openAlerts: alerts.where((a) => a.shipmentId == list[i].id).length,
                        ),
                        childCount: list.length,
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.inTransit, required this.problems, required this.alerts});
  final int inTransit, problems, alerts;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, Color color, IconData icon) => Expanded(
          child: KxCard(
            padding: const EdgeInsets.all(KxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(value, style: KxText.metric(color).copyWith(fontSize: 22)),
                const Spacer(),
                Icon(icon, color: color, size: 18),
              ]),
              const SizedBox(height: 2),
              Text(label, style: KxText.body.copyWith(fontSize: 12, height: 1.2), maxLines: 2),
            ]),
          ),
        );
    return Row(children: [
      tile('$inTransit', 'em viagem', KxColors.cyberCyan, Icons.local_shipping_outlined),
      const SizedBox(width: KxSpace.sm),
      tile('$problems', 'com problema', problems > 0 ? KxColors.talpaLava : KxColors.electricLime, Icons.report_gmailerrorred_outlined),
      const SizedBox(width: KxSpace.sm),
      tile('$alerts', 'alertas novos', alerts > 0 ? KxColors.telemetryAmber : KxColors.electricLime, Icons.notifications_none_rounded),
    ]);
  }
}

class ShipmentCard extends ConsumerWidget {
  const ShipmentCard({super.key, required this.shipment, this.openAlerts = 0});
  final Shipment shipment;
  final int openAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = shipment;
    final color = KxColors.forIntegrity(s.integrity);
    final device = s.deviceId == null
        ? null
        : (ref.watch(devicesProvider).value ?? const <Device>[]).where((d) => d.id == s.deviceId).firstOrNull;

    final statusLine = switch (s.status) {
      ShipmentStatus.inTransit => device?.online ?? false
          ? 'Ao vivo · ${device!.name}'
          : 'Caixa sem sinal${device?.lastSeen == null ? '' : ' · ${Fmt.ago(device!.lastSeen!)}'}',
      ShipmentStatus.preparing => 'Aguardando saída',
      ShipmentStatus.delivered => 'Entregue ${s.deliveredAt == null ? '' : Fmt.ago(s.deliveredAt!)}',
      ShipmentStatus.refused => 'Recusada na entrega',
    };
    final statusColor = switch (s.status) {
      ShipmentStatus.inTransit => device?.online ?? false ? KxColors.cyberCyan : KxColors.telemetryAmber,
      ShipmentStatus.refused => KxColors.talpaLava,
      _ => KxColors.textBody,
    };

    return Semantics(
      button: true,
      label: 'Carga ${s.code}, ${s.description}, nota ${s.score.round()}, ${s.integrity.label}',
      child: KxCard(
        glow: s.status.isActive && s.integrity == Integrity.problem ? KxColors.talpaLava : null,
        onTap: () => context.go(Routes.shipment(s.id)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: KxSpace.sm, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(s.code, style: KxText.log.copyWith(color: KxColors.cyberCyan, fontSize: 13)),
                if (openAlerts > 0)
                  StatusPill(label: '$openAlerts ${openAlerts == 1 ? 'alerta' : 'alertas'}', color: KxColors.talpaLava, icon: Icons.notifications_active_outlined),
              ]),
              const SizedBox(height: 4),
              Text(s.description, style: KxText.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: KxSpace.sm),
              Row(children: [
                Flexible(child: Text(s.origin, style: KxText.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: KxColors.cyberCyan),
                ),
                Flexible(child: Text(s.destination, style: KxText.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const Spacer(),
              Row(children: [
                if (s.status == ShipmentStatus.inTransit && (device?.online ?? false))
                  PulseDot(color: statusColor, size: 7)
                else
                  Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 6),
                Expanded(child: Text(statusLine, style: KxText.body.copyWith(color: statusColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          const SizedBox(width: KxSpace.md),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScoreGauge(score: s.score, size: 84, stroke: 7),
            const SizedBox(height: 4),
            Text(s.integrity.label, style: KxText.label.copyWith(color: color)),
          ]),
        ]),
      ),
    );
  }
}
