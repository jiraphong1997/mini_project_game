import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/services/class_progression_service.dart';
import 'package:mini_project_game/services/class_quest_service.dart';

void main() {
  test('Advanced class should require completed class quest', () {
    final hero = HeroModel(
      id: 'hero_1',
      name: 'Knight Seed',
      gender: 'ชาย',
      age: 21,
      backgroundStory: 'Test',
      level: 15,
      totalTowerFloorsCleared: 8,
      baseStats: HeroStats(
        maxHp: 420,
        currentHp: 420,
        atk: 42,
        def: 36,
        spd: 18,
        maxEng: 100,
        currentEng: 100,
        luk: 12,
      ),
      currentStats: HeroStats(
        maxHp: 420,
        currentHp: 420,
        atk: 42,
        def: 36,
        spd: 18,
        maxEng: 100,
        currentEng: 100,
        luk: 12,
      ),
      aptitudes: const {'Knight': 0.5, 'Farmer': 0.5},
      currentClass: 'vanguard',
      unlockedClasses: const ['novice', 'vanguard'],
      bond: 35,
    );

    expect(
      ClassProgressionService.meetsDirectRequirement(hero, 'knight'),
      isTrue,
    );
    expect(
      ClassProgressionService.canUnlockOrSwitch(hero, 'knight'),
      isFalse,
    );

    ClassQuestService.startQuest(hero, 'steel_resolve');
    ClassQuestService.completeQuest(hero, 'steel_resolve');

    expect(hero.completedClassQuestIds, contains('steel_resolve'));
    expect(
      ClassProgressionService.applyClassChange(hero, 'knight'),
      isTrue,
    );
    expect(hero.unlockedClasses, contains('knight'));
  });

  test('Special branch should allow override unlocks', () {
    final hero = HeroModel(
      id: 'hero_2',
      name: 'Late Bloomer',
      gender: 'หญิง',
      age: 19,
      backgroundStory: 'Test',
      level: 6,
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Farmer': 1.0},
      currentClass: 'acolyte',
      unlockedClasses: const ['novice', 'acolyte'],
    );

    expect(
      ClassProgressionService.canUnlockOrSwitch(hero, 'saint'),
      isFalse,
    );
    expect(
      ClassProgressionService.applyClassChange(
        hero,
        'saint',
        useOverride: true,
      ),
      isTrue,
    );
    expect(hero.currentClass, 'saint');
  });
}
