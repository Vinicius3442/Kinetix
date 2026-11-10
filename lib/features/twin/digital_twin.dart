import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/tokens.dart';

/// Gêmeo Digital 3D da caixa.
///
/// Desenha a caixa em perspectiva e gira com os ângulos do MPU6050
/// (roll, pitch, yaw). Recursos pensados para quem não é técnico:
/// - setas "este lado para cima" na frente da caixa;
/// - contorno pontilhado mostrando a posição correta quando a caixa inclina;
/// - tremor rápido quando há impacto ([impactKey] muda);
/// - arestas acendem em laranja quando há alerta.
///
/// Arraste para girar a câmera; toque duas vezes para voltar à vista padrão.
class DigitalTwin extends StatefulWidget {
  const DigitalTwin({
    super.key,
    required this.roll,
    required this.pitch,
    required this.yaw,
    this.alert = false,
    this.impactKey = 0,
    this.lidOpen = false,
    this.interactive = true,
    this.semanticLabel,
  });

  final double roll;
  final double pitch;
  final double yaw;
  final bool alert;

  /// Mude este número para disparar o tremor de impacto.
  final int impactKey;

  /// Mostra a tampa entreaberta (caixa aberta / luz detectada).
  final bool lidOpen;
  final bool interactive;
  final String? semanticLabel;

  @override
  State<DigitalTwin> createState() => _DigitalTwinState();
}

class _DigitalTwinState extends State<DigitalTwin> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  // orientação exibida (suavizada) e câmera
  double _roll = 0, _pitch = 0, _yaw = 0, _lid = 0;
  double _camYaw = -0.6, _camPitch = 0.42;
  double _shake = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _roll = widget.roll;
    _pitch = widget.pitch;
    _yaw = widget.yaw;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void didUpdateWidget(covariant DigitalTwin old) {
    super.didUpdateWidget(old);
    if (widget.impactKey != old.impactKey && !_reduceMotion) _shake = 1;
  }

  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = now;
    final k = _reduceMotion ? 1.0 : 1 - math.exp(-dt * 7);
    double approach(double cur, double target) => cur + (target - cur) * k;
    double approachAngle(double cur, double target) {
      var d = (target - cur) % 360;
      if (d > 180) d -= 360;
      if (d < -180) d += 360;
      return cur + d * k;
    }

    final nr = approach(_roll, widget.roll), np = approach(_pitch, widget.pitch), ny = approachAngle(_yaw, widget.yaw);
    final nl = approach(_lid, widget.lidOpen ? 1 : 0);
    final ns = math.max(0.0, _shake - dt * 2.2);
    final moved =
        (nr - _roll).abs() > 0.01 || (np - _pitch).abs() > 0.01 || (ny - _yaw).abs() > 0.01 || (nl - _lid).abs() > 0.002 || _shake > 0;
    if (moved) {
      setState(() {
        _roll = nr;
        _pitch = np;
        _yaw = ny;
        _lid = nl;
        _shake = ns;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _TwinPainter(
      roll: _roll,
      pitch: _pitch,
      yaw: _yaw,
      lid: _lid,
      camYaw: _camYaw,
      camPitch: _camPitch,
      shake: _shake,
      alert: widget.alert,
      time: _last.inMilliseconds / 1000,
    );
    Widget canvas = CustomPaint(painter: painter, size: Size.infinite);
    if (widget.interactive) {
      canvas = GestureDetector(
        onPanUpdate: (d) => setState(() {
          _camYaw -= d.delta.dx * 0.01;
          _camPitch = (_camPitch + d.delta.dy * 0.006).clamp(0.05, 1.2);
        }),
        onDoubleTap: () => setState(() {
          _camYaw = -0.6;
          _camPitch = 0.42;
        }),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: canvas),
      );
    }
    return Semantics(label: widget.semanticLabel ?? 'Gêmeo digital da caixa', image: true, child: canvas);
  }
}

