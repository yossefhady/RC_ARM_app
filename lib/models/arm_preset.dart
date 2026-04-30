class ArmPreset {
  final String id;
  final String label;
  final List<int> values;

  const ArmPreset({
    required this.id,
    required this.label,
    required this.values,
  });

  factory ArmPreset.fromJson(Map<String, dynamic> json) {
    return ArmPreset(
      id: json['id'] as String,
      label: json['label'] as String,
      values: List<int>.from(json['values'] as List),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'values': values};

  ArmPreset copyWith({String? id, String? label, List<int>? values}) {
    return ArmPreset(
      id: id ?? this.id,
      label: label ?? this.label,
      values: values ?? this.values,
    );
  }
}

// We will keep this default array for fallback
const armPresetsDefaults = [
  ArmPreset(id: 'home', label: 'HOME', values: [90, 90, 90, 90, 90]),
  ArmPreset(id: 'grab', label: 'GRAB', values: [90, 120, 90, 60, 40]),
  ArmPreset(id: 'lift', label: 'LIFT', values: [90, 45, 90, 90, 90]),
  ArmPreset(id: 'rest', label: 'REST', values: [0, 0, 0, 0, 180]),
];
