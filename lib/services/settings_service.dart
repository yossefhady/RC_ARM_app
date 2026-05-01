import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arm_preset.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Drive commands
  String get cmdUp => _prefs.getString('cmdUp') ?? 'F';
  Future<void> setCmdUp(String v) => _prefs.setString('cmdUp', v);

  String get cmdDown => _prefs.getString('cmdDown') ?? 'B';
  Future<void> setCmdDown(String v) => _prefs.setString('cmdDown', v);

  String get cmdLeft => _prefs.getString('cmdLeft') ?? 'L';
  Future<void> setCmdLeft(String v) => _prefs.setString('cmdLeft', v);

  String get cmdRight => _prefs.getString('cmdRight') ?? 'R';
  Future<void> setCmdRight(String v) => _prefs.setString('cmdRight', v);

  String get cmdStop => _prefs.getString('cmdStop') ?? 'S';
  Future<void> setCmdStop(String v) => _prefs.setString('cmdStop', v);

  // Presets
  List<ArmPreset> get loadedPresets {
    final str = _prefs.getString('armPresets');
    if (str != null) {
      try {
        final List list = jsonDecode(str);
        return list.map((e) => ArmPreset.fromJson(e)).toList();
      } catch (_) {}
    }
    // Default
    return [
      ArmPreset(id: 'home', label: 'HOME', values: [90, 90, 90, 90, 90]),
      ArmPreset(id: 'grab', label: 'GRAB', values: [90, 120, 90, 60, 40]),
      ArmPreset(id: 'lift', label: 'LIFT', values: [90, 45, 90, 90, 90]),
      ArmPreset(id: 'rest', label: 'REST', values: [0, 0, 0, 0, 180]),
    ];
  }

  Future<void> savePresets(List<ArmPreset> presets) async {
    final list = presets.map((e) => e.toJson()).toList();
    await _prefs.setString('armPresets', jsonEncode(list));
  }

  // Servo settings limits or names
  int getServoMax(int id) => _prefs.getInt('servoMax_$id') ?? 180;
  int getServoMin(int id) => _prefs.getInt('servoMin_$id') ?? 0;

  Future<void> setServoMax(int id, int val) =>
      _prefs.setInt('servoMax_$id', val);
  Future<void> setServoMin(int id, int val) =>
      _prefs.setInt('servoMin_$id', val);
}
