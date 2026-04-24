abstract class BleService {
  Stream<bool> get connectionStream;
  Stream<String> get responseStream;
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendCommand(String command);
  void dispose();
}
