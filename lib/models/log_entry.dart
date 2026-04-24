enum LogType { out, inbound, info, err }

class LogEntry {
  final String ts;
  final LogType type;
  final String msg;

  const LogEntry({required this.ts, required this.type, required this.msg});
}
