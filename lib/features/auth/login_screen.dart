import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../data/repositories/demo_repository.dart';
import '../../data/repositories/kinetix_repository.dart';
import 'auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({String? email, String? password}) async {
    if (email == null && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).signIn(email ?? _email.text, password ?? _password.text);
    } on KxException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível entrar agora. Tente de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(repositoryProvider).isDemo;
    return AuthLayout(
      title: 'Entrar',
      subtitle: 'Acompanhe suas cargas em tempo real.',
      footer: Column(children: [
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Ainda não tem conta?', style: KxText.body),
          TextButton(onPressed: () => context.go(Routes.register), child: const Text('Criar conta')),
        ]),
        const SizedBox(height: KxSpace.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.publicScanner),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Recebi uma carga: ler QR Code'),
        ),
        if (isDemo) ...[
          const SizedBox(height: KxSpace.xl),
          _DemoAccess(busy: _busy, onPick: (e) => _submit(email: e, password: 'kinetix'))
        ],
      ]),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ...[FormMessage(_error!), const SizedBox(height: KxSpace.lg)],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validateEmail,
              onChanged: (_) => _error == null ? null : setState(() => _error = null),
            ),
            const SizedBox(height: KxSpace.lg),
            TextFormField(
              controller: _password,
              obscureText: _hide,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hide ? 'Mostrar senha' : 'Esconder senha',
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.push(Routes.forgot), child: const Text('Esqueci a senha')),
            ),
            const SizedBox(height: KxSpace.sm),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Entrar'),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Atalhos do modo demonstração: entrar com um perfil pronto.
class _DemoAccess extends StatelessWidget {
  const _DemoAccess({required this.onPick, required this.busy});
  final ValueChanged<String> onPick;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('MODO DEMONSTRAÇÃO · ENTRAR COMO', style: KxText.label.copyWith(color: KxColors.telemetryAmber)),
      const SizedBox(height: KxSpace.md),
      Wrap(spacing: KxSpace.sm, runSpacing: KxSpace.sm, alignment: WrapAlignment.center, children: [
        for (final e in DemoRepository.demoUsers.entries.where((e) => e.value.$2 != UserRole.destinatario))
          ActionChip(
            avatar: Icon(
                switch (e.value.$2) {
                  UserRole.admin => Icons.admin_panel_settings_outlined,
                  UserRole.gestor => Icons.insights_outlined,
                  _ => Icons.local_shipping_outlined,
                },
                size: 18,
                color: KxColors.cyberCyan),
            label: Text(e.value.$2.label),
            onPressed: busy ? null : () => onPick(e.key),
          ),
      ]),
    ]);
  }
}
