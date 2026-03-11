class SkillModel {
  final String id;
  final String name;
  final String description;
  final String unlockCondition;
  
  int level; // เลเวล 1 - 10
  bool isUnlocked;
  
  double damageMultiplier;
  double healAmount;

  SkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCondition,
    this.level = 1,
    this.isUnlocked = false,
    this.damageMultiplier = 0.0,
    this.healAmount = 0.0,
  });
}
