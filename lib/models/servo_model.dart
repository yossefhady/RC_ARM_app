class ServoModel {
  final int id;
  final String name;
  final int value;

  const ServoModel({required this.id, required this.name, required this.value});

  ServoModel copyWith({int? value}) =>
      ServoModel(id: id, name: name, value: value ?? this.value);
}
