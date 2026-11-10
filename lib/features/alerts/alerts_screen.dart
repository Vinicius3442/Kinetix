import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../timeline/event_tile.dart';

/// Central de alertas: ocorrências que ainda ninguém viu (RF 08).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertsProvider);
    final shipments = ref.watch(shipmentsProvider).value ?? const <Shipment>[];
    final repo = ref.watch(repositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ContentWidth(
          max: 820,
          child: async.when(
            skipLoadingOnReload: true,
            skipError: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(alertsProvider)),
            data: (alerts) => ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
              Row(children: [
                Expanded(child: Text('Alertas', style: KxText.h1)),
                if (alerts.length > 1)
                  TextButton.icon(
                    onPressed: () => runAction(context, () async {
                      for (final a in alerts) {
                        if (a.id != null) await repo.acknowledge(a.id!);
                      }
                    }, success: 'Todos os alertas foram marcados como vistos.'),
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('Marcar todos como vistos'),
                  ),
              ]),
              const SizedBox(height: KxSpace.xs),
              Text('Ocorrências que ainda não foram vistas por ninguém da equipe.', style: KxText.body),
              const SizedBox(height: KxSpace.lg),
              if (alerts.isEmpty)
                const KxCard(
                  child: EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Nenhum alerta pendente',
                    message: 'Quando uma caixa sofrer impacto, tombar, for aberta ou sair da temperatura, o aviso aparece aqui na hora.',
                  ),
                )
              else
                for (final a in alerts) ...[
                  Builder(builder: (context) {
                    final s = shipments.where((x) => x.id == a.shipmentId).firstOrNull;
                    return KxCard(
                      glow: a.severity == Severity.critical ? KxColors.talpaLava : null,
                      padding: const EdgeInsets.fromLTRB(KxSpace.md, KxSpace.sm, KxSpace.sm, KxSpace.sm),
                      onTap: s == null ? null : () => context.go(Routes.timeline(s.id, eventId: a.id)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (s != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 4),
                            child: Text('${s.code} · ${s.description}', style: KxText.log.copyWith(color: KxColors.cyberCyan)),
                          ),
                        EventTile(
                          event: a,
                          trailing: IconButton(
                            tooltip: 'Marcar como visto',
                            icon: const Icon(Icons.done_rounded),
                            onPressed: a.id == null ? null : () => runAction(context, () => repo.acknowledge(a.id!)),
                          ),
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: KxSpace.sm),
                ],
            ]),
          ),
        ),
      ),
    );
  }
}
