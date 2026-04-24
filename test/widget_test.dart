import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/main.dart';
import 'package:app/providers/ctrl_notifier.dart';
import 'package:app/services/mock_ble_service.dart';
import 'package:app/widgets/tabs/ctrl_tab_bar.dart';

void main() {
  testWidgets('app renders CTRL title', (WidgetTester tester) async {
    await tester.pumpWidget(const CtrlApp());
    await tester.pump();
    expect(find.text('CTRL'), findsWidgets);
  });

  testWidgets('tab bar switches between DRIVE and ARM', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CtrlNotifier(MockBleService()),
        child: const MaterialApp(home: Scaffold(body: CtrlTabBar())),
      ),
    );
    await tester.pump();
    expect(find.text('DRIVE'), findsOneWidget);
    expect(find.text('ARM'), findsOneWidget);
  });

  testWidgets('tapping ARM tab changes active tab', (WidgetTester tester) async {
    final notifier = CtrlNotifier(MockBleService());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: const MaterialApp(home: Scaffold(body: CtrlTabBar())),
      ),
    );
    await tester.pump();
    expect(notifier.tab, 'drive');
    await tester.tap(find.text('ARM'));
    await tester.pump();
    expect(notifier.tab, 'arm');
    notifier.dispose();
  });
}
