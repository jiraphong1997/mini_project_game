import 'hero_stats.dart';

enum ItemType { weapon, armor, consumable, material, warpItem }

enum EquipmentSlot { weapon, armor, relic }

class ItemModel {
  final String id;
  final String name;
  final ItemType type;
  final int rarity;
  final HeroStats? statBonus;
  final EquipmentSlot? equipmentSlot;
  int quantity;

  ItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    this.statBonus,
    this.equipmentSlot,
    this.quantity = 1,
  });

  String get rarityLabel => '$rarity ดาว';
  bool get isEquippable => equipmentSlot != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rarity': rarity,
      'statBonus': statBonus?.toMap(),
      'equipmentSlot': equipmentSlot?.name,
      'quantity': quantity,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? ItemType.material.name;
    final slotName = map['equipmentSlot'] as String?;
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
      equipmentSlot: slotName == null
          ? null
          : EquipmentSlot.values.firstWhere(
              (value) => value.name == slotName,
              orElse: () => EquipmentSlot.relic,
            ),
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}
