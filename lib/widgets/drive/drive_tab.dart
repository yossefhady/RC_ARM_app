import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/drive_mode.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../animated_number.dart';
import 'joystick_widget.dart';

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
          _DirectionSection(),
          SizedBox(height: 14),
          Text('PRESETS', style: TextStyle(fontSize: 10)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['0', '64', '128', '192', '255']
                  .map(
                    (t) => Text(
                      t,
                      style: AppText.mono(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Direction Section (toggle + dpad or joystick) ───────────────────────────

class _DirectionSection extends StatefulWidget {
  const _DirectionSection();

  @override
  State<_DirectionSection> createState() => _DirectionSectionState();
}

class _DirectionSectionState extends State<_DirectionSection> {
  // Local dpad press tracking; joystick state lives in JoystickWidget.
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
    if (dir != 'stop') context.read<CtrlNotifier>().onDirectionRelease();
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
    final notifier = context.watch<CtrlNotifier>();
    final mode = notifier.driveCtrlMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIRECTION · MANUAL',
                style: AppText.label(letterSpacing: 0.22),
              ),
              Row(
                children: [
                  _ModeToggle(
                    icon: Icons.apps_rounded,
                    label: 'ARROWS',
                    active: mode == 'dpad',
                    onTap: () =>
                        context.read<CtrlNotifier>().setDriveCtrlMode('dpad'),
                  ),
                  const SizedBox(width: 6),
                  _ModeToggle(
                    icon: Icons.radio_button_checked,
                    label: 'STICK',
                    active: mode == 'joystick',
                    onTap: () => context.read<CtrlNotifier>().setDriveCtrlMode(
                      'joystick',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Status label (dpad only) ──────────────────────────────────
          if (mode == 'dpad') ...[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _stateLabel,
                  style: AppText.mono(
                    fontSize: 10,
                    color: AppColors.accent,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Controller ────────────────────────────────────────────────
          if (mode == 'dpad')
            _DPad(pressed: _pressed, onPress: _press, onRelease: _release)
          else
            SizedBox(
              height: 200,
              child: JoystickWidget(
                onMove: context.read<CtrlNotifier>().onJoystickMove,
                onRelease: context.read<CtrlNotifier>().onJoystickRelease,
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: active ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.mono(
                fontSize: 9,
                weight: FontWeight.w600,
                color: active ? AppColors.accent : AppColors.textMuted,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── D-Pad ───────────────────────────────────────────────────────────────────

class _DPad extends StatelessWidget {
  final Map<String, bool> pressed;
  final void Function(String) onPress;
  final void Function(String) onRelease;

  const _DPad({
    required this.pressed,
    required this.onPress,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DPadHudPainter(),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 80),
                _DPadBtn(
                  icon: Icons.keyboard_arrow_up_rounded,
                  pressed: pressed['up'] ?? false,
                  onPress: () => onPress('up'),
                  onRelease: () => onRelease('up'),
                ),
                const SizedBox(width: 80),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DPadBtn(
                  icon: Icons.keyboard_arrow_left_rounded,
                  pressed: pressed['left'] ?? false,
                  onPress: () => onPress('left'),
                  onRelease: () => onRelease('left'),
                ),
                const SizedBox(width: 8),
                _StopBtn(
                  pressed: pressed['stop'] ?? false,
                  onPress: () => onPress('stop'),
                  onRelease: () => onRelease('stop'),
                ),
                const SizedBox(width: 8),
                _DPadBtn(
                  icon: Icons.keyboard_arrow_right_rounded,
                  pressed: pressed['right'] ?? false,
                  onPress: () => onPress('right'),
                  onRelease: () => onRelease('right'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 80),
                _DPadBtn(
                  icon: Icons.keyboard_arrow_down_rounded,
                  pressed: pressed['down'] ?? false,
                  onPress: () => onPress('down'),
                  onRelease: () => onRelease('down'),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ],
        ),
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
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pressed ? AppColors.accent : AppColors.border,
          ),
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: pressed ? 0.93 : 1.0,
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
        scale: pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipPath(
          clipper: _OctagonClipper(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 72,
            height: 72,
            color: pressed
                ? AppColors.error.withValues(alpha: 0.12)
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
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    p.color = AppColors.accent.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.44, p);
    p.color = AppColors.accent.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.30, p);

    p
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;
    const bl = 10.0;
    const pad = 8.0;
    final corners = [
      [Offset(pad, pad + bl), Offset(pad, pad), Offset(pad + bl, pad)],
      [
        Offset(size.width - pad - bl, pad),
        Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + bl),
      ],
      [
        Offset(pad, size.height - pad - bl),
        Offset(pad, size.height - pad),
        Offset(pad + bl, size.height - pad),
      ],
      [
        Offset(size.width - pad - bl, size.height - pad),
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - bl),
      ],
    ];
    for (final pts in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_DPadHudPainter _) => false;
}

// ─── Mode Chips ───────────────────────────────────────────────────────────────

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
              margin: EdgeInsets.only(right: m == driveModes.last ? 0 : 6),
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
                          color: AppColors.accent.withValues(alpha: 0.18),
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
