import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/item_model.dart';
import 'package:mini_project_game/models/player_data.dart';
import 'package:mini_project_game/services/item_usage_service.dart';

void main() {
  HeroModel buildHero() {
    return HeroModel(
      id: 'hero_1',
      name: 'Item Target',
      gender: 'ชาย',
      age: 20,
      backgroundStory: 'Test',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
    );
  }

  test('Using hero consumable should modify hero and consume item', () {
    final hero = buildHero();
    final player = PlayerData(
      playerId: 'player_1',
      playerName: 'Tester',
      inventory: [
        ItemUsageService.definitionFor('battle_tonic')!.toItemModel(),
      ],
    );

    final result = ItemUsageService.useItem(player, hero, 'battle_tonic');

    expect(result.success, isTrue);
    expect(hero.currentStats.atk, greaterThan(HeroStats.initial().atk));
    expect(hero.totalItemsUsed, 1);
    expect(player.itemQuantity('battle_tonic'), 0);
  });

  test('Equipping weapon should move inventory into hero equipment', () {
    final hero = buildHero();
    final player = PlayerData(
      playerId: 'player_2',
      playerName: 'Tester',
      inventory: [
        ItemUsageService.definitionFor('steel_blade')!.toItemModel(),
      ],
    );

    final result = ItemUsageService.equipItem(player, hero, 'steel_blade');

    expect(result.success, isTrue);
    expect(hero.equippedItemIdForSlot(EquipmentSlot.weapon), 'steel_blade');
    expect(player.itemQuantity('steel_blade'), 0);
  });

  test('Selling item should grant currency and reduce inventory', () {
    final player = PlayerData(
      playerId: 'player_3',
      playerName: 'Seller',
      inventory: [
        ItemUsageService.definitionFor('tower_ore_3')!.toItemModel(quantity: 2),
      ],
    );

    final result = ItemUsageService.sellItem(
      player,
      'tower_ore_3',
      quantity: 2,
    );

    expect(result.success, isTrue);
    expect(result.silverEarned, 120);
    expect(result.goldEarned, 2);
    expect(player.itemQuantity('tower_ore_3'), 0);
    expect(player.silver, 120);
    expect(player.gold, 2);
  });

  test('Crafting should consume materials and add crafted output', () {
    final player = PlayerData(
      playerId: 'player_4',
      playerName: 'Crafter',
      silver: 100,
      inventory: [
        ItemUsageService.definitionFor('beast_meat')!.toItemModel(quantity: 2),
        ItemUsageService.definitionFor('cloth_scrap')!.toItemModel(quantity: 1),
      ],
    );

    final result = ItemUsageService.craftItem(player, 'cook_ration');

    expect(result.success, isTrue);
    expect(player.itemQuantity('beast_meat'), 0);
    expect(player.itemQuantity('cloth_scrap'), 0);
    expect(player.itemQuantity('ration_pack'), 1);
    expect(player.silver, 90);
  });
}
