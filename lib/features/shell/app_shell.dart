import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

class _Dest {
  const _Dest(this.branch, this.label, this.icon, this.selectedIcon);
  final int branch;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Estrutura com navegação: barra inferior no celular, trilho lateral na web.
/// Também mostra o aviso de alerta em qualquer tela quando chega uma ocorrência.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Set<int>? _seenAlerts;

  List<_Dest> _destinations(Profile? me) => [
        const _Dest(0, 'Cargas', Icons.inventory_2_outlined, Icons.inventory_2),
        const _Dest(1, 'Alertas', Icons.notifications_none_rounded, Icons.notifications_rounded),
        if (me?.role != UserRole.motorista) const _Dest(2, 'Ler QR', Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded),
        const _Dest(3, 'Perfil', Icons.person_outline_rounded, Icons.person_rounded),
        if (me?.role.isStaff ?? false) const _Dest(4, 'Gestão', Icons.tune_rounded, Icons.tune_rounded),
      ];

  void _onAlerts(List<CargoEvent> alerts) {
    final ids = alerts.map((e) => e.id ?? -1).toSet();
    if (_seenAlerts == null) {
      _seenAlerts = ids; // primeira carga: não avisa o que já existia
      return;
    }
    final fresh = alerts.where((e) => !_seenAlerts!.contains(e.id ?? -1)).toList();
    _seenAlerts!.addAll(ids);
    if (fresh.isEmpty || !mounted) return;
    final e = fresh.first;
    final shipments = ref.read(shipmentsProvider).value ?? const [];
    final sh = shipments.where((s) => s.id == e.shipmentId).firstOrNull;
    final color = KxColors.forSeverity(e.severity);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(MaterialBanner(
      backgroundColor: KxColors.charcoalSolid,
      surfaceTintColor: Colors.transparent,
      dividerColor: color,
      leading: Icon(_iconFor(e.type), color: color),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('${e.title}${sh == null ? '' : ' · ${sh.code}'}', style: KxText.h3.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(e.detail, style: KxText.body),
      ]),
      actions: [
        TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: const Text('Fechar')),
        if (sh != null)
          FilledButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              context.go(Routes.shipment(sh.id));
            },
            child: const Text('Ver carga'),
          ),
      ],
    ));
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(alertsProvider, (_, next) {
      final v = next.value;
      if (v != null) _onAlerts(v);
    });
    final me = ref.watch(sessionProvider).value;
    final alertCount = ref.watch(alertsProvider).value?.length ?? 0;
    final isDemo = ref.watch(repositoryProvider).isDemo;
    final dests = _destinations(me);
    final selected = dests.indexWhere((d) => d.branch == widget.shell.currentIndex).clamp(0, dests.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    void go(int i) => widget.shell.goBranch(dests[i].branch, initialLocation: dests[i].branch == widget.shell.currentIndex);

    Widget icon(_Dest d, bool sel) {
      final i = Icon(sel ? d.selectedIcon : d.icon);
      return d.branch == 1 && alertCount > 0
          ? Badge(label: Text('$alertCount'), backgroundColor: KxColors.talpaLava, child: i)
          : i;
    }

    final body = Column(children: [
      if (isDemo) const _DemoStrip(),
      Expanded(child: KxBackground(child: widget.shell)),
    ]);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1200,
            minExtendedWidth: 200,
            selectedIndex: selected,
            onDestinationSelected: go,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: KxSpace.lg),
              child: KxLogo(height: 30, showName: false),
            ),
            destinations: [
              for (final (i, d) in dests.indexed)
                NavigationRailDestination(icon: icon(d, false), selectedIcon: icon(d, i == selected), label: Text(d.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: go,
        destinations: [
          for (final (i, d) in dests.indexed)
            NavigationDestination(icon: icon(d, false), selectedIcon: icon(d, i == selected), label: d.label),
        ],
      ),
    );
  }
}

class _DemoStrip extends StatelessWidget {
  const _DemoStrip();

  @override
  Widget build(BuildContext context) => Material(
        color: KxColors.telemetryAmber.withValues(alpha: 0.12),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KxSpace.lg, vertical: 6),
            child: Row(children: [
              const Icon(Icons.science_outlined, size: 16, color: KxColors.telemetryAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Modo demonstração: caixas e dados simulados neste aparelho.',
                    style: KxText.body.copyWith(color: KxColors.telemetryAmber, fontSize: 12)),
              ),
            ]),
          ),
        ),
      );
}

IconData _iconFor(EventType t) => eventIcon(t);

IconData eventIcon(EventType t) => switch (t) {
      EventType.impact => Icons.vibration_rounded,
      EventType.tilt => Icons.screen_rotation_alt_rounded,
      EventType.opening => Icons.light_mode_rounded,
      EventType.temperature => Icons.thermostat_rounded,
      EventType.humidity => Icons.water_drop_outlined,
      EventType.connection => Icons.wifi_tethering_rounded,
      EventType.delivery => Icons.verified_outlined,
    };
