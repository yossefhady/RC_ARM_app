import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';

// Nordic UART Service UUIDs — matches standard ESP32 BLE UART firmware.
// Change these if your ESP32 uses a custom service.
const _serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const _txCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify (ESP32 → phone)
const _rxCharUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write  (phone → ESP32)

class RealBleService implements BleService {
  final _connController = StreamController<bool>.broadcast();
  final _respController = StreamController<String>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  bool _connected = false;

  @override
  Stream<bool> get connectionStream => _connController.stream;

  @override
  Stream<String> get responseStream => _respController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    // Scan for the first device advertising the Nordic UART service.
    final completer = Completer<ScanResult>();
    final sub = FlutterBluePlus.scanResults.listen((results) {
      if (!completer.isCompleted && results.isNotEmpty) {
        completer.complete(results.first);
      }
    });
    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: const Duration(seconds: 10),
    );
    final result = await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException('No ESP32 found'),
    );
    await FlutterBluePlus.stopScan();
    sub.cancel();

    _device = result.device;
    await _device!.connect(autoConnect: false);

    _stateSub = _device!.connectionState.listen((state) {
      final connected = state == BluetoothConnectionState.connected;
      _connected = connected;
      _connController.add(connected);
    });

    final services = await _device!.discoverServices();
    for (final svc in services) {
      if (svc.uuid == Guid(_serviceUuid)) {
        for (final char in svc.characteristics) {
          if (char.uuid == Guid(_rxCharUuid)) _rxChar = char;
          if (char.uuid == Guid(_txCharUuid)) {
            await char.setNotifyValue(true);
            _notifySub = char.onValueReceived.listen((bytes) {
              final msg = utf8.decode(bytes).trim();
              if (msg.isNotEmpty) _respController.add(msg);
            });
          }
        }
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _device?.disconnect();
    _connected = false;
    _connController.add(false);
  }

  @override
  Future<void> sendCommand(String command) async {
    if (_rxChar == null || !_connected) return;
    final bytes = utf8.encode('$command\n');
    await _rxChar!.write(bytes, withoutResponse: true);
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _stateSub?.cancel();
    _device?.disconnect();
    _connController.close();
    _respController.close();
  }
}
