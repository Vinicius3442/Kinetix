import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/kinetix_repository.dart';
import 'auth_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).sendPasswordReset(_email.text);
      setState(() => _sent = true);
    } on KxException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void back() => context.canPop() ? context.pop() : context.go(Routes.login);
    return AuthLayout(
      title: 'Recuperar senha',
      subtitle: 'Enviaremos um link para você criar uma senha nova.',
      onBack: back,
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) ...[FormMessage(_error!), const SizedBox(height: KxSpace.lg)],
          if (_sent) ...[
            FormMessage(
                'Pronto! Se existir uma conta com ${_email.text.trim()}, o link chega em alguns minutos. Confira também a caixa de spam.',
                success: true),
            const SizedBox(height: KxSpace.lg),
            FilledButton(onPressed: back, child: const Text('Voltar para entrar')),
          ] else ...[
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail da conta', prefixIcon: Icon(Icons.mail_outline)),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: validateEmail,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: KxSpace.xl),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar link'),
            ),
          ],
        ]),
      ),
    );
  }
}
