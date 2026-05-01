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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showSaveDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.save_outlined,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SAVE',
                            style: AppText.mono(
                              fontSize: 10,
                              weight: FontWeight.w600,
                              color: AppColors.accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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

  Future<void> _showSaveDialog(BuildContext context) async {
    final notifier = context.read<CtrlNotifier>();
    final presets = notifier.settings.loadedPresets;
    final result = await showDialog<_SaveTarget>(
      context: context,
      builder: (ctx) => _SavePresetDialog(presets: presets),
    );
    if (result == null) return;
    if (result.isNew) {
      final id = 'preset_${DateTime.now().millisecondsSinceEpoch}';
      await notifier.saveCurrentPosToPreset(id, result.label);
    } else {
      await notifier.saveCurrentPosToPreset(result.id!, result.label);
    }
  }
}

class _SaveTarget {
  final String? id;
  final String label;
  final bool isNew;
  const _SaveTarget.update(this.id, this.label) : isNew = false;
  const _SaveTarget.create(this.label) : id = null, isNew = true;
}

class _SavePresetDialog extends StatefulWidget {
  final List<ArmPreset> presets;
  const _SavePresetDialog({required this.presets});

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  late String _selectedId;
  bool _createNew = false;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.presets.isNotEmpty ? widget.presets.first.id : '';
    _labelCtrl = TextEditingController(
      text: widget.presets.isNotEmpty ? widget.presets.first.label : 'NEW',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String id) {
    final p = widget.presets.firstWhere((e) => e.id == id);
    setState(() {
      _createNew = false;
      _selectedId = id;
      _labelCtrl.text = p.label;
    });
  }

  void _selectNew() {
    setState(() {
      _createNew = true;
      _labelCtrl.text = 'NEW PRESET';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'SAVE CURRENT ANGLES',
        style: AppText.mono(
          fontSize: 14,
          color: AppColors.accent,
          weight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overwrite a preset',
            style: AppText.label(fontSize: 10, letterSpacing: 0.2),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...widget.presets.map((p) {
                final active = !_createNew && _selectedId == p.id;
                return GestureDetector(
                  onTap: () => _selectPreset(p.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withValues(alpha: 0.18)
                          : AppColors.surfaceDeep,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: active ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: AppText.mono(
                        fontSize: 11,
                        color: active
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: _selectNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _createNew
                        ? AppColors.accent.withValues(alpha: 0.18)
                        : AppColors.surfaceDeep,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _createNew
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 12,
                        color: _createNew
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NEW',
                        style: AppText.mono(
                          fontSize: 11,
                          color: _createNew
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Label',
            style: AppText.label(fontSize: 10, letterSpacing: 0.2),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _labelCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                filled: true,
                fillColor: AppColors.surfaceDeep,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: AppText.mono(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            final label = _labelCtrl.text.trim().isEmpty
                ? 'PRESET'
                : _labelCtrl.text.trim().toUpperCase();
            Navigator.of(context).pop(
              _createNew
                  ? _SaveTarget.create(label)
                  : _SaveTarget.update(_selectedId, label),
            );
          },
          child: Text(
            'SAVE',
            style: AppText.mono(
              fontSize: 11,
              color: AppColors.accent,
              weight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
