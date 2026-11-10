import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Guarda os traços da assinatura e exporta como SVG (texto leve para o banco).
class SignatureController extends ChangeNotifier {
  final List<List<Offset>> strokes = [];
  Size size = const Size(400, 160);

  bool get isEmpty => strokes.every((s) => s.length < 2);

  void start(Offset p) {
    strokes.add([p]);
    notifyListeners();
  }

  void extend(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  String? toSvg() {
    if (isEmpty) return null;
    final paths = strokes.where((s) => s.length > 1).map((s) {
      final b = StringBuffer('M${s.first.dx.toStringAsFixed(1)} ${s.first.dy.toStringAsFixed(1)}');
      for (final p in s.skip(1)) {
        b.write(' L${p.dx.toStringAsFixed(1)} ${p.dy.toStringAsFixed(1)}');
      }
      return '<path d="$b"/>';
    }).join();
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size.width.round()} ${size.height.round()}">'
        '<g fill="none" stroke="#0B0E14" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">$paths</g></svg>';
  }
}

class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.height = 160, this.hasError = false});
  final SignatureController controller;
  final double height;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(KxRadius.input),
          border: Border.all(color: hasError ? KxColors.talpaLava : KxColors.borderSlate, width: hasError ? 1.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KxRadius.input),
          child: LayoutBuilder(builder: (context, c) {
            controller.size = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              onPanStart: (d) => controller.start(d.localPosition),
              onPanUpdate: (d) => controller.extend(d.localPosition),
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => CustomPaint(
                  painter: _SignaturePainter(controller.strokes),
                  child: controller.isEmpty
                      ? Center(child: Text('Assine aqui com o dedo', style: KxText.body.copyWith(color: const Color(0xFF8A96A8))))
                      : const SizedBox.expand(),
                ),
              ),
            );
          }),
        ),
      ),
      Row(children: [
        if (hasError) Text('Falta a assinatura.', style: KxText.body.copyWith(color: KxColors.talpaLava, fontSize: 12)),
        const Spacer(),
        TextButton.icon(
            onPressed: controller.clear, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Limpar assinatura')),
      ]),
    ]);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(16, size.height - 32), Offset(size.width - 16, size.height - 32), guide);
    final p = Paint()
      ..color = const Color(0xFF0B0E14)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final pt in s.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
