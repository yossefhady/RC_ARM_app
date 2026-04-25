import '../models/ble_scan_result.dart';

abstract class BleService {
  Stream<bool> get connectionStream;
  Stream<String> get responseStream;
  Stream<List<BleScanResult>> get scanStream;
  bool get isConnected;

  /// Request permissions (if needed) then start BLE scan.
  /// Results arrive via [scanStream]. Returns quickly; call [stopScan] to end.
  Future<void> startScan();
  Future<void> stopScan();

  /// Connect to a device that appeared in [scanStream].
  Future<void> connectTo(BleScanResult device);

  Future<void> disconnect();
  Future<void> sendCommand(String command);
  void dispose();
}
