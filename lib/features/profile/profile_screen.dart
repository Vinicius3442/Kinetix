import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final repo = ref.watch(repositoryProvider);
    if (me == null) return const SizedBox.shrink();

    Widget tile(IconData icon, String title, String? sub, VoidCallback? onTap, {Color? color}) => ListTile(
          leading: Icon(icon, color: color ?? KxColors.cyberCyan),
          title: Text(title, style: KxText.h3.copyWith(fontSize: 15, color: color)),
          subtitle: sub == null ? null : Text(sub, style: KxText.body.copyWith(fontSize: 13)),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KxRadius.input)),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ContentWidth(
          max: 720,
          child: ListView(padding: const EdgeInsets.all(KxSpace.lg), children: [
            Text('Perfil', style: KxText.h1),
            const SizedBox(height: KxSpace.lg),
            KxCard(
              child: Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: KxColors.cyberCyan.withValues(alpha: 0.15),
                  child: Text(me.initials, style: KxText.h2.copyWith(color: KxColors.cyberCyan)),
                ),
                const SizedBox(width: KxSpace.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.fullName.isEmpty ? me.email : me.fullName, style: KxText.h2),
                    Text(me.email, style: KxText.body),
                    const SizedBox(height: KxSpace.sm),
                    StatusPill(label: me.role.label, color: KxColors.cyberCyan, icon: Icons.badge_outlined),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: KxSpace.md),
            KxCard(
              padding: const EdgeInsets.all(KxSpace.sm),
              child: Column(children: [
                tile(Icons.edit_outlined, 'Editar meus dados', 'Nome, telefone e empresa', () => _edit(context, ref, me)),
                tile(Icons.school_outlined, 'Rever o tutorial', 'Como o Kinetix funciona, em 3 passos', () => context.go(Routes.onboarding)),
                tile(Icons.info_outline_rounded, 'O que posso fazer', me.role.description, null),
              ]),
            ),
            const SizedBox(height: KxSpace.md),
            KxCard(
              padding: const EdgeInsets.all(KxSpace.sm),
              child: Column(children: [
                tile(
                  repo.isDemo ? Icons.science_outlined : Icons.cloud_done_outlined,
                  repo.isDemo ? 'Modo demonstração' : 'Conectado ao servidor',
                  repo.isDemo
                      ? 'Os dados são simulados neste aparelho. Para usar o banco real, rode o app com SUPABASE_URL e SUPABASE_ANON_KEY.'
                      : 'Banco Supabase e telemetria ao vivo via MQTT (${Uri.tryParse(Env.mqttWsUrl)?.host ?? Env.mqttWsUrl}).',
                  null,
                  color: repo.isDemo ? KxColors.telemetryAmber : null,
                ),
                tile(Icons.logout_rounded, 'Sair da conta', null, () => _signOut(context, ref), color: KxColors.talpaLava),
              ]),
            ),
            const SizedBox(height: KxSpace.xl),
            Center(child: Text('Kinetix 2.0 · Talpa Systems · SENAI', style: KxText.log)),
            Center(child: Text('Sensibilidade total onde os olhos não alcançam.', style: KxText.log)),
          ]),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você vai precisar do e-mail e da senha para entrar de novo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ficar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair da conta')),
        ],
      ),
    );
    if (ok == true && context.mounted) await runAction(context, () => ref.read(repositoryProvider).signOut());
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Profile me) {
    final name = TextEditingController(text: me.fullName);
    final phone = TextEditingController(text: me.phone ?? '');
    final company = TextEditingController(text: me.company ?? '');
    final form = GlobalKey<FormState>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(KxSpace.xl, 0, KxSpace.xl, MediaQuery.viewInsetsOf(ctx).bottom + KxSpace.xl),
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Meus dados', style: KxText.h2),
            const SizedBox(height: KxSpace.lg),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().length < 3 ? 'Digite o seu nome.' : null,
            ),
            const SizedBox(height: KxSpace.md),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone (opcional)'), keyboardType: TextInputType.phone),
            const SizedBox(height: KxSpace.md),
            TextFormField(controller: company, decoration: const InputDecoration(labelText: 'Empresa (opcional)')),
            const SizedBox(height: KxSpace.xl),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final ok = await runAction(
                  ctx,
                  () => ref.read(repositoryProvider).updateMyProfile(
                        fullName: name.text,
                        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                        company: company.text.trim().isEmpty ? null : company.text.trim(),
                      ),
                  success: 'Dados salvos.',
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar dados'),
            ),
          ]),
        ),
      ),
    );
  }
}
