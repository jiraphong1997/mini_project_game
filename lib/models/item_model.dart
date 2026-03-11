import 'hero_stats.dart';

enum ItemType { weapon, armor, consumable, material, warpItem }

class ItemModel {
  final String id;
  final String name;
  final ItemType type;
  final int rarity; // 1-5
  final HeroStats? statBonus; // โบนัสที่จะบวกเพิ่ม
  int quantity; 

  ItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    this.statBonus,
    this.quantity = 1,
  });
}
