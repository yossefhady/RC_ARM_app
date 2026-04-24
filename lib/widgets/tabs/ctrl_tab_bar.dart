import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ctrl_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CtrlTabBar extends StatelessWidget {
  const CtrlTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CtrlNotifier>();
    final isDrive = notifier.tab == 'drive';
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _Tab(
                label: 'DRIVE',
                icon: Icons.directions_car_outlined,
                active: isDrive,
                onTap: () => notifier.setTab('drive'),
              ),
              _Tab(
                label: 'ARM',
                icon: Icons.precision_manufacturing_outlined,
                active: !isDrive,
                onTap: () => notifier.setTab('arm'),
              ),
            ],
          ),
          // Sliding accent underline
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 0,
            left: isDrive ? width * 0.1 : width * 0.6,
            child: Container(
              width: width * 0.3,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.accent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    blurRadius: 8,
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

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.label(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: active ? AppColors.textPrimary : AppColors.textMuted,
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
