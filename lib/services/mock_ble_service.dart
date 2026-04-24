import 'dart:async';
import 'dart:math';
import 'ble_service.dart';

class MockBleService implements BleService {
  final _connController = StreamController<bool>.broadcast();
  final _respController = StreamController<String>.broadcast();
  final _rng = Random();
  bool _connected = false;

  @override
  Stream<bool> get connectionStream => _connController.stream;

  @override
  Stream<String> get responseStream => _respController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
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
    final delay = 80 + _rng.nextInt(80);
    await Future<void>.delayed(Duration(milliseconds: delay));
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
    if (lower.startsWith('err')) return 'ERROR · unknown command';
    return 'OK';
  }

  @override
  void dispose() {
    _connController.close();
    _respController.close();
  }
}
