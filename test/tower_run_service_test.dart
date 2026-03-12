import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/party_model.dart';
import 'package:mini_project_game/models/player_data.dart';
import 'package:mini_project_game/services/tower_run_service.dart';

void main() {
  test('TowerRunService should grant progression rewards on successful run', () {
    final hero = HeroModel(
      id: 'hero_1',
      name: 'Arthur',
      gender: 'ชาย',
      age: 22,
      backgroundStory: 'Test hero',
      level: 10,
      baseStats: HeroStats(
        maxHp: 500,
        currentHp: 500,
        atk: 120,
        def: 100,
        spd: 80,
        maxEng: 100,
        currentEng: 100,
        luk: 30,
      ),
      currentStats: HeroStats(
        maxHp: 500,
        currentHp: 500,
        atk: 120,
        def: 100,
        spd: 80,
        maxEng: 100,
        currentEng: 100,
        luk: 30,
      ),
      aptitudes: const {'Knight': 1.0},
    );

    final party = PartyModel(
      partyId: 'main',
      partyName: 'Main Expedition',
      members: [hero],
      formation: 'assault',
    );

    final player = PlayerData(
      playerId: 'player_1',
      playerName: 'Tester',
      savedParties: [party],
      allHeroes: [hero],
    );

    final result = TowerRunService.run(
      playerData: player,
      party: party,
      maxFloorsPerRun: 1,
    );

    expect(result.clearedFloors, greaterThanOrEqualTo(0));
    expect(result.expPerHero, greaterThanOrEqualTo(0));
    expect(player.lastTowerSummary, isNotNull);

    if (result.clearedFloors > 0) {
      expect(player.inventory, isNotEmpty);
      expect(player.silver, greaterThan(0));
    }
  });

  test('Advice charges should scale with party bond and faith', () {
    final trustedHero = HeroModel(
      id: 'hero_2',
      name: 'Priest',
      gender: 'หญิง',
      age: 19,
      backgroundStory: 'Trusted hero',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Priest': 1.0},
      bond: 90,
      faith: 92,
    );

    final party = PartyModel(
      partyId: 'trusted',
      partyName: 'Trusted Party',
      members: [trustedHero],
    );
    final player = PlayerData(
      playerId: 'player_2',
      playerName: 'Trusted Player',
      savedParties: [party],
      allHeroes: [trustedHero],
    );

    expect(TowerRunService.adviceChargesForParty(party), greaterThanOrEqualTo(3));
    expect(
      TowerRunService.maybeCreateMajorEvent(playerData: player, floor: 5),
      isNotNull,
    );
    expect(
      TowerRunService.maybeCreateMajorEvent(playerData: player, floor: 4),
      isNull,
    );
  });

  test('Tower recovery helpers should support cooldown and quick recover', () {
    final hero = HeroModel(
      id: 'hero_3',
      name: 'Runner',
      gender: 'ชาย',
      age: 23,
      backgroundStory: 'Test hero',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Scout': 1.0},
    );
    hero.currentStats.currentHp = 40;
    hero.currentStats.currentEng = 30;

    final party = PartyModel(
      partyId: 'party_3',
      partyName: 'Recovery Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_3',
      playerName: 'Recovery Tester',
      silver: 999,
      savedParties: [party],
      allHeroes: [hero],
    );

    final duration = TowerRunService.scheduleRecoveryCooldown(
      party,
      clearedFloors: 3,
    );

    expect(duration, greaterThan(Duration.zero));
    expect(hero.isRecovering, isTrue);
    expect(TowerRunService.quickRecoverWithSilver(player, party), isTrue);
    expect(hero.isRecovering, isFalse);
    expect(hero.currentStats.currentHp, hero.currentStats.maxHp);
    expect(player.silver, lessThan(999));
  });
}
