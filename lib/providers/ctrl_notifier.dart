import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/arm_preset.dart';
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

  bool _connected = false;
  String _tab = 'drive';
  int _speed = 180;
  String _mode = 'forward';
  String? _preset = 'home';
  List<ServoModel> _servos = _servoDefs
      .map((s) => ServoModel(id: s.id, name: s.name, value: 90))
      .toList();
  List<LogEntry> _logs = [];

  StreamSubscription<bool>? _connSub;
  StreamSubscription<String>? _respSub;
  Timer? _speedDebounce;

  bool get connected => _connected;
  String get tab => _tab;
  int get speed => _speed;
  String get mode => _mode;
  String? get preset => _preset;
  List<ServoModel> get servos => List.unmodifiable(_servos);
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void _init() {
    _connSub = _ble.connectionStream.listen((c) {
      _connected = c;
      notifyListeners();
    });
    _respSub = _ble.responseStream.listen((msg) {
      _addLog(LogType.inbound, msg);
    });

    _ble.connect().then((_) {
      _addLog(LogType.info, 'BLE link established · ESP32-WROOM-32');
    }).catchError((_) {
      _addLog(LogType.err, 'BLE connection failed');
    });

    _addLog(LogType.out, 'SET_PWM 180');
    _addLog(LogType.out, 'ARM_HOME');
    _addLog(LogType.inbound, 'OK · servos aligned 90°');
  }

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

  void setTab(String t) {
    _tab = t;
    notifyListeners();
  }

  void toggleConnection() {
    if (_connected) {
      _addLog(LogType.info, 'BLE disconnecting…');
      _ble.disconnect();
    } else {
      _addLog(LogType.info, 'BLE reconnecting…');
      _ble.connect().catchError((_) {
        _addLog(LogType.err, 'BLE connection failed');
      });
    }
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

  void setSpeed(int v) {
    _speed = v;
    notifyListeners();
    _speedDebounce?.cancel();
    _speedDebounce = Timer(const Duration(milliseconds: 300), () {
      _send('SET_PWM $_speed');
    });
  }

  void setMode(DriveMode m) {
    _mode = m.id;
    _speed = m.speed;
    notifyListeners();
    _send('MODE ${m.id.toUpperCase()} · pwm=${m.speed}');
  }

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
        _servos[i].copyWith(value: i < p.values.length ? p.values[i] : _servos[i].value),
    ];
    notifyListeners();
    _send('PRESET ${p.label}');
  }

  void sendRawCommand(String cmd) => _send(cmd);

  @override
  void dispose() {
    _connSub?.cancel();
    _respSub?.cancel();
    _speedDebounce?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
