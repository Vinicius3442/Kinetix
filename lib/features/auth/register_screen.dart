import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/kinetix_repository.dart';
import 'auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _hide = true;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(repositoryProvider).signUp(_name.text, _email.text, _password.text);
    } on KxException catch (e) {
      setState(() {
        _message = e.message;
        _success = e.message.startsWith('Conta criada');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Criar conta',
      subtitle: 'Leva menos de um minuto. Um administrador define o seu tipo de acesso.',
      onBack: () => context.go(Routes.login),
      footer: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('Já tem conta?', style: KxText.body),
        TextButton(onPressed: () => context.go(Routes.login), child: const Text('Entrar')),
      ]),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_message != null) ...[FormMessage(_message!, success: _success), const SizedBox(height: KxSpace.lg)],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.badge_outlined)),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().length < 3 ? 'Digite o seu nome.' : null,
            ),
            const SizedBox(height: KxSpace.lg),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validateEmail,
            ),
            const SizedBox(height: KxSpace.lg),
            TextFormField(
              controller: _password,
              obscureText: _hide,
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: 'Pelo menos 6 caracteres.',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hide ? 'Mostrar senha' : 'Esconder senha',
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              autofillHints: const [AutofillHints.newPassword],
              validator: validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: KxSpace.xl),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Criar conta'),
            ),
          ]),
        ),
      ),
    );
  }
}
