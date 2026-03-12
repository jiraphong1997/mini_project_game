import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/services/class_progression_service.dart';

void main() {
  test('Class progression should respect direct requirements', () {
    final hero = HeroModel(
      id: 'hero_1',
      name: 'Knight Seed',
      gender: 'ชาย',
      age: 21,
      backgroundStory: 'Test',
      level: 15,
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
    );

    expect(
      ClassProgressionService.meetsDirectRequirement(hero, 'knight'),
      isTrue,
    );
    expect(
      ClassProgressionService.applyClassChange(hero, 'knight'),
      isTrue,
    );
    expect(hero.unlockedClasses, contains('knight'));
  });

  test('Class progression should allow override unlocks', () {
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
    );

    expect(
      ClassProgressionService.canUnlockOrSwitch(hero, 'oracle'),
      isFalse,
    );
    expect(
      ClassProgressionService.applyClassChange(
        hero,
        'oracle',
        useOverride: true,
      ),
      isTrue,
    );
    expect(hero.currentClass, 'oracle');
  });
}
