import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ble_scan_sheet.dart';

class CtrlHeader extends StatefulWidget {
  const CtrlHeader({super.key});

  @override
  State<CtrlHeader> createState() => _CtrlHeaderState();
}

class _CtrlHeaderState extends State<CtrlHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _tick = 0;
  Timer? _timer;
  static const _battery = 78;
  static const _rssi = -54;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _timer =
        Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timer?.cancel();
    super.dispose();
  }

  List<double> _bars(bool connected) {
    if (!connected) return List.filled(24, 0.15);
    return List.generate(24, (i) {
      final v = sin(_tick * 0.3 + i * 0.4) * 0.3 + 0.6;
      return (v + (i % 5 == 0 ? 0.15 : 0.0)).clamp(0.15, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CtrlNotifier>();
    final connected = notifier.connected;
    final bars = _bars(connected);
    final latency = connected ? 18 + (_tick % 7) : 999;
    final top = MediaQuery.of(context).padding.top;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + (isLandscape ? 6 : 12), 16,
          isLandscape ? 6 : 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── top row ──────────────────────────────────────────────────
          Row(
            children: [
              _Logo(),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Techno Genius',
                    style: AppText.label(
                      fontSize: 14,
                      weight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'CTRL · RC Ops',
                        style: AppText.mono(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusDot(connected: connected, pulse: _pulse),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _BlePill(
                connected: connected,
                onTap: () {
                  if (connected) {
                    notifier.disconnectDevice();
                  } else {
                    BleScanSheet.show(context);
                  }
                },
              ),
            ],
          ),

          // ── signal + telemetry row (portrait only) ───────────────────
          if (!isLandscape) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 22,
              child: Row(
                children: [
                  Expanded(
                      child: _SignalBars(bars: bars, connected: connected)),
                  const SizedBox(width: 12),
                  _Telemetry(
                    label: 'LAT',
                    value: connected
                        ? '${latency.toString().padLeft(2, '0')}ms'
                        : '---',
                    accent: connected,
                  ),
                  const SizedBox(width: 10),
                  _Telemetry(
                    label: 'RSSI',
                    value: connected ? '$_rssi' : '---',
                    accent: connected,
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Icon(
                        _battery > 20
                            ? Icons.battery_5_bar
                            : Icons.battery_alert,
                        size: 14,
                        color: _battery > 20 ? AppColors.accent : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$_battery%',
                        style: AppText.mono(
                          fontSize: 11,
                          color: _battery > 20
                              ? AppColors.accent
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── sub-widgets ──────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          'RC_ARM/assets/technogenius-logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'TG',
              style: AppText.mono(
                fontSize: 13,
                weight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool connected;
  final AnimationController pulse;

  const _StatusDot({required this.connected, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final opacity = connected ? 0.5 + pulse.value * 0.5 : 1.0;
        final color = connected ? AppColors.accent : AppColors.textMuted;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: connected
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _BlePill extends StatelessWidget {
  final bool connected;
  final VoidCallback onTap;

  const _BlePill({required this.connected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.accent : AppColors.textMuted;
    final bg = connected ? AppColors.accentSoft : AppColors.surfaceDeep;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: connected ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              connected ? 'CONNECTED' : 'CONNECT',
              style: AppText.mono(
                fontSize: 10,
                weight: FontWeight.w600,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final List<double> bars;
  final bool connected;

  const _SignalBars({required this.bars, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((b) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            height: (b * 22).clamp(3.0, 22.0),
            decoration: BoxDecoration(
              color: connected
                  ? AppColors.accent.withValues(alpha: 0.25 + b * 0.55)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Telemetry extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _Telemetry(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppText.label(fontSize: 8, letterSpacing: 0.2)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.mono(
            fontSize: 11,
            weight: FontWeight.w500,
            color: accent ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
