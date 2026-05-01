import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_scan_result.dart';
import 'ble_service.dart';

class RealBleService implements BleService {
  final _connController = StreamController<bool>.broadcast();
  final _respController = StreamController<String>.broadcast();
  final _scanController = StreamController<List<BleScanResult>>.broadcast();

  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _scanSub;

  final _scannedDevices = <String, BluetoothDevice>{};
  bool _connected = false;

  @override
  Stream<bool> get connectionStream => _connController.stream;
  @override
  Stream<String> get responseStream => _respController.stream;
  @override
  Stream<List<BleScanResult>> get scanStream => _scanController.stream;
  @override
  bool get isConnected => _connected;

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      final btScan = results[Permission.bluetoothScan]?.isGranted ?? false;
      final btConnect =
          results[Permission.bluetoothConnect]?.isGranted ?? false;
      final location =
          results[Permission.locationWhenInUse]?.isGranted ?? false;
      return (btScan && btConnect) || location;
    }
    return true;
  }

  @override
  Future<void> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) throw Exception('Bluetooth permissions denied');

    _scannedDevices.clear();
    final seen = <String, BleScanResult>{};

    _scanSub?.cancel();

    // First, let's get already bonded (paired) devices so they show up easily
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (final d in bonded) {
        _scannedDevices[d.address] = d;
        seen[d.address] = BleScanResult(
          deviceId: d.address,
          name: d.name ?? 'Unknown Device',
          rssi: -50, // Fake RSSI for bonded devices
        );
      }
      _scanController.add(seen.values.toList());
    } catch (e) {
      // Error handled silently
    }

    _scanSub = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      final d = r.device;
      _scannedDevices[d.address] = d;
      seen[d.address] = BleScanResult(
        deviceId: d.address,
        name: d.name ?? 'Unknown Device',
        rssi: r.rssi,
      );

      final sorted = seen.values.toList()
        ..sort((a, b) {
          final anamed = a.name != 'Unknown Device';
          final bnamed = b.name != 'Unknown Device';
          if (anamed != bnamed) return anamed ? -1 : 1;
          return b.rssi.compareTo(a.rssi);
        });
      _scanController.add(sorted);
    });
  }

  @override
  Future<void> stopScan() async {
    _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  @override
  Future<void> connectTo(BleScanResult device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.deviceId);
      _connected = true;
      _connController.add(true);

      _connection!.input!
          .listen((Uint8List data) {
            final msg = utf8.decode(data).trim();
            if (msg.isNotEmpty) _respController.add(msg);
          })
          .onDone(() {
            _connected = false;
            _connController.add(false);
          });
    } catch (e) {
      _connected = false;
      _connController.add(false);
      // Connection failed, controller notified
    }
  }

  @override
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _connected = false;
    _connController.add(false);
  }

  @override
  Future<void> sendCommand(String command) async {
    if (_connection == null || !_connected) return;
    try {
      _connection!.output.add(
        utf8.encode(command),
      ); // Ensure newline isn't strictly required if ino looks for pure char
      // But ino looks for exact char match: char cmd = (char)SerialBT.read();
      // It handles 'F', 'B' etc. The .ino loop reads chars sequentially.
      await _connection!.output.allSent;
    } catch (e) {
      // Send failed, error ignored
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connection?.close();
    _connController.close();
    _respController.close();
    _scanController.close();
  }
}
