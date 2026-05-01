import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/arm_preset.dart';
import '../models/ble_scan_result.dart';
import '../models/drive_mode.dart';
import '../models/log_entry.dart';
import '../models/servo_model.dart';
import '../services/ble_service.dart';
import '../services/settings_service.dart';

const _servoDefs = [
  (id: 1, name: 'BASE ROT'),
  (id: 2, name: 'SHOULDER'),
  (id: 4, name: 'ELBOW'),
  (id: 5, name: 'WRIST ROLL'),
  (id: 6, name: 'GRIPPER'),
];

class CtrlNotifier extends ChangeNotifier {
  final BleService _ble;
  final SettingsService settings;

  CtrlNotifier(this._ble, this.settings) {
    _init();
  }

  // ── Connection ──────────────────────────────────────────────────────────────
  bool _connected = false;

  // ── Scan ────────────────────────────────────────────────────────────────────
  List<BleScanResult> _scanResults = [];
  bool _isScanning = false;
  Timer? _scanTimer;

  // ── UI state ────────────────────────────────────────────────────────────────
  String _tab = 'drive';
  String _driveCtrlMode = 'dpad'; // 'dpad' | 'joystick'
  int _speed = 180;
  String _mode = 'forward';
  String? _preset = 'home';
  List<ServoModel> _servos = _servoDefs
      .map(
        (s) => ServoModel(id: s.id, name: s.name, value: s.id == 6 ? 75 : 90),
      )
      .toList();
  List<LogEntry> _logs = [];

  // ── Subscriptions ────────────────────────────────────────────────────────────
  StreamSubscription<bool>? _connSub;
  StreamSubscription<String>? _respSub;
  StreamSubscription<List<BleScanResult>>? _scanSub;
  Timer? _speedDebounce;
  String? _lastJoyCmd;

  // Per-servo debounce so a fast slider drag does not flood the BLE link.
  // Why: each servo command stalls the firmware briefly; spamming makes the
  // arm jitter/panic. We send at most one command per ~80ms while sliding,
  // then a final command on release.
  static const Duration _servoDebounceDelay = Duration(milliseconds: 80);
  final Map<int, Timer> _servoDebounce = {};
  final Map<int, int> _lastSentServoValue = {};

  // ── Getters ──────────────────────────────────────────────────────────────────
  bool get connected => _connected;
  List<BleScanResult> get scanResults => List.unmodifiable(_scanResults);
  bool get isScanning => _isScanning;
  String get tab => _tab;
  String get driveCtrlMode => _driveCtrlMode;
  int get speed => _speed;
  String get mode => _mode;
  String? get preset => _preset;
  List<ServoModel> get servos => List.unmodifiable(_servos);
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void _init() {
    _connSub = _ble.connectionStream.listen((c) {
      _connected = c;
      if (!c) _addLog(LogType.info, 'Bluetooth link lost');
      notifyListeners();
    });
    _respSub = _ble.responseStream.listen((msg) {
      _addLog(LogType.inbound, msg);
    });
    _addLog(LogType.info, 'CTRL ready · tap scan button');
  }

  // ── BLE Scan (Now Classic BT) ───────────────────────────────────────────────

  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _scanResults = [];
    notifyListeners();

