import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<CtrlNotifier>().settings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('SETTINGS', style: AppText.mono(fontSize: 16)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('DRIVE CONTROLS'),
          _TextFieldRow(
            label: 'UP Comm.',
            value: settings.cmdUp,
            onChanged: (v) => setState(() => settings.setCmdUp(v)),
          ),
          _TextFieldRow(
            label: 'DOWN Comm.',
            value: settings.cmdDown,
            onChanged: (v) => setState(() => settings.setCmdDown(v)),
          ),
          _TextFieldRow(
            label: 'LEFT Comm.',
            value: settings.cmdLeft,
            onChanged: (v) => setState(() => settings.setCmdLeft(v)),
          ),
          _TextFieldRow(
            label: 'RIGHT Comm.',
            value: settings.cmdRight,
            onChanged: (v) => setState(() => settings.setCmdRight(v)),
          ),
          _TextFieldRow(
            label: 'STOP Comm.',
            value: settings.cmdStop,
            onChanged: (v) => setState(() => settings.setCmdStop(v)),
          ),
          const SizedBox(height: 24),
          _SectionTitle('ARM PRESETS'),
          ...settings.loadedPresets.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TextFieldRow(
                          label: 'Name',
                          value: p.label,
                          onChanged: (v) {
                            final newPresets = settings.loadedPresets;
                            final idx = newPresets.indexWhere(
                              (e) => e.id == p.id,
                            );
                            if (idx != -1) {
                              newPresets[idx] = p.copyWith(label: v);
                              settings
                                  .savePresets(newPresets)
                                  .then((_) => setState(() {}));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Angles (0-5)', style: AppText.label(fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                          child: _NumberField(
                            value: p.values[i].toString(),
                            onChanged: (v) {
                              final val = int.tryParse(v) ?? p.values[i];
                              final newPresets = settings.loadedPresets;
                              final idx = newPresets.indexWhere(
                                (e) => e.id == p.id,
                              );
                              if (idx != -1) {
                                final newVals = List<int>.from(p.values);
                                newVals[i] = val;
                                newPresets[idx] = p.copyWith(values: newVals);
                                settings
                                    .savePresets(newPresets)
                                    .then((_) => setState(() {}));
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppText.mono(
          fontSize: 14,
          color: AppColors.accent,
          weight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _TextFieldRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _NumberField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.surfaceDeep,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
