import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
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
  });
}
