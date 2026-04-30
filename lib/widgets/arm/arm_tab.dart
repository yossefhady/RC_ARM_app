import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/arm_preset.dart';
import '../../models/servo_model.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../animated_number.dart';

class ArmTab extends StatelessWidget {
  const ArmTab({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CtrlNotifier>();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRESET POSITIONS', style: AppText.label(letterSpacing: 0.22)),
          const SizedBox(height: 8),
          _PresetGrid(preset: notifier.preset),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SERVOS · 6-DOF', style: AppText.label(letterSpacing: 0.22)),
              Text(
                '● LIVE',
                style: AppText.mono(
                  fontSize: 10,
                  color: AppColors.accent,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...notifier.servos.asMap().entries.map(
            (e) => _ServoCard(servo: e.value, index: e.key),
          ),
        ],
      ),
    );
  }
}

// ─── Preset Grid ──────────────────────────────────────────────────────────────

class _PresetGrid extends StatelessWidget {
  final String? preset;
  const _PresetGrid({required this.preset});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CtrlNotifier>();
    final presets = notifier.settings.loadedPresets;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 2.8,
      children: presets.map((p) {
        final active = preset == p.id;
        return GestureDetector(
          onTap: () => context.read<CtrlNotifier>().applyPreset(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? AppColors.accent : AppColors.border,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _presetIcon(p.id),
                  size: 18,
                  color: active ? AppColors.background : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  p.label,
                  style: AppText.label(
                    fontSize: 10,
                    weight: FontWeight.w700,
                    color: active
                        ? AppColors.background
                        : AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _presetIcon(String id) {
    return switch (id) {
      'home' => Icons.home_outlined,
      'grab' => Icons.pan_tool_outlined,
      'lift' => Icons.vertical_align_top,
      'rest' => Icons.airline_seat_flat_outlined,
      _ => Icons.adjust,
    };
  }
}

// ─── Servo Card ───────────────────────────────────────────────────────────────

class _ServoCard extends StatelessWidget {
  final ServoModel servo;
  final int index;

  const _ServoCard({required this.servo, required this.index});

  @override
  Widget build(BuildContext context) {
    final double maxAngle = context.select<CtrlNotifier, double>(
      (n) => n.settings.getServoMax(servo.id).toDouble(),
    );
    final double minAngle = context.select<CtrlNotifier, double>(
      (n) => n.settings.getServoMin(servo.id).toDouble(),
    );
    
    final List<int> quickAngles = maxAngle == 180.0
        ? [minAngle.round(), 45, 90, 135, maxAngle.round()]
        : [minAngle.round(), (maxAngle / 2).round(), maxAngle.round()];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent left bar
            Container(
              width: 2,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'S${servo.id}',
                              style: AppText.mono(
                                fontSize: 18,
                                weight: FontWeight.w600,
                                color: AppColors.accent,
                                letterSpacing: 0.05,
                              ),
                            ),
                            Text(
                              servo.name,
                              style: AppText.label(
                                fontSize: 10,
                                letterSpacing: 0.12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AnimatedNumber(
                              value: servo.value,
                              padded: true,
                              style: AppText.mono(
                                fontSize: 22,
                                weight: FontWeight.w500,
                                letterSpacing: -0.02,
                              ),
                            ),
                            Text(
                              '°',
                              style: AppText.mono(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.background,
                        overlayColor: AppColors.accent.withValues(alpha: 0.15),
                        thumbShape: _ServoThumbShape(),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: servo.value.toDouble().clamp(minAngle, maxAngle),
                        min: minAngle,
                        max: maxAngle,
                        onChanged: (v) => context.read<CtrlNotifier>().setServo(
                          index,
                          v.round(),
                        ),
                        onChangeEnd: (v) => context.read<CtrlNotifier>().endServo(
                          index,
                          v.round(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Quick-angle chips
                    Row(
                      children: quickAngles.map((a) {
                        final active = servo.value == a;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                context.read<CtrlNotifier>().endServo(index, a),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: EdgeInsets.only(
                                right: a == quickAngles.last ? 0 : 4,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.accent.withValues(alpha: 0.12)
                                    : AppColors.surfaceDeep,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: active
                                      ? AppColors.accent
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                '$a°',
                                textAlign: TextAlign.center,
                                style: AppText.mono(
                                  fontSize: 10,
                                  weight: FontWeight.w500,
                                  color: active
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServoThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 12);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Outer ring (accent border)
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Inner fill (dark background)
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.fill,
    );
    // Glow
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}
