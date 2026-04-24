class DriveMode {
  final String id;
  final String label;
  final int speed;

  const DriveMode({required this.id, required this.label, required this.speed});
}

const driveModes = [
  DriveMode(id: 'forward', label: 'FORWARD ONLY', speed: 255),
  DriveMode(id: 'tank', label: 'TANK SPIN', speed: 150),
  DriveMode(id: 'crawl', label: 'CRAWL', speed: 60),
];
