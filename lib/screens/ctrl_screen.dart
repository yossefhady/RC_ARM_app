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
                    builder: (_, notifier, __) =>
                        notifier.tab == 'drive'
                            ? const DriveTab()
                            : const ArmTab(),
                  ),
                  const TerminalWidget(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
