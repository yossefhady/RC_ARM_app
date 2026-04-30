import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/ctrl_notifier.dart';
import 'screens/ctrl_screen.dart';
import 'services/real_ble_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(CtrlApp(settings: settings));
}

class CtrlApp extends StatelessWidget {
  final SettingsService settings;
  const CtrlApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CtrlNotifier(RealBleService(), settings),
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
