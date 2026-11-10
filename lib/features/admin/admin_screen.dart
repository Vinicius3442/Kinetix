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

/// Gestão: cargas, caixas Kinetix e usuários (gestor/admin).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(sessionProvider).value?.role == UserRole.admin;
    final tabs = [
      const Tab(text: 'Cargas'),
      const Tab(text: 'Caixas'),
      if (isAdmin) const Tab(text: 'Usuários'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ContentWidth(
            max: 900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(KxSpace.lg, KxSpace.lg, KxSpace.lg, 0),
                child: Text('Gestão', style: KxText.h1),
              ),
              TabBar(tabs: tabs, isScrollable: true, tabAlignment: TabAlignment.start),
              Expanded(
                child: TabBarView(children: [
                  const _ShipmentsTab(),
                  const _DevicesTab(),
                  if (isAdmin) const _UsersTab(),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================================ cargas

class _ShipmentsTab extends ConsumerWidget {
  const _ShipmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shipmentsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e),
      data: (list) => ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
        Row(children: [
          Expanded(child: Text('Cadastre a viagem, escolha a caixa e o motorista. O QR Code é gerado sozinho.', style: KxText.body)),
          const SizedBox(width: KxSpace.md),
          FilledButton.icon(onPressed: () => context.go(Routes.newShipment), icon: const Icon(Icons.add), label: const Text('Nova carga')),
        ]),
        const SizedBox(height: KxSpace.lg),
        if (list.isEmpty)
          const EmptyState(icon: Icons.inventory_2_outlined, title: 'Nenhuma carga cadastrada', message: 'Use o botão "Nova carga" para começar.')
        else
          for (final s in list) ...[
            KxCard(
              padding: const EdgeInsets.symmetric(horizontal: KxSpace.md, vertical: KxSpace.sm),
              onTap: () => context.go(Routes.shipment(s.id)),
              child: Row(children: [
                ScoreGauge(score: s.score, size: 46, stroke: 5),
                const SizedBox(width: KxSpace.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.code} · ${s.description}', style: KxText.h3.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
                    Text('${s.status.label} · ${s.deviceId ?? 'sem caixa'} · ${s.origin} → ${s.destination}',
                        style: KxText.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ]),
                ),
                IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => context.go(Routes.editShipment(s.id))),
              ]),
            ),
            const SizedBox(height: KxSpace.sm),
          ],
      ]),
    );
  }
}

// ============================================================================ caixas

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devicesProvider);
    final shipments = ref.watch(shipmentsProvider).value ?? const <Shipment>[];
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e),
      data: (devices) => ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
        Row(children: [
          Expanded(
            child: Text('Cada caixa precisa ter o mesmo código do DEVICE_ID gravado no firmware (ex.: kx-01).', style: KxText.body),
          ),
          const SizedBox(width: KxSpace.md),
          FilledButton.icon(onPressed: () => _editDevice(context, ref), icon: const Icon(Icons.add), label: const Text('Nova caixa')),
        ]),
        const SizedBox(height: KxSpace.lg),
        if (devices.isEmpty)
          const EmptyState(icon: Icons.memory_rounded, title: 'Nenhuma caixa cadastrada', message: 'Cadastre a caixa do Wokwi com o código kx-01.')
        else
          for (final d in devices) ...[
            Builder(builder: (context) {
              final using = shipments.where((s) => s.deviceId == d.id && s.status.isActive).firstOrNull;
              return KxCard(
                padding: const EdgeInsets.symmetric(horizontal: KxSpace.md, vertical: KxSpace.sm),
                child: Row(children: [
                  Icon(Icons.inventory_2_rounded, color: d.online ? KxColors.cyberCyan : KxColors.textLog),
                  const SizedBox(width: KxSpace.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(d.name, style: KxText.h3.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: KxSpace.sm),
                        StatusPill(label: d.online ? 'Online' : 'Offline', color: d.online ? KxColors.electricLime : KxColors.textBody, pulse: d.online),
                      ]),
                      Text(
                        '${d.id}${d.battery == null ? '' : ' · bateria ${d.battery}%'}'
                        '${d.lastSeen == null ? ' · nunca conectou' : ' · visto ${Fmt.ago(d.lastSeen!)}'}'
                        '${using == null ? ' · livre' : ' · na carga ${using.code}'}',
                        style: KxText.body.copyWith(fontSize: 12),
                      ),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    onSelected: (v) => v == 'edit' ? _editDevice(context, ref, d) : _delete(context, ref, d),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Renomear')),
                      PopupMenuItem(value: 'del', child: Text('Remover caixa')),
                    ],
                  ),
                ]),
              );
            }),
            const SizedBox(height: KxSpace.sm),
          ],
      ]),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Device d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover ${d.name}?'),
        content: const Text('O histórico das cargas continua salvo. A caixa só some da lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Remover ${d.id}')),
        ],
      ),
    );
    if (ok == true && context.mounted) await runAction(context, () => ref.read(repositoryProvider).deleteDevice(d.id), success: 'Caixa removida.');
  }

  Future<void> _editDevice(BuildContext context, WidgetRef ref, [Device? d]) {
    final id = TextEditingController(text: d?.id ?? '');
    final name = TextEditingController(text: d?.name ?? '');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(KxSpace.xl, 0, KxSpace.xl, MediaQuery.viewInsetsOf(ctx).bottom + KxSpace.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(d == null ? 'Nova caixa' : 'Renomear caixa', style: KxText.h2),
          const SizedBox(height: KxSpace.lg),
          TextField(
            controller: id,
            enabled: d == null,
            decoration: const InputDecoration(labelText: 'Código da caixa', helperText: 'Igual ao DEVICE_ID do firmware. Ex.: kx-04'),
          ),
          const SizedBox(height: KxSpace.md),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex.: Caixa Kinetix 04')),
          const SizedBox(height: KxSpace.xl),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(ctx, () => ref.read(repositoryProvider).saveDevice(id.text, name.text), success: 'Caixa salva.');
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar caixa'),
          ),
        ]),
      ),
    );
  }
}

// ============================================================================ usuários

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profilesProvider);
    final me = ref.watch(sessionProvider).value;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e),
      data: (users) => ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
        Text('Quem se cadastra entra como Motorista. Mude o tipo de acesso aqui.', style: KxText.body),
        const SizedBox(height: KxSpace.lg),
        for (final u in users) ...[
          KxCard(
            padding: const EdgeInsets.symmetric(horizontal: KxSpace.md, vertical: KxSpace.sm),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: KxColors.cyberCyan.withValues(alpha: 0.12),
                child: Text(u.initials, style: KxText.label.copyWith(color: KxColors.cyberCyan)),
              ),
              const SizedBox(width: KxSpace.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${u.fullName.isEmpty ? u.email : u.fullName}${u.id == me?.id ? ' (você)' : ''}',
                      style: KxText.h3.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
                  Text(u.email, style: KxText.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                ]),
              ),
              DropdownButton<UserRole>(
                value: u.role,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(KxRadius.input),
                items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label))],
                onChanged: (r) => r == null || r == u.role
                    ? null
                    : runAction(context, () => ref.read(repositoryProvider).setRole(u.id, r), success: '${u.firstName} agora é ${r.label}.'),
              ),
            ]),
          ),
          const SizedBox(height: KxSpace.sm),
        ],
      ]),
    );
  }
}
