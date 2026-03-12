import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/item_model.dart';
import 'package:mini_project_game/models/party_model.dart';
import 'package:mini_project_game/models/player_data.dart';

void main() {
  test('PlayerData should serialize and deserialize heroes and parties', () {
    final hero = HeroModel(
      id: 'hero_1',
      name: 'Arthur',
      gender: 'ชาย',
      age: 20,
      backgroundStory: 'Test hero',
      level: 12,
      currentExp: 340,
      totalExpEarned: 1240,
      totalTowerFloorsCleared: 9,
      totalItemsUsed: 2,
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
      bond: 55,
      faith: 61,
      currentClass: 'vanguard',
      unlockedClasses: const ['novice', 'vanguard'],
      activeClassQuestIds: const ['steel_resolve'],
      completedClassQuestIds: const ['warpath'],
      equippedItemIds: const {'weapon': 'steel_blade'},
      equippedItemBonuses: const {},
      recoveryReadyAtEpochMs: 123456789,
    );

    final party = PartyModel(
      partyId: 'party_1',
      partyName: 'Main Expedition',
      members: [hero],
      status: 'ready',
    );

    final player = PlayerData(
      playerId: 'player_1',
      playerName: 'Tester',
      silver: 1000,
      gold: 200,
      baseBuildingLevel: 2,
      highestTowerFloor: 7,
      pendingMajorChainEventId: 'pilgrim_rest',
      pendingMajorChainEventIds: const ['pilgrim_rest', 'secret_bazaar'],
      resolvedMajorChainEventIds: const ['hidden_camp'],
      lastTowerSummary: 'ชนะชั้น 7',
      savedParties: [party],
      allHeroes: [hero],
      inventory: [
        ItemModel(
          id: 'tower_ore_1',
          name: 'Tower Ore',
          type: ItemType.material,
          rarity: 1,
          quantity: 3,
        ),
        ItemModel(
          id: 'tower_mail',
          name: 'Tower Mail',
          type: ItemType.armor,
          rarity: 2,
          equipmentSlot: EquipmentSlot.armor,
          quantity: 1,
        ),
      ],
    );

    final restored = PlayerData.fromMap(player.toMap());

    expect(restored.playerName, 'Tester');
    expect(restored.highestTowerFloor, 7);
    expect(restored.lastTowerSummary, 'ชนะชั้น 7');
    expect(restored.allHeroes, hasLength(1));
    expect(restored.savedParties, hasLength(1));
    expect(restored.inventory, hasLength(2));
    expect(restored.savedParties.first.members.first.id, 'hero_1');
    expect(restored.allHeroes.first.bond, 55);
    expect(restored.allHeroes.first.faith, 61);
    expect(restored.allHeroes.first.totalExpEarned, 1240);
    expect(restored.allHeroes.first.totalTowerFloorsCleared, 9);
    expect(restored.allHeroes.first.totalItemsUsed, 2);
    expect(restored.allHeroes.first.currentClass, 'vanguard');
    expect(restored.allHeroes.first.unlockedClasses, contains('vanguard'));
    expect(restored.allHeroes.first.activeClassQuestIds, contains('steel_resolve'));
    expect(restored.allHeroes.first.completedClassQuestIds, contains('warpath'));
    expect(restored.allHeroes.first.equippedItemIds['weapon'], 'steel_blade');
    expect(restored.allHeroes.first.recoveryReadyAtEpochMs, 123456789);
    expect(restored.pendingMajorChainEventId, 'pilgrim_rest');
    expect(restored.pendingMajorChainEventIds, ['pilgrim_rest', 'secret_bazaar']);
    expect(restored.resolvedMajorChainEventIds, contains('hidden_camp'));
    expect(restored.inventory.last.equipmentSlot, EquipmentSlot.armor);
  });

  test('PlayerData should consume stackable items', () {
    final player = PlayerData(
      playerId: 'player_2',
      playerName: 'Tester',
      inventory: [
        ItemModel(
          id: 'ration_pack',
          name: 'Field Ration',
          type: ItemType.consumable,
          rarity: 1,
          quantity: 2,
        ),
      ],
    );

    expect(player.itemQuantity('ration_pack'), 2);
    expect(player.consumeItem('ration_pack'), isTrue);
    expect(player.itemQuantity('ration_pack'), 1);
  });
}
