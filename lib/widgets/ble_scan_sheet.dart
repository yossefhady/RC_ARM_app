import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ctrl_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BleScanSheet extends StatefulWidget {
  const BleScanSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final notifier = context.read<CtrlNotifier>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: notifier,
        child: const BleScanSheet(),
      ),
    );
  }

  @override
  State<BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends State<BleScanSheet> {
  CtrlNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier ??= context.read<CtrlNotifier>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CtrlNotifier>().startScan();
    });
  }

  @override
  void dispose() {
    _notifier?.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CtrlNotifier>();
    final results = notifier.scanResults;
    final scanning = notifier.isScanning;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header row
              Row(
                children: [
                  Icon(Icons.bluetooth_searching,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('SELECT DEVICE',
                      style: AppText.label(letterSpacing: 0.22)),
                  const Spacer(),
                  if (scanning) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('SCANNING…',
                        style: AppText.mono(
                            fontSize: 10, color: AppColors.accent)),
                  ] else
                    GestureDetector(
                      onTap: () => notifier.startScan(),
                      child: Text('RESCAN',
                          style: AppText.mono(
                              fontSize: 10, color: AppColors.accent)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),

              // Device list
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.bluetooth_disabled,
                            size: 32,
                            color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          scanning
                              ? 'Searching for nearby BLE devices…'
                              : 'No devices found. Tap RESCAN.',
                          style: AppText.mono(
                              fontSize: 11, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: AppColors.border, height: 1),
                    itemBuilder: (_, i) {
                      final dev = results[i];
                      final bars = _rssiBars(dev.rssi);
                      final isNamed = !dev.name.startsWith('BLE·');
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isNamed
                                ? AppColors.accentSoft
                                : AppColors.surfaceDeep,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.bluetooth,
                              color: isNamed
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              size: 20),
                        ),
                        title: Text(dev.name,
                            style: AppText.mono(
                                fontSize: 12,
                                weight: FontWeight.w600,
                                color: isNamed
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted)),
                        subtitle: Text(dev.deviceId,
                            style: AppText.mono(
                                fontSize: 9, color: AppColors.textMuted)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                4,
                                (b) => Container(
                                  width: 4,
                                  height: 6.0 + b * 3,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: b < bars
                                        ? AppColors.accent
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('${dev.rssi} dBm',
                                style: AppText.mono(
                                    fontSize: 8, color: AppColors.textMuted)),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<CtrlNotifier>().connectToDevice(dev);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map RSSI to 1–4 signal bars.
  int _rssiBars(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -65) return 3;
    if (rssi >= -75) return 2;
    return 1;
  }
}
