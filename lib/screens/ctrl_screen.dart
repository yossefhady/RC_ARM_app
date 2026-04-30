import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ctrl_notifier.dart';
import '../theme/app_colors.dart';
import '../widgets/header/ctrl_header.dart';
import '../widgets/tabs/ctrl_tab_bar.dart';
import '../widgets/drive/drive_tab.dart';
import '../widgets/arm/arm_tab.dart';
import '../widgets/terminal/terminal_widget.dart';

class CtrlScreen extends StatelessWidget {
  const CtrlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? const _LandscapeLayout() : const _PortraitLayout();
  }
}

// ─── Portrait ────────────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CtrlHeader(),
          const CtrlTabBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Consumer<CtrlNotifier>(
                    builder: (_, n, __) =>
                        n.tab == 'drive' ? const DriveTab() : const ArmTab(),
                  ),
                  const SizedBox(height: 8),
                  const TerminalWidget(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Landscape ───────────────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CtrlHeader(),
          const CtrlTabBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Controls pane (left, scrollable)
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Consumer<CtrlNotifier>(
                      builder: (_, n, __) =>
                          n.tab == 'drive' ? const DriveTab() : const ArmTab(),
                    ),
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                // Terminal pane (right, expanded)
                Expanded(
                  flex: 4,
                  child: Column(children: const [TerminalWidget(expand: true)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
