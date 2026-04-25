import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_scan_result.dart';
import 'ble_service.dart';

// Nordic UART Service UUIDs — standard ESP32 BLE UART firmware.
const _serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const _txCharUuid  = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify (ESP32 → phone)
const _rxCharUuid  = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write  (phone → ESP32)

class RealBleService implements BleService {
  final _connController = StreamController<bool>.broadcast();
  final _respController = StreamController<String>.broadcast();
  final _scanController = StreamController<List<BleScanResult>>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  // Cache discovered devices so connectTo can look up BluetoothDevice by ID.
  final _scannedDevices = <String, BluetoothDevice>{};

  bool _connected = false;

  @override Stream<bool> get connectionStream => _connController.stream;
  @override Stream<String> get responseStream => _respController.stream;
  @override Stream<List<BleScanResult>> get scanStream => _scanController.stream;
  @override bool get isConnected => _connected;

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      return results.values.every((s) => s.isGranted || s.isLimited);
    }
    // iOS: CoreBluetooth prompts automatically on first use.
    return true;
  }

  @override
  Future<void> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) throw Exception('Bluetooth permissions denied');

    _scannedDevices.clear();
    final seen = <String, BleScanResult>{};

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;
        _scannedDevices[id] = r.device;
        seen[id] = BleScanResult(
          deviceId: id,
          name: r.device.platformName.isEmpty ? 'Unknown' : r.device.platformName,
          rssi: r.rssi,
        );
      }
      _scanController.add(seen.values.toList());
    });

    // Fire-and-forget: scan runs in background; stopScan() ends it early.
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 12)).ignore();
  }

  @override
  Future<void> stopScan() async {
    _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connectTo(BleScanResult device) async {
    final btDevice = _scannedDevices[device.deviceId]
        ?? BluetoothDevice.fromId(device.deviceId);

    _device = btDevice;
    await _device!.connect(autoConnect: false);

    _stateSub?.cancel();
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
            _notifySub?.cancel();
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
    await _rxChar!.write(utf8.encode('$command\n'), withoutResponse: true);
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _stateSub?.cancel();
    _scanSub?.cancel();
    _device?.disconnect();
    _connController.close();
    _respController.close();
    _scanController.close();
  }
}
