import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/arm_preset.dart';
import '../models/ble_scan_result.dart';
import '../models/drive_mode.dart';
import '../models/log_entry.dart';
import '../models/servo_model.dart';
import '../services/ble_service.dart';

const _servoDefs = [
  (id: 1, name: 'BASE ROT'),
  (id: 2, name: 'SHOULDER'),
  (id: 3, name: 'ELBOW'),
  (id: 4, name: 'WRIST PITCH'),
  (id: 5, name: 'WRIST ROT'),
  (id: 6, name: 'GRIPPER'),
];

class CtrlNotifier extends ChangeNotifier {
  CtrlNotifier(this._ble) {
    _init();
  }

  final BleService _ble;

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
      .map((s) => ServoModel(id: s.id, name: s.name, value: 90))
      .toList();
  List<LogEntry> _logs = [];

  // ── Subscriptions ────────────────────────────────────────────────────────────
  StreamSubscription<bool>? _connSub;
  StreamSubscription<String>? _respSub;
  StreamSubscription<List<BleScanResult>>? _scanSub;
  Timer? _speedDebounce;
  String? _lastJoyCmd;

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
      if (!c) _addLog(LogType.info, 'BLE link lost');
      notifyListeners();
    });
    _respSub = _ble.responseStream.listen((msg) {
      _addLog(LogType.inbound, msg);
    });
    _addLog(LogType.info, 'CTRL ready · tap BLE button to scan');
  }

  // ── BLE Scan ─────────────────────────────────────────────────────────────────

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
      _addLog(LogType.info, 'Scanning for BLE devices…');
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
      _addLog(LogType.info, 'BLE link up · ${device.name}');
      _send('SET_PWM $_speed');
      _send('ARM_HOME');
    } catch (e) {
      _addLog(LogType.err, 'Connection failed: $e');
    }
  }

  void disconnectDevice() {
    _addLog(LogType.info, 'BLE disconnecting…');
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
    const cmdMap = {
      'up': 'DRIVE_FWD',
      'down': 'DRIVE_REV',
      'left': 'TURN_L',
      'right': 'TURN_R',
    };
    _send('${cmdMap[dir]!} pwm=$_speed');
  }

  void onDirectionRelease() => _send('DRIVE_STOP');

  void onStop() => _send('DRIVE_STOP');

  void onJoystickMove(double x, double y) {
    final mag = sqrt(x * x + y * y).clamp(0.0, 1.0);
    final cmd = _joystickCmd(x, y, mag);
    if (cmd == _lastJoyCmd) return;
    _lastJoyCmd = cmd;
    _addLog(LogType.out, cmd);
    _ble.sendCommand(cmd);
  }

  void onJoystickRelease() {
    if (_lastJoyCmd == null || _lastJoyCmd == 'DRIVE_STOP') return;
    _lastJoyCmd = null;
    _send('DRIVE_STOP');
  }

  String _joystickCmd(double x, double y, double mag) {
    if (mag < 0.15) return 'DRIVE_STOP';
    // Quantise pwm to 16-unit steps to reduce command spam.
    final pwm = ((mag * _speed / 16).round() * 16).clamp(0, 255);
    if (y.abs() >= x.abs()) {
      return y > 0 ? 'DRIVE_FWD pwm=$pwm' : 'DRIVE_REV pwm=$pwm';
    }
    return x > 0 ? 'TURN_R pwm=$pwm' : 'TURN_L pwm=$pwm';
  }

  void setSpeed(int v) {
    _speed = v;
    notifyListeners();
    _speedDebounce?.cancel();
    _speedDebounce =
        Timer(const Duration(milliseconds: 300), () => _send('SET_PWM $_speed'));
  }

  void setMode(DriveMode m) {
    _mode = m.id;
    _speed = m.speed;
    notifyListeners();
    _send('MODE ${m.id.toUpperCase()} · pwm=${m.speed}');
  }

  // ── Arm ──────────────────────────────────────────────────────────────────────

  void setServo(int idx, int value) {
    final next = [..._servos];
    next[idx] = next[idx].copyWith(value: value);
    _servos = next;
    _preset = null;
    notifyListeners();
    _send('S${idx + 1} → ${value.toString().padLeft(3, '0')}°');
  }

  void applyPreset(ArmPreset p) {
    _preset = p.id;
    _servos = [
      for (var i = 0; i < _servos.length; i++)
        _servos[i].copyWith(
            value: i < p.values.length ? p.values[i] : _servos[i].value),
    ];
    notifyListeners();
    _send('PRESET ${p.label}');
  }

  // ── Terminal ─────────────────────────────────────────────────────────────────

  void sendRawCommand(String cmd) => _send(cmd);

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
    _ble.dispose();
    super.dispose();
  }
}
