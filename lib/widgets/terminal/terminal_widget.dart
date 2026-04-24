import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/log_entry.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TerminalWidget extends StatefulWidget {
  const TerminalWidget({super.key});

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  late final AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submit() {
    final cmd = _inputCtrl.text.trim();
    if (cmd.isEmpty) return;
    context.read<CtrlNotifier>().sendRawCommand(cmd);
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<CtrlNotifier>().logs;
    _scrollToBottom();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TerminalHeader(logCount: logs.length),
          _LogBody(
            logs: logs,
            scrollCtrl: _scrollCtrl,
            blinkCtrl: _blinkCtrl,
          ),
          _InputRow(
            ctrl: _inputCtrl,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _TerminalHeader extends StatelessWidget {
  final int logCount;
  const _TerminalHeader({required this.logCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0A00E5A0), Colors.transparent],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // macOS-style traffic-light dots
          Row(
            children: [
              _Dot(color: AppColors.error),
              const SizedBox(width: 4),
              _Dot(color: AppColors.textMuted),
              const SizedBox(width: 4),
              _Dot(color: AppColors.accent),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            'esp32 · /dev/ble0',
            style: AppText.mono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 0.15,
            ),
          ),
          const Spacer(),
          Text(
            '$logCount EVT',
            style: AppText.mono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Log Body ─────────────────────────────────────────────────────────────────

class _LogBody extends StatelessWidget {
  final List<LogEntry> logs;
  final ScrollController scrollCtrl;
  final AnimationController blinkCtrl;

  const _LogBody({
    required this.logs,
    required this.scrollCtrl,
    required this.blinkCtrl,
  });

  static Color _color(LogType t) => switch (t) {
        LogType.out => AppColors.accent,
        LogType.inbound => AppColors.info,
        LogType.info => AppColors.textMuted,
        LogType.err => AppColors.error,
      };

  static String _prefix(LogType t) => switch (t) {
        LogType.out => '→',
        LogType.inbound => '←',
        LogType.info => '·',
        LogType.err => '!',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: logs.length + 1, // +1 for blinking cursor row
        itemBuilder: (_, i) {
          if (i == logs.length) {
            // Blinking cursor
            return Align(
              alignment: Alignment.centerLeft,
              child: FadeTransition(
                opacity: blinkCtrl,
                child: Container(
                  width: 7,
                  height: 11,
                  color: AppColors.accent,
                ),
              ),
            );
          }
          final log = logs[i];
          final color = _color(log.type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.ts,
                  style: AppText.mono(
                    fontSize: 9,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  child: Text(
                    _prefix(log.type),
                    textAlign: TextAlign.center,
                    style: AppText.mono(fontSize: 11, color: color),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    log.msg,
                    style: AppText.mono(fontSize: 11, color: color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Input Row ────────────────────────────────────────────────────────────────

class _InputRow extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit;

  const _InputRow({required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '\$',
              style: AppText.mono(
                fontSize: 12,
                weight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onSubmitted: (_) => onSubmit(),
              style: AppText.mono(fontSize: 11),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'send command…',
                hintStyle: AppText.mono(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) => GestureDetector(
              onTap: onSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: ctrl.text.trim().isNotEmpty
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
