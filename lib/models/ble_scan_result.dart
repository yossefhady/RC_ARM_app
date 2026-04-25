class BleScanResult {
  final String deviceId;
  final String name;
  final int rssi;

  const BleScanResult({
    required this.deviceId,
    required this.name,
    required this.rssi,
  });
}
