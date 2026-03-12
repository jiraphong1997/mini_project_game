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

  String get rarityLabel => '$rarity ดาว';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rarity': rarity,
      'statBonus': statBonus?.toMap(),
      'quantity': quantity,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? ItemType.material.name;
    return ItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ItemType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => ItemType.material,
      ),
      rarity: map['rarity'] as int? ?? 1,
      statBonus: map['statBonus'] == null
          ? null
          : HeroStats.fromMap(Map<String, dynamic>.from(map['statBonus'] as Map)),
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}