    _scanSub?.cancel();
    _scanSub = _ble.scanStream.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    try {
      await _ble.startScan();
      _addLog(LogType.info, 'Scanning for Bluetooth devices…');
    } catch (e) {
      _addLog(LogType.err, 'Scan error: $e');
      _isScanning = false;
      notifyListeners();
      return;
    }

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 12), stopScan);
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    notifyListeners();
    await _ble.stopScan();
  }

  Future<void> connectToDevice(BleScanResult device) async {
    await stopScan();
    _addLog(LogType.info, 'Connecting to ${device.name}…');
    try {
      await _ble.connectTo(device);
      _addLog(LogType.info, 'BT link up · ${device.name}');
    } catch (e) {
      _addLog(LogType.err, 'Connection failed: $e');
    }
  }

  void disconnectDevice() {
    _addLog(LogType.info, 'Disconnecting…');
    _ble.disconnect();
  }

  // ── Drive ────────────────────────────────────────────────────────────────────

  void setTab(String t) {
    _tab = t;
    notifyListeners();
  }

  void setDriveCtrlMode(String m) {
    _driveCtrlMode = m;
    notifyListeners();
  }

  void onDirectionPress(String dir) {
    final cmdMap = {
      'up': settings.cmdUp,
      'down': settings.cmdDown,
      'left': settings.cmdLeft,
      'right': settings.cmdRight,
    };
    _send(cmdMap[dir]!);
  }

  void onDirectionRelease() => _send(settings.cmdStop);

  void onStop() => _send(settings.cmdStop);

  void onJoystickMove(double x, double y) {
    final mag = sqrt(x * x + y * y).clamp(0.0, 1.0);
    final cmd = _joystickCmd(x, y, mag);
    if (cmd == _lastJoyCmd) return;
    _lastJoyCmd = cmd;
    _send(cmd);
  }

  void onJoystickRelease() {
    if (_lastJoyCmd == null || _lastJoyCmd == settings.cmdStop) return;
    _lastJoyCmd = null;
    _send(settings.cmdStop);
  }

  String _joystickCmd(double x, double y, double mag) {
    if (mag < 0.15) return settings.cmdStop;
    if (y.abs() >= x.abs()) {
      return y > 0 ? settings.cmdUp : settings.cmdDown;
    }
    return x > 0 ? settings.cmdRight : settings.cmdLeft;
  }

  void setSpeed(int v) {
    _speed = v;
    notifyListeners();
    // For this simple classic bluetooth test we won't spam the pwm command right now.
  }

  void setMode(DriveMode m) {
    _mode = m.id;
    _speed = m.speed;
    notifyListeners();
  }

  // ── Arm ──────────────────────────────────────────────────────────────────────

  void setServo(int idx, int value) {
    final next = [..._servos];
    next[idx] = next[idx].copyWith(value: value);
    _servos = next;
    _preset = null;
    notifyListeners();
    _scheduleServoSend(idx, value);
  }

  void endServo(int idx, int value) {
    final next = [..._servos];
    next[idx] = next[idx].copyWith(value: value);
    _servos = next;
    _preset = null;
    notifyListeners();
    _flushServoSend(idx, value);
  }

  void _scheduleServoSend(int idx, int value) {
    _servoDebounce[idx]?.cancel();
    _servoDebounce[idx] = Timer(_servoDebounceDelay, () {
      _flushServoSend(idx, value);
    });
  }

  void _flushServoSend(int idx, int value) {
    _servoDebounce[idx]?.cancel();
    _servoDebounce.remove(idx);
    if (_lastSentServoValue[idx] == value) return;
    _lastSentServoValue[idx] = value;
    _send('${_servos[idx].id} $value\n');
  }

  Future<void> saveCurrentPosToPreset(String presetId, String newLabel) async {
    final values = _servos.map((s) => s.value).toList();
    final newPreset = ArmPreset(id: presetId, label: newLabel, values: values);
    
    final existing = List<ArmPreset>.from(settings.loadedPresets);
    final idx = existing.indexWhere((p) => p.id == presetId);
    if (idx != -1) {
      existing[idx] = newPreset;
    } else {
      existing.add(newPreset);
    }
    await settings.savePresets(existing);
    _preset = presetId;
    notifyListeners();
  }

  void applyPreset(ArmPreset p) {
    _preset = p.id;
    _servos = [
      for (var i = 0; i < _servos.length; i++)
        _servos[i].copyWith(
          value: i < p.values.length ? p.values[i] : _servos[i].value,
        ),
    ];
    notifyListeners();
    for (var i = 0; i < _servos.length; i++) {
      // Small delay between servo commands to prevent serial buffer overflow
      Timer(Duration(milliseconds: i * 50), () {
        _send('${_servos[i].id} ${_servos[i].value}\n');
      });
    }
  }

  // ── Terminal ─────────────────────────────────────────────────────────────────

  void sendRawCommand(String cmd) {
    if (!cmd.endsWith('\n')) {
      cmd += '\n';
    }
    _send(cmd);
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  void _addLog(LogType type, String msg) {
    final next = [..._logs, LogEntry(ts: _ts(), type: type, msg: msg)];
    _logs = next.length > 42 ? next.sublist(next.length - 42) : next;
    notifyListeners();
  }

  void _send(String cmd) {
    if (!_connected) return;
    _addLog(LogType.out, cmd);
    _ble.sendCommand(cmd);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _respSub?.cancel();
    _scanSub?.cancel();
    _scanTimer?.cancel();
    _speedDebounce?.cancel();
    for (final t in _servoDebounce.values) {
      t.cancel();
    }
    _servoDebounce.clear();
    _ble.dispose();
    super.dispose();
  }
}
