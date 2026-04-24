import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/ctrl_notifier.dart';
import 'screens/ctrl_screen.dart';
import 'services/mock_ble_service.dart';
// To use real BLE, swap MockBleService with RealBleService:
//   import 'services/real_ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CtrlApp());
}

class CtrlApp extends StatelessWidget {
  const CtrlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CtrlNotifier(MockBleService()),
      child: MaterialApp(
        title: 'CTRL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFBFCFD),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E9E5A),
            secondary: Color(0xFF24834A),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF262B36),
            error: Color(0xFFC4321A),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Color(0xFF2E9E5A),
            selectionColor: Color(0x222E9E5A),
          ),
        ),
        home: const CtrlScreen(),
      ),
    );
  }
}
