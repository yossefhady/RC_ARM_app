import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/services/settings_service.dart';

void main() {
  group('SettingsService servo limits', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults: max 180, min 0', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = SettingsService(prefs);
      expect(s.getServoMax(4), 180);
      expect(s.getServoMin(4), 0);
    });

    test('per-servo keys are isolated (S4 max=150 must not affect S2)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final s = SettingsService(prefs);

      await s.setServoMax(4, 150);

      expect(s.getServoMax(4), 150);
      expect(s.getServoMax(2), 180);
      expect(s.getServoMax(5), 180);
    });

    test('per-servo min keys are isolated', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = SettingsService(prefs);

      await s.setServoMin(2, 30);

      expect(s.getServoMin(2), 30);
      expect(s.getServoMin(4), 0);
    });
  });
}
