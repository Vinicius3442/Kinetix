import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';
import '../../data/providers.dart';
import '../twin/digital_twin.dart';

/// Tutorial curto (3 passos), mostrado no primeiro acesso.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _steps = [
    (
      'A caixa sente tudo',
      'Dentro de cada caixa Kinetix há sensores que percebem solavancos, se ela tombou, se foi aberta e a temperatura da carga.',
      Icons.sensors_rounded,
    ),
    (
      'Você acompanha ao vivo',
      'O modelo 3D se move igual à caixa real. Se algo acontecer, você recebe um alerta na hora e a nota da carga (de 0 a 100) diminui.',
      Icons.view_in_ar_rounded,
    ),
    (
      'Na entrega, o QR Code prova tudo',
      'Quem recebe lê o QR Code da etiqueta, vê o histórico completo da viagem e assina a entrega no próprio celular.',
      Icons.qr_code_2_rounded,
    ),
  ];

  Future<void> _finish() async {
    await runAction(context, () => ref.read(repositoryProvider).markOnboarded());
    if (mounted) context.go(Routes.shipments);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _steps.length - 1;
    return Scaffold(
      body: KxBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(KxSpace.lg),
                child: Column(children: [
                  Row(children: [
                    const KxLogo(height: 28),
                    const Spacer(),
                    if (!last) TextButton(onPressed: _finish, child: const Text('Pular')),
                  ]),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: _steps.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        final (title, text, icon) = _steps[i];
                        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(
                            height: 230,
                            child: i == 1
                                ? const _DemoTwin()
                                : Icon(icon, size: 110, color: i == 0 ? KxColors.cyberCyan : KxColors.talpaLava),
                          ),
                          const SizedBox(height: KxSpace.xl),
                          Text('PASSO ${i + 1} DE ${_steps.length}', style: KxText.label.copyWith(color: KxColors.cyberCyan)),
                          const SizedBox(height: KxSpace.sm),
                          Text(title, style: KxText.h1, textAlign: TextAlign.center),
                          const SizedBox(height: KxSpace.md),
                          Text(text, style: KxText.body.copyWith(fontSize: 16), textAlign: TextAlign.center),
                        ]);
                      },
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < _steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(4),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? KxColors.cyberCyan : KxColors.borderSlate,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ]),
                  const SizedBox(height: KxSpace.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: last
                          ? _finish
                          : () => _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                      child: Text(last ? 'Começar a usar' : 'Próximo'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caixa 3D balançando sozinha, só para ilustrar.
class _DemoTwin extends StatefulWidget {
  const _DemoTwin();

  @override
  State<_DemoTwin> createState() => _DemoTwinState();
}

class _DemoTwinState extends State<_DemoTwin> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 6.283;
          return DigitalTwin(roll: 18 * (t < 3 ? (t / 3) : (6.283 - t) / 3.283), pitch: 4, yaw: 30, interactive: false);
        },
      );
}
