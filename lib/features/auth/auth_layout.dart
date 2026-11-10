import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';

/// Moldura comum das telas de entrada: logo, título e um card central.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.subtitle, required this.child, this.footer, this.onBack});

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KxBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: KxSpace.lg, vertical: KxSpace.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back), tooltip: 'Voltar'),
                    ),
                  const Center(child: KxLogo(height: 52, subtitle: 'por Talpa Systems')),
                  const SizedBox(height: KxSpace.xl),
                  Text(title, style: KxText.h1, textAlign: TextAlign.center),
                  const SizedBox(height: KxSpace.sm),
                  Text(subtitle, style: KxText.body, textAlign: TextAlign.center),
                  const SizedBox(height: KxSpace.xl),
                  KxCard(padding: const EdgeInsets.all(KxSpace.xl), child: child),
                  if (footer != null) ...[const SizedBox(height: KxSpace.lg), footer!],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem de erro dentro do formulário (não some sozinha).
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.success = false});
  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final c = success ? KxColors.electricLime : KxColors.talpaLava;
    return Container(
      padding: const EdgeInsets.all(KxSpace.md),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KxRadius.input),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(success ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: KxText.body.copyWith(color: KxColors.textDisplay))),
      ]),
    );
  }
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Digite o seu e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Esse e-mail parece incompleto (ex.: nome@empresa.com).';
  return null;
}

String? validatePassword(String? v) {
  if ((v ?? '').isEmpty) return 'Digite a sua senha.';
  if (v!.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
  return null;
}
