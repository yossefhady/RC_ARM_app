import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/drive_mode.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../animated_number.dart';

class DriveTab extends StatelessWidget {
  const DriveTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpeedSlider(),
          SizedBox(height: 14),
          _DPad(),
          SizedBox(height: 14),
          _ModeSectionLabel(),
          SizedBox(height: 8),
          _ModeChips(),
        ],
      ),
    );
  }
}

// ─── Speed Slider ─────────────────────────────────────────────────────────────

class _SpeedSlider extends StatelessWidget {
  const _SpeedSlider();

  @override
  Widget build(BuildContext context) {
    final speed = context.watch<CtrlNotifier>().speed;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('PWM SPEED', style: AppText.label(letterSpacing: 0.22)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedNumber(
                    value: speed,
                    padded: true,
                    style: AppText.mono(
                      fontSize: 32,
                      weight: FontWeight.w500,
                      color: AppColors.accent,
                      letterSpacing: -0.02,
                    ),
                  ),
                  Text(
                    ' / 255',
                    style: AppText.mono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: speed.toDouble(),
              min: 0,
              max: 255,
              onChanged: (v) =>
                  context.read<CtrlNotifier>().setSpeed(v.round()),
            ),
          ),
          // Tick labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['0', '64', '128', '192', '255']
                  .map((t) => Text(t, style: AppText.mono(fontSize: 8, color: AppColors.textMuted)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── D-Pad ───────────────────────────────────────────────────────────────────

class _DPad extends StatefulWidget {
  const _DPad();

  @override
  State<_DPad> createState() => _DPadState();
}

class _DPadState extends State<_DPad> {
  final Map<String, bool> _pressed = {};

  void _press(String dir) {
    HapticFeedback.lightImpact();
    setState(() => _pressed[dir] = true);
    if (dir == 'stop') {
      context.read<CtrlNotifier>().onStop();
    } else {
      context.read<CtrlNotifier>().onDirectionPress(dir);
    }
  }

  void _release(String dir) {
    setState(() => _pressed[dir] = false);
    if (dir != 'stop') {
      context.read<CtrlNotifier>().onDirectionRelease();
    }
  }

  String get _stateLabel {
    if (_pressed['up'] == true) return 'FWD';
    if (_pressed['down'] == true) return 'REV';
    if (_pressed['left'] == true) return 'L-TURN';
    if (_pressed['right'] == true) return 'R-TURN';
    return 'IDLE';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIRECTION · MANUAL',
                style: AppText.label(letterSpacing: 0.22),
              ),
              Text(
                _stateLabel,
                style: AppText.mono(
                  fontSize: 10,
                  color: AppColors.accent,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Button grid
          CustomPaint(
            painter: _DPadHudPainter(),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Row 1: _ UP _
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 72),
                      const SizedBox(width: 8),
                      _DPadBtn(
                        icon: Icons.keyboard_arrow_up_rounded,
                        pressed: _pressed['up'] ?? false,
                        onPress: () => _press('up'),
                        onRelease: () => _release('up'),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 72),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: LEFT  STOP  RIGHT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DPadBtn(
                        icon: Icons.keyboard_arrow_left_rounded,
                        pressed: _pressed['left'] ?? false,
                        onPress: () => _press('left'),
                        onRelease: () => _release('left'),
                      ),
                      const SizedBox(width: 8),
                      _StopBtn(
                        pressed: _pressed['stop'] ?? false,
                        onPress: () => _press('stop'),
                        onRelease: () => _release('stop'),
                      ),
                      const SizedBox(width: 8),
                      _DPadBtn(
                        icon: Icons.keyboard_arrow_right_rounded,
                        pressed: _pressed['right'] ?? false,
                        onPress: () => _press('right'),
                        onRelease: () => _release('right'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 3: _ DOWN _
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 72),
                      const SizedBox(width: 8),
                      _DPadBtn(
                        icon: Icons.keyboard_arrow_down_rounded,
                        pressed: _pressed['down'] ?? false,
                        onPress: () => _press('down'),
                        onRelease: () => _release('down'),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 72),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadBtn extends StatelessWidget {
  final IconData icon;
  final bool pressed;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  const _DPadBtn({
    required this.icon,
    required this.pressed,
    required this.onPress,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPress(),
      onPointerUp: (_) => onRelease(),
      onPointerCancel: (_) => onRelease(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: pressed
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pressed ? AppColors.accent : AppColors.border,
          ),
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Icon(
            icon,
            size: 32,
            color: pressed ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StopBtn extends StatelessWidget {
  final bool pressed;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  const _StopBtn({
    required this.pressed,
    required this.onPress,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPress(),
      onPointerUp: (_) => onRelease(),
      onPointerCancel: (_) => onRelease(),
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipPath(
          clipper: _OctagonClipper(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 72,
            height: 72,
            color: pressed
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.surface,
            child: Center(
              child: Text(
                'STOP',
                style: AppText.mono(
                  fontSize: 13,
                  weight: FontWeight.w700,
                  color: pressed ? AppColors.error : AppColors.textPrimary,
                  letterSpacing: 0.12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * 0.30, 0)
    ..lineTo(s.width * 0.70, 0)
    ..lineTo(s.width, s.height * 0.30)
    ..lineTo(s.width, s.height * 0.70)
    ..lineTo(s.width * 0.70, s.height)
    ..lineTo(s.width * 0.30, s.height)
    ..lineTo(0, s.height * 0.70)
    ..lineTo(0, s.height * 0.30)
    ..close();

  @override
  bool shouldReclip(_OctagonClipper _) => false;
}

class _DPadHudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Faint concentric circles
    paint.color = AppColors.accent.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.44, paint);
    paint.color = AppColors.accent.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.3, paint);

    // Corner brackets
    paint
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;
    const bl = 10.0; // bracket length
    const pad = 8.0;
    final corners = [
      // top-left
      [Offset(pad, pad + bl), Offset(pad, pad), Offset(pad + bl, pad)],
      // top-right
      [
        Offset(size.width - pad - bl, pad),
        Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + bl),
      ],
      // bottom-left
      [
        Offset(pad, size.height - pad - bl),
        Offset(pad, size.height - pad),
        Offset(pad + bl, size.height - pad),
      ],
      // bottom-right
      [
        Offset(size.width - pad - bl, size.height - pad),
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - bl),
      ],
    ];
    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DPadHudPainter _) => false;
}

// ─── Mode Chips ───────────────────────────────────────────────────────────────

class _ModeSectionLabel extends StatelessWidget {
  const _ModeSectionLabel();

  @override
  Widget build(BuildContext context) => Text(
        'PRESETS',
        style: AppText.label(letterSpacing: 0.22),
      );
}

class _ModeChips extends StatelessWidget {
  const _ModeChips();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<CtrlNotifier>().mode;
    return Row(
      children: driveModes.map((m) {
        final active = mode == m.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.read<CtrlNotifier>().setMode(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: m == driveModes.last ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.border,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                m.label,
                textAlign: TextAlign.center,
                style: AppText.label(
                  fontSize: 9,
                  weight: FontWeight.w600,
                  color: active ? AppColors.accent : AppColors.textMuted,
                  letterSpacing: 0.18,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
