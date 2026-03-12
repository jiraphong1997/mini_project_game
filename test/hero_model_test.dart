import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/item_model.dart';
import 'package:mini_project_game/services/class_progression_service.dart';

void main() {
  test('HeroModel gainExp should level up and improve stats', () {
    final hero = HeroModel(
      id: 'hero_1',
      name: 'Leveler',
      gender: 'ชาย',
      age: 18,
      backgroundStory: 'Test',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
    );

    final originalHp = hero.currentStats.maxHp;
    final originalAtk = hero.currentStats.atk;

    final gained = hero.gainExp(500);

    expect(gained, greaterThan(0));
    expect(hero.level, greaterThan(1));
    expect(hero.currentStats.maxHp, greaterThan(originalHp));
    expect(hero.currentStats.atk, greaterThan(originalAtk));
    expect(hero.totalExpEarned, 500);
    expect(hero.experienceStage, isNotEmpty);
  });

  test('HeroModel should track recovery cooldown and class change bonuses', () {
    final hero = HeroModel(
      id: 'hero_2',
      name: 'Recoverer',
      gender: 'ชาย',
      age: 20,
      backgroundStory: 'Test',
      level: 12,
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
      unlockedClasses: const ['novice', 'vanguard'],
      currentClass: 'vanguard',
    );

    final originalAtk = hero.currentStats.atk;
    hero.startRecoveryCooldown(const Duration(minutes: 5));

    expect(hero.isRecovering, isTrue);

    final changed = ClassProgressionService.applyClassChange(
      hero,
      'vanguard',
      useOverride: true,
    );
    expect(changed, isTrue);
    expect(hero.currentClass, 'vanguard');
    expect(hero.currentStats.atk, greaterThan(originalAtk));
    hero.startClassQuest('steel_resolve');
    hero.completeClassQuest('steel_resolve');
    expect(hero.completedClassQuestIds, contains('steel_resolve'));
  });

  test('HeroModel should apply and remove equipment bonuses by slot', () {
    final hero = HeroModel(
      id: 'hero_3',
      name: 'Equipper',
      gender: 'ชาย',
      age: 20,
      backgroundStory: 'Test',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
    );
    final sword = ItemModel(
      id: 'steel_blade',
      name: 'Steel Blade',
      type: ItemType.weapon,
      rarity: 2,
      equipmentSlot: EquipmentSlot.weapon,
      statBonus: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 8,
        def: 0,
        spd: 0,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
    );

    hero.equipItem(sword);
    expect(hero.equippedItemIdForSlot(EquipmentSlot.weapon), 'steel_blade');
    expect(hero.currentStats.atk, HeroStats.initial().atk + 8);

    hero.unequipSlot(EquipmentSlot.weapon);
    expect(hero.equippedItemIdForSlot(EquipmentSlot.weapon), isNull);
    expect(hero.currentStats.atk, HeroStats.initial().atk);
  });
}
