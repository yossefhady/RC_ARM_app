import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class JoystickWidget extends StatefulWidget {
  final void Function(double x, double y) onMove;
  final VoidCallback onRelease;

  const JoystickWidget({
    super.key,
    required this.onMove,
    required this.onRelease,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  Offset _knob = Offset.zero;
  bool _active = false;

  static const double _baseR = 72.0;
  static const double _knobR = 26.0;

  void _update(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var delta = local - center;
    if (delta.distance > _baseR) delta = delta / delta.distance * _baseR;
    setState(() {
      _knob = delta;
      _active = true;
    });
    // Flip Y so dragging up → positive y → forward.
    widget.onMove(delta.dx / _baseR, -delta.dy / _baseR);
  }

  void _release() {
    setState(() {
      _knob = Offset.zero;
      _active = false;
    });
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _update(d.localPosition, size),
          onPanEnd: (_) => _release(),
          onPanCancel: _release,
          child: CustomPaint(
            painter: _JoystickPainter(
              knob: _knob,
              active: _active,
              baseR: _baseR,
              knobR: _knobR,
            ),
            size: size,
          ),
        );
      },
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knob;
  final bool active;
  final double baseR;
  final double knobR;

  const _JoystickPainter({
    required this.knob,
    required this.active,
    required this.baseR,
    required this.knobR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // ── Base ring ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = AppColors.surfaceDeep
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Crosshairs ───────────────────────────────────────────────────────────
    final hairPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.25)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(c.dx - baseR, c.dy), Offset(c.dx + baseR, c.dy), hairPaint);
    canvas.drawLine(Offset(c.dx, c.dy - baseR), Offset(c.dx, c.dy + baseR), hairPaint);

    // ── Direction arrows ─────────────────────────────────────────────────────
    _arrow(canvas, c + Offset(0, -(baseR - 12)), 0);
    _arrow(canvas, c + Offset(0,  (baseR - 12)), pi);
    _arrow(canvas, c + Offset(-(baseR - 12), 0), -pi / 2);
    _arrow(canvas, c + Offset( (baseR - 12), 0),  pi / 2);

    // ── Knob shadow ──────────────────────────────────────────────────────────
    final kc = c + knob;
    canvas.drawCircle(
      kc,
      knobR + 4,
      Paint()
        ..color = AppColors.accent.withValues(alpha: active ? 0.25 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Knob fill ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      kc,
      knobR,
      Paint()
        ..color = active ? AppColors.accent : AppColors.surface
        ..style = PaintingStyle.fill,
    );

    // ── Knob border ──────────────────────────────────────────────────────────
    canvas.drawCircle(
      kc,
      knobR,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Knob centre dot ──────────────────────────────────────────────────────
    canvas.drawCircle(
      kc,
      5,
      Paint()
        ..color = active ? AppColors.surface : AppColors.accent
        ..style = PaintingStyle.fill,
    );
  }

  void _arrow(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, -5)
        ..lineTo(-4, 2)
        ..lineTo(4, 2)
        ..close(),
      Paint()
        ..color = AppColors.textMuted.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      knob != old.knob || active != old.active;
}
