import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/models/arm_preset.dart';
import 'package:app/models/ble_scan_result.dart';
import 'package:app/providers/ctrl_notifier.dart';
import 'package:app/services/ble_service.dart';
import 'package:app/services/settings_service.dart';

class _RecordingBle implements BleService {
  final _conn = StreamController<bool>.broadcast();
  final _resp = StreamController<String>.broadcast();
  final _scan = StreamController<List<BleScanResult>>.broadcast();
  final List<String> sent = [];
  bool _connected = false;

  @override
  Stream<bool> get connectionStream => _conn.stream;
  @override
  Stream<String> get responseStream => _resp.stream;
  @override
  Stream<List<BleScanResult>> get scanStream => _scan.stream;
  @override
  bool get isConnected => _connected;

  void simulateConnected() {
    _connected = true;
    _conn.add(true);
  }

  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connectTo(BleScanResult device) async {
    simulateConnected();
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _conn.add(false);
  }

  @override
  Future<void> sendCommand(String command) async {
    sent.add(command);
  }

  @override
  void dispose() {
    _conn.close();
    _resp.close();
    _scan.close();
  }
}

void main() {
  late _RecordingBle ble;
  late CtrlNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ble = _RecordingBle();
    notifier = CtrlNotifier(ble, SettingsService(prefs));
    ble.simulateConnected();
    // Drain the connection-state microtask.
    await Future<void>.delayed(Duration.zero);
    ble.sent.clear();
  });

  tearDown(() => notifier.dispose());

  group('servo command debounce', () {
    test('setServo does not send immediately', () {
      notifier.setServo(0, 100);
      expect(ble.sent, isEmpty);
    });

    test('setServo sends once after debounce window', () async {
      notifier.setServo(0, 100);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(ble.sent, hasLength(1));
      expect(ble.sent.single.trim(), '1 100');
    });

    test('rapid setServo calls collapse to a single send with the last value',
        () async {
      notifier.setServo(0, 91);
      notifier.setServo(0, 92);
      notifier.setServo(0, 93);
      notifier.setServo(0, 95);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(ble.sent, hasLength(1));
      expect(ble.sent.single.trim(), '1 95');
    });

    test('endServo flushes immediately and cancels the pending debounce',
        () async {
      notifier.setServo(0, 91);
      notifier.endServo(0, 110);
      // Synchronously sent on endServo.
      expect(ble.sent, hasLength(1));
      expect(ble.sent.single.trim(), '1 110');
      // Previously scheduled debounce must not also fire.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(ble.sent, hasLength(1));
    });

    test('redundant equal value is not re-sent', () async {
      notifier.endServo(0, 100);
      notifier.endServo(0, 100);
      expect(ble.sent, hasLength(1));
    });

    test('different servos debounce independently', () async {
      notifier.setServo(0, 50);
      notifier.setServo(1, 60);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(ble.sent, hasLength(2));
      // Servo IDs map: index 0 → id 1, index 1 → id 2.
      expect(ble.sent.map((e) => e.trim()), containsAll(['1 50', '2 60']));
    });
  });

  group('applyPreset clamping', () {
    test('returns null when all values are within limits', () async {
      final preset = ArmPreset(
        id: 'home',
        label: 'HOME',
        values: [90, 90, 90, 90, 90],
      );
      final warning = notifier.applyPreset(preset);
      expect(warning, isNull);
    });

    test('clamps over-max value and returns warning', () async {
      await notifier.settings.setServoMax(1, 150);
      final preset = ArmPreset(
        id: 'grab',
        label: 'GRAB',
        values: [160, 90, 90, 90, 90],
      );
      final warning = notifier.applyPreset(preset);
      expect(notifier.servos[0].value, 150);
      expect(warning, contains('S1'));
      expect(warning, contains('160°'));
      expect(warning, contains('max 150'));
    });

    test('clamps under-min value and returns warning', () async {
      await notifier.settings.setServoMin(2, 30);
      final preset = ArmPreset(
        id: 'rest',
        label: 'REST',
        values: [90, 10, 90, 90, 90],
      );
      final warning = notifier.applyPreset(preset);
      expect(notifier.servos[1].value, 30);
      expect(warning, contains('S2'));
      expect(warning, contains('10°'));
      expect(warning, contains('min 30'));
    });

    test('sends clamped value to BLE, not raw preset value', () async {
      await notifier.settings.setServoMax(1, 150);
      final preset = ArmPreset(
        id: 'grab',
        label: 'GRAB',
        values: [160, 90, 90, 90, 90],
      );
      ble.sent.clear();
      notifier.applyPreset(preset);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(ble.sent.any((cmd) => cmd.trim() == '1 150'), isTrue);
      expect(ble.sent.any((cmd) => cmd.trim() == '1 160'), isFalse);
    });

    test('multiple clamped servos all appear in warning', () async {
      await notifier.settings.setServoMax(1, 100);
      await notifier.settings.setServoMin(2, 50);
      final preset = ArmPreset(
        id: 'custom',
        label: 'CUSTOM',
        values: [120, 20, 90, 90, 90],
      );
      final warning = notifier.applyPreset(preset);
      expect(warning, contains('S1'));
      expect(warning, contains('S2'));
    });
  });

  group('saveCurrentPosToPreset', () {
    test('saves new preset id when not in list', () async {
      notifier.setServo(0, 95);
      await notifier.saveCurrentPosToPreset('custom_1', 'CUSTOM');
      final presets = notifier.settings.loadedPresets;
      final created = presets.firstWhere((p) => p.id == 'custom_1');
      expect(created.label, 'CUSTOM');
      expect(created.values.first, 95);
    });

    test('updates existing preset by id', () async {
      notifier.setServo(0, 45);
      await notifier.saveCurrentPosToPreset('home', 'HOME');
      final home = notifier.settings.loadedPresets
          .firstWhere((p) => p.id == 'home');
      expect(home.values.first, 45);
    });
  });
}
