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
        Permission.locationWhenInUse, // Required for BLE scan on Android < 12
      ].request();
      final btScan = results[Permission.bluetoothScan]?.isGranted ?? false;
      final btConnect = results[Permission.bluetoothConnect]?.isGranted ?? false;
      final location = results[Permission.locationWhenInUse]?.isGranted ?? false;
      // Android 12+ needs BT perms; Android <12 needs location
      return (btScan && btConnect) || location;
    }
    // iOS: CoreBluetooth prompts automatically on first use.
    return true;
  }

  /// Resolves a human-readable name: advertisement name > platform name > short hex ID.
  String _resolveName(ScanResult r) {
    final adv = r.device.advName.trim();
    if (adv.isNotEmpty) return adv;
    final platform = r.device.platformName.trim();
    if (platform.isNotEmpty) return platform;
    final hex = r.device.remoteId.str.replaceAll(':', '').replaceAll('-', '');
    return 'BLE·${hex.substring((hex.length - 6).clamp(0, hex.length))}';
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
          name: _resolveName(r),
          rssi: r.rssi,
        );
      }
      // Named devices first, then sort by signal strength within each group.
      final sorted = seen.values.toList()
        ..sort((a, b) {
          final anamed = !a.name.startsWith('BLE·');
          final bnamed = !b.name.startsWith('BLE·');
          if (anamed != bnamed) return anamed ? -1 : 1;
          return b.rssi.compareTo(a.rssi);
        });
      _scanController.add(sorted);
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
