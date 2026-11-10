import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/repositories/kinetix_repository.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Fundo com malha de pontos (20 × 20 px), como em softwares de CAD.
class KxBackground extends StatelessWidget {
  const KxBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotGrid(), child: child);
}

class _DotGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = KxColors.dotGrid;
    for (double y = 10; y < size.height; y += 20) {
      for (double x = 10; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card técnico: fundo escuro translúcido, borda de 1 px e brilho reativo
/// (a borda acende em laranja quando [glow] recebe uma cor).
class KxCard extends StatelessWidget {
  const KxCard({super.key, required this.child, this.padding = const EdgeInsets.all(KxSpace.lg), this.glow, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KxRadius.card);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: KxColors.charcoalGlass.withValues(alpha: 0.85),
        borderRadius: radius,
        border: Border.all(color: glow ?? KxColors.borderSlate, width: glow == null ? 1 : 1.4),
        boxShadow: glow == null ? const [] : [BoxShadow(color: glow!.withValues(alpha: 0.35), blurRadius: 12)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Selo pequeno com cor, ícone e texto.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon, this.pulse = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KxRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (pulse) PulseDot(color: color) else if (icon != null) Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: KxText.label.copyWith(color: color, letterSpacing: 0.2)),
      ]),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _Pulse(widget.color, reduce ? 0 : _c.value, widget.size)),
      ),
    );
  }
}

class _Pulse extends CustomPainter {
  _Pulse(this.color, this.t, this.r);
  final Color color;
  final double t;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (t > 0) canvas.drawCircle(c, r / 2 + r / 2 * t, Paint()..color = color.withValues(alpha: 0.5 * (1 - t)));
    canvas.drawCircle(c, r / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Pulse old) => old.t != t || old.color != color;
}

/// Mostrador em arco do Score de Integridade (0 a 100).
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, this.size = 120, this.stroke = 10});
  final double score;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final color = KxColors.forScore(score);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: score),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _Gauge(v, color, stroke),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(v.round().toString(), style: KxText.metric(color).copyWith(fontSize: size * 0.3)),
              Text('de 100', style: KxText.unit.copyWith(fontSize: math.max(10, size * 0.09))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Gauge extends CustomPainter {
  _Gauge(this.v, this.color, this.stroke);
  final double v;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    const start = math.pi * 0.75, sweep = math.pi * 1.5;
    final bg = Paint()
      ..color = KxColors.borderSlate
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep * (v.clamp(0, 100) / 100), false, fg);
  }

  @override
  bool shouldRepaint(covariant _Gauge old) => old.v != v || old.color != color;
}

/// Logo Talpa Vector + nome.
class KxLogo extends StatelessWidget {
  const KxLogo({super.key, this.height = 36, this.showName = true, this.subtitle});
  final double height;
  final bool showName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset('assets/brand/logo.svg', height: height, width: height * 1.6, fit: BoxFit.contain);
    if (!showName) return mark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark,
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('KINETIX', style: TextStyle(fontFamily: kxMono, fontWeight: FontWeight.w700, fontSize: height * 0.48, color: KxColors.textDisplay, letterSpacing: 1.5)),
        if (subtitle != null) Text(subtitle!, style: KxText.log.copyWith(fontSize: 11)),
      ]),
    ]);
  }
}

/// Estado vazio com uma ação clara.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KxSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 40, color: KxColors.cyberCyan),
            const SizedBox(height: KxSpace.md),
            Text(title, style: KxText.h3, textAlign: TextAlign.center),
            const SizedBox(height: KxSpace.sm),
            Text(message, style: KxText.body, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: KxSpace.lg), action!],
          ]),
        ),
      ),
    );
  }
}

/// Mostra erro com mensagem humana e botão para tentar de novo.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Não foi possível carregar',
        message: error is KxException ? error.toString() : 'Verifique a conexão com a internet e tente de novo.',
        action: onRetry == null ? null : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar de novo')),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KxSpace.sm, top: KxSpace.xs),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: KxText.label)),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Limita a largura do conteúdo em telas grandes (web).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.max = 1120});
  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child));
}

/// Mostra uma mensagem rápida no rodapé.
void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: error ? KxColors.talpaLava : KxColors.electricLime, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
}

/// Executa uma ação mostrando erro amigável se falhar.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, e is KxException ? e.message : 'Algo deu errado. Tente de novo.', error: true);
    return false;
  }
}
