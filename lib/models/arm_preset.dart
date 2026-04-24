class ArmPreset {
  final String id;
  final String label;
  final List<int> values;

  const ArmPreset({required this.id, required this.label, required this.values});
}

const armPresets = [
  ArmPreset(id: 'home', label: 'HOME', values: [90, 90, 90, 90, 90, 90]),
  ArmPreset(id: 'grab', label: 'GRAB', values: [90, 120, 45, 90, 60, 20]),
  ArmPreset(id: 'lift', label: 'LIFT', values: [90, 45, 135, 90, 90, 90]),
  ArmPreset(id: 'rest', label: 'REST', values: [0, 0, 180, 0, 0, 180]),
];
