import 'hero_stats.dart';
import 'item_model.dart';
import 'skill_model.dart';

class HeroModel {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String backgroundStory;
  final int rarity; // 1 - 5

  int level;
  int currentExp;

  HeroStats baseStats;
  HeroStats currentStats;

  // ค่าความถนัดในบทบาทต่างๆรวมกันไม่เกิน 1.0 (100%)
  Map<String, double> aptitudes;
  
  List<SkillModel> skills;
  List<ItemModel> equipments;

  bool isAlive;
  bool isInTower;

  HeroModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.backgroundStory,
    required this.rarity,
    this.level = 1,
    this.currentExp = 0,
    required this.baseStats,
    required this.currentStats,
    required this.aptitudes,
    this.skills = const [],
    this.equipments = const [],
    this.isAlive = true,
    this.isInTower = false,
  });

  // คืนค่าสายอาชีพที่ความถนัดมากที่สุด
  String get currentJobRole {
    if (aptitudes.isEmpty) return 'Novice';
    return aptitudes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
