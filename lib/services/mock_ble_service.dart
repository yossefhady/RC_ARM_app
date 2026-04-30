import 'dart:async';
import 'dart:math';
import '../models/ble_scan_result.dart';
import 'ble_service.dart';

const _fakeDevices = [
  BleScanResult(deviceId: 'AA:BB:CC:DD:EE:01', name: 'ESP32-CTRL', rssi: -42),
  BleScanResult(deviceId: 'AA:BB:CC:DD:EE:02', name: 'ESP32-ARM-01', rssi: -61),
  BleScanResult(deviceId: 'FF:FF:FF:FF:FF:00', name: 'Galaxy Buds', rssi: -78),
];

class MockBleService implements BleService {
  final _connController = StreamController<bool>.broadcast();
  final _respController = StreamController<String>.broadcast();
  final _scanController = StreamController<List<BleScanResult>>.broadcast();
  final _rng = Random();
  bool _connected = false;
  final List<BleScanResult> _discovered = [];

  @override
  Stream<bool> get connectionStream => _connController.stream;
  @override
  Stream<String> get responseStream => _respController.stream;
  @override
  Stream<List<BleScanResult>> get scanStream => _scanController.stream;
  @override
  bool get isConnected => _connected;

  @override
  Future<void> startScan() async {
    // Returns immediately; devices appear via scanStream asynchronously.
    _discovered.clear();
    _emitDevicesAsync();
  }

  void _emitDevicesAsync() async {
    for (final dev in _fakeDevices) {
      await Future<void>.delayed(
        Duration(milliseconds: 500 + _rng.nextInt(700)),
      );
      if (_scanController.isClosed) return;
      _discovered.add(dev);
      _scanController.add(List.unmodifiable(_discovered));
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connectTo(BleScanResult device) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _connected = true;
    _connController.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _respController.add('ACK handshake · firmware v2.4.1');
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connController.add(false);
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!_connected) return;
    await Future<void>.delayed(Duration(milliseconds: 80 + _rng.nextInt(80)));
    _respController.add(_respond(command));
  }

  String _respond(String cmd) {
    final lower = cmd.toLowerCase();
    if (lower.startsWith('drive_stop')) return 'OK · halted';
    if (lower.startsWith('drive_fwd')) return 'OK · drive_fwd';
    if (lower.startsWith('drive_rev')) return 'OK · drive_rev';
    if (lower.startsWith('turn_l')) return 'OK · turn_l';
    if (lower.startsWith('turn_r')) return 'OK · turn_r';
    if (lower.startsWith('set_pwm')) return 'OK · pwm set';
    if (lower.startsWith('mode')) return 'OK · mode updated';
    if (lower.startsWith('preset')) {
      final label = cmd.length > 7 ? cmd.substring(7).toLowerCase() : '';
      return 'OK · moving to $label';
    }
    if (lower.startsWith('arm_home')) return 'OK · servos aligned 90°';
    return 'OK';
  }

  @override
  void dispose() {
    _connController.close();
    _respController.close();
    _scanController.close();
  }
}
