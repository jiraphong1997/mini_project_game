class SkillModel {
  final String id;
  final String name;
  final String description;
  final String unlockCondition;
  final List<String> classIds;
  final int unlockLevel;
  final int manaCost;
  final int cooldownTurns;
  final int powerRating;
  final String role;

  const SkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.classIds,
    required this.unlockLevel,
    required this.manaCost,
    required this.cooldownTurns,
    required this.powerRating,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unlockCondition': unlockCondition,
      'classIds': classIds,
      'unlockLevel': unlockLevel,
      'manaCost': manaCost,
      'cooldownTurns': cooldownTurns,
      'powerRating': powerRating,
      'role': role,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      unlockCondition: map['unlockCondition'] as String,
      classIds: (map['classIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      unlockLevel: map['unlockLevel'] as int? ?? 1,
      manaCost: map['manaCost'] as int? ?? 0,
      cooldownTurns: map['cooldownTurns'] as int? ?? 0,
      powerRating: map['powerRating'] as int? ?? 0,
      role: map['role'] as String? ?? 'utility',
    );
  }
}