class _TwinPainter extends CustomPainter {
  _TwinPainter({
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.lid,
    required this.camYaw,
    required this.camPitch,
    required this.shake,
    required this.alert,
    required this.time,
  });

  final double roll, pitch, yaw, lid, camYaw, camPitch, shake, time;
  final bool alert;

  static const hx = 1.05, hy = 0.72, hz = 0.78; // meia largura / altura / profundidade
  static const floorY = -1.35;
  static const camDist = 6.2;

  // vértice i: bit0 → +x, bit1 → +y, bit2 → +z
  static final _verts = List.generate(8, (i) => vm.Vector3(i & 1 == 1 ? hx : -hx, i & 2 == 2 ? hy : -hy, i & 4 == 4 ? hz : -hz));
  static const _faces = [
    [1, 3, 7, 5], // +x
    [4, 6, 2, 0], // -x
    [2, 6, 7, 3], // +y (tampa)
    [0, 1, 5, 4], // -y
    [4, 5, 7, 6], // +z (frente)
    [0, 2, 3, 1], // -z
  ];
  static const _normals = [
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1]
  ];
  static const _edges = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7],
    [0, 2],
    [1, 3],
    [4, 6],
    [5, 7],
    [0, 4],
    [1, 5],
    [2, 6],
    [3, 7]
  ];

  static double _rad(double d) => d * math.pi / 180;

  vm.Matrix3 get _model {
    // sensor: X = comprimento, Y = lateral (→ -Z da cena), Z = cima (→ Y da cena)
    final ry = vm.Matrix3.rotationY(_rad(yaw));
    final rz = vm.Matrix3.rotationZ(_rad(-pitch));
    final rx = vm.Matrix3.rotationX(_rad(roll));
    return ry * rz * rx;
  }

  vm.Matrix3 get _view => vm.Matrix3.rotationX(camPitch) * vm.Matrix3.rotationY(camYaw);

  @override
  void paint(Canvas canvas, Size size) {
    final f = size.shortestSide * 1.55;
    final center = Offset(size.width / 2, size.height * 0.52);
    final jitter = shake > 0 ? Offset(math.sin(time * 90) * 7 * shake, math.cos(time * 77) * 5 * shake) : Offset.zero;
    final view = _view;
    final model = _model;
    final edgeColor = alert ? KxColors.talpaLava : KxColors.cyberCyan;

    Offset project(vm.Vector3 world, {bool shaken = true}) {
      final p = view.transform(world.clone());
      final d = camDist - p.z;
      return center + Offset(p.x * f / d, -p.y * f / d) + (shaken ? jitter : Offset.zero);
    }

    _paintFloor(canvas, project, edgeColor);

    // sombra no piso
    final shadowCenter = project(vm.Vector3(0, floorY, 0), shaken: false);
    final tilt = math.min(1.0, (roll.abs() + pitch.abs()) / 90);
    final shadowPaint = Paint()
      ..shader = RadialGradient(colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent])
          .createShader(Rect.fromCenter(center: shadowCenter, width: f * 0.75, height: f * 0.22));
    canvas.drawOval(Rect.fromCenter(center: shadowCenter, width: f * (0.62 + 0.15 * tilt), height: f * (0.16 + 0.04 * tilt)), shadowPaint);

    // contorno da posição correta (em pé) quando a caixa inclina
    final tiltDeg = math.acos((math.cos(_rad(roll)) * math.cos(_rad(pitch))).clamp(-1.0, 1.0)) * 180 / math.pi;
    if (tiltDeg > 8) {
      final upright = vm.Matrix3.rotationY(_rad(yaw));
      final pts = _verts.map((v) => project(upright.transform(v.clone()), shaken: false)).toList();
      final ghost = Paint()
        ..color = KxColors.textBody.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final e in _edges) {
        _dashed(canvas, pts[e[0]], pts[e[1]], ghost);
      }
    }

    // caixa
    final world = _verts.map((v) => model.transform(v.clone())).toList();
    final screen = world.map(project).toList();
    final viewSpace = world.map((w) => view.transform(w.clone())).toList();
    final light = vm.Vector3(-0.45, 0.8, 0.55)..normalize();

    final faces = <({int i, double depth, double shade})>[];
    for (var i = 0; i < 6; i++) {
      final n =
          view.transform(model.transform(vm.Vector3(_normals[i][0].toDouble(), _normals[i][1].toDouble(), _normals[i][2].toDouble())));
      // face visível se estiver voltada para a câmera
      final c = _faces[i].map((k) => viewSpace[k]).reduce((a, b) => a + b) / 4.0;
      final toCam = vm.Vector3(0, 0, camDist) - c;
      if (n.dot(toCam) <= 0) continue;
      final shade = 0.22 + 0.78 * math.max(0, n.dot(light));
      faces.add((i: i, depth: c.z, shade: shade));
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    const dark = Color(0xFF16222F), lit = Color(0xFF34536D);
    for (final face in faces) {
      final path = Path()..addPolygon(_faces[face.i].map((k) => screen[k]).toList(), true);
      canvas.drawPath(path, Paint()..color = Color.lerp(dark, lit, face.shade)!);
      if (face.i == 4) _paintFrontDecals(canvas, model, project, edgeColor);
      if (face.i == 2 && lid > 0.01) _paintOpening(canvas, model, project);
    }

    // arestas com brilho
    final glow = Paint()
      ..color = edgeColor.withValues(alpha: alert ? 0.45 : 0.25)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final visibleEdges = <List<int>>{};
    for (final face in faces) {
      final idx = _faces[face.i];
      for (var k = 0; k < 4; k++) {
        final a = idx[k], b = idx[(k + 1) % 4];
        visibleEdges.add(a < b ? [a, b] : [b, a]);
      }
    }
    for (final e in _edges) {
      final visible = visibleEdges.any((v) => v[0] == math.min(e[0], e[1]) && v[1] == math.max(e[0], e[1]));
      if (!visible) {
        _dashed(
            canvas,
            screen[e[0]],
            screen[e[1]],
            Paint()
              ..color = edgeColor.withValues(alpha: 0.18)
              ..strokeWidth = 1);
        continue;
      }
      canvas.drawLine(screen[e[0]], screen[e[1]], glow);
      canvas.drawLine(screen[e[0]], screen[e[1]], line);
    }

    // tampa entreaberta (caixa aberta)
    if (lid > 0.01) _paintLid(canvas, model, project, edgeColor);

    // vértices
    final dot = Paint()..color = edgeColor;
    for (final face in faces) {
      for (final k in _faces[face.i]) {
        canvas.drawCircle(screen[k], 2, dot);
      }
    }
  }

  void _paintFloor(Canvas canvas, Offset Function(vm.Vector3, {bool shaken}) project, Color color) {
    final p = Paint()..strokeWidth = 1;
    const r = 3.2, step = 0.4;
    for (double u = -r; u <= r + 0.001; u += step) {
      for (var dir = 0; dir < 2; dir++) {
        for (double v = -r; v < r - 0.001; v += step) {
          final a = dir == 0 ? vm.Vector3(u, floorY, v) : vm.Vector3(v, floorY, u);
          final b = dir == 0 ? vm.Vector3(u, floorY, v + step) : vm.Vector3(v + step, floorY, u);
          final mid = (a + b) / 2.0;
          final fade = math.exp(-(mid.x * mid.x + mid.z * mid.z) / 4.5);
          if (fade < 0.04) continue;
          p.color = KxColors.cyberCyan.withValues(alpha: 0.16 * fade);
          canvas.drawLine(project(a, shaken: false), project(b, shaken: false), p);
        }
      }
    }
  }

  /// Setas "este lado para cima" e etiqueta na frente da caixa.
  void _paintFrontDecals(Canvas canvas, vm.Matrix3 model, Offset Function(vm.Vector3, {bool shaken}) project, Color color) {
    const z = hz + 0.002;
    Offset pt(double x, double y) => project(model.transform(vm.Vector3(x, y, z)));
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    for (final cx in [-0.62, -0.32]) {
      final arrow = Path()
        ..addPolygon([
          pt(cx - 0.035, -0.32),
          pt(cx + 0.035, -0.32),
          pt(cx + 0.035, 0.18),
          pt(cx + 0.11, 0.18),
          pt(cx, 0.4),
          pt(cx - 0.11, 0.18),
          pt(cx - 0.035, 0.18),
        ], true);
      canvas.drawPath(arrow, paint);
    }
    final base = pt(-0.78, -0.48), end = pt(-0.16, -0.48);
    canvas.drawLine(
        base,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 2);

    // etiqueta com QR
    final label = Path()..addPolygon([pt(0.25, 0.42), pt(0.85, 0.42), pt(0.85, -0.42), pt(0.25, -0.42)], true);
    canvas.drawPath(label, Paint()..color = const Color(0xFFE8EEF4).withValues(alpha: 0.9));
    final qr = Paint()..color = const Color(0xFF0B0E14);
    final rnd = math.Random(4);
    const cells = 7, x0 = 0.33, y0 = 0.32, s = 0.06;
    for (var i = 0; i < cells; i++) {
      for (var j = 0; j < cells; j++) {
        final finder = (i < 2 && j < 2) || (i > 4 && j < 2) || (i < 2 && j > 4);
        if (!finder && rnd.nextBool()) continue;
        final cell = Path()
          ..addPolygon([
            pt(x0 + i * s, y0 - j * s),
            pt(x0 + (i + 1) * s, y0 - j * s),
            pt(x0 + (i + 1) * s, y0 - (j + 1) * s),
            pt(x0 + i * s, y0 - (j + 1) * s),
          ], true);
        canvas.drawPath(cell, qr);
      }
    }
    final stripe = Path()..addPolygon([pt(0.25, -0.24), pt(0.85, -0.24), pt(0.85, -0.42), pt(0.25, -0.42)], true);
    canvas.drawPath(stripe, Paint()..color = KxColors.talpaLava);
  }

  /// Luz entrando pela abertura.
  void _paintOpening(Canvas canvas, vm.Matrix3 model, Offset Function(vm.Vector3, {bool shaken}) project) {
    const y = hy + 0.002;
    final pts = [
      project(model.transform(vm.Vector3(-hx * 0.92, y, -hz * 0.9))),
      project(model.transform(vm.Vector3(hx * 0.92, y, -hz * 0.9))),
      project(model.transform(vm.Vector3(hx * 0.92, y, hz * 0.9))),
      project(model.transform(vm.Vector3(-hx * 0.92, y, hz * 0.9))),
    ];
    canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = const Color(0xFFFFE2B8).withValues(alpha: 0.75 * lid));
  }

  void _paintLid(Canvas canvas, vm.Matrix3 model, Offset Function(vm.Vector3, {bool shaken}) project, Color color) {
    final angle = lid * 0.8; // abre girando na aresta de trás
    final hinge = vm.Matrix3.rotationX(-angle);
    vm.Vector3 lidPt(double x, double z) {
      final local = hinge.transform(vm.Vector3(x, 0, z + hz)) + vm.Vector3(0, hy, -hz);
      return model.transform(local);
    }

    final pts = [lidPt(-hx, -hz), lidPt(hx, -hz), lidPt(hx, hz), lidPt(-hx, hz)].map(project).toList();
    canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = const Color(0xFF223446));
    canvas.drawPath(
        Path()..addPolygon(pts, true),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p) {
    final len = (b - a).distance;
    if (len < 1) return;
    final dir = (b - a) / len;
    for (double d = 0; d < len; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, len), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinPainter o) =>
      o.roll != roll ||
      o.pitch != pitch ||
      o.yaw != yaw ||
      o.lid != lid ||
      o.camYaw != camYaw ||
      o.camPitch != camPitch ||
      o.shake != shake ||
      o.alert != alert;
}
