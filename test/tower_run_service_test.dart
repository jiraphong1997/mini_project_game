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
      name: 'อาร์เธอร์',
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
      name: 'พรีสต์',
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

  test('Tower recovery cooldown should vary per hero fatigue and stats', () {
    final tank = HeroModel(
      id: 'hero_3',
      name: 'แทงก์',
      gender: 'ชาย',
      age: 28,
      backgroundStory: 'Recovery tank',
      baseStats: HeroStats(
        maxHp: 260,
        currentHp: 260,
        atk: 55,
        def: 90,
        spd: 35,
        maxEng: 120,
        currentEng: 120,
        luk: 8,
      ),
      currentStats: HeroStats(
        maxHp: 260,
        currentHp: 220,
        atk: 55,
        def: 90,
        spd: 35,
        maxEng: 120,
        currentEng: 95,
        luk: 8,
      ),
      aptitudes: const {'Knight': 1.0},
    );
    final scout = HeroModel(
      id: 'hero_4',
      name: 'สเกาต์',
      gender: 'หญิง',
      age: 21,
      backgroundStory: 'Recovery scout',
      baseStats: HeroStats(
        maxHp: 160,
        currentHp: 160,
        atk: 72,
        def: 32,
        spd: 88,
        maxEng: 90,
        currentEng: 90,
        luk: 16,
      ),
      currentStats: HeroStats(
        maxHp: 160,
        currentHp: 70,
        atk: 72,
        def: 32,
        spd: 88,
        maxEng: 90,
        currentEng: 18,
        luk: 16,
      ),
      aptitudes: const {'Scout': 1.0},
      currentClass: 'shadowblade',
      unlockedClasses: const ['novice', 'skirmisher', 'shadowblade'],
    );

    final party = PartyModel(
      partyId: 'party_3',
      partyName: 'Recovery Party',
      members: [tank, scout],
    );

    final duration = TowerRunService.scheduleRecoveryCooldown(
      party,
      clearedFloors: 3,
    );

    expect(duration, greaterThan(Duration.zero));
    expect(tank.isRecovering, isTrue);
    expect(scout.isRecovering, isTrue);
    expect(
      scout.recoveryCooldownRemaining.inMinutes,
      greaterThan(tank.recoveryCooldownRemaining.inMinutes),
    );
  });

  test('Holy classes should improve shrine vow outcomes', () {
    final hero = HeroModel(
      id: 'hero_5',
      name: 'คลีริก',
      gender: 'หญิง',
      age: 20,
      backgroundStory: 'Holy guide',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Priest': 1.0},
      currentClass: 'acolyte',
      unlockedClasses: const ['novice', 'acolyte'],
      faith: 40,
    );
    hero.currentStats.currentHp = 55;
    hero.currentStats.currentEng = 40;

    final party = PartyModel(
      partyId: 'holy_party',
      partyName: 'Holy Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_4',
      playerName: 'Holy Tester',
      savedParties: [party],
      allHeroes: [hero],
    );
    const event = TowerDecisionEvent(
      id: 'shrine',
      title: 'ศาลโบราณ',
      description: '',
      options: [],
    );

    final advice = TowerRunService.buildAdvice(party: party, event: event);
    final outcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 5,
      event: event,
      optionId: 'vow',
    );

    expect(advice, contains('ถวายสัตย์'));
    expect(outcome.enemyModifierDelta, -45);
    expect(outcome.rewardModifierDelta, -40);
    expect(hero.faith, 54);
    expect(player.resolvedMajorEventFloors, contains(5));
  });

  test('Scout classes should soften survivor leave penalties', () {
    final hero = HeroModel(
      id: 'hero_6',
      name: 'เชด',
      gender: 'ชาย',
      age: 24,
      backgroundStory: 'Scout specialist',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Scout': 1.0},
      currentClass: 'shadowblade',
      unlockedClasses: const ['novice', 'skirmisher', 'shadowblade'],
      bond: 80,
      faith: 70,
    );

    final party = PartyModel(
      partyId: 'scout_party',
      partyName: 'Scout Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_5',
      playerName: 'Scout Tester',
      savedParties: [party],
      allHeroes: [hero],
    );
    const event = TowerDecisionEvent(
      id: 'survivor',
      title: 'ผู้รอดชีวิตคนสุดท้าย',
      description: '',
      options: [],
    );

    final outcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 10,
      event: event,
      optionId: 'leave',
    );

    expect(outcome.enemyModifierDelta, -55);
    expect(outcome.silverDelta, 50);
    expect(hero.bond, 76);
    expect(hero.faith, 67);
  });

  test('Major choices should queue and resolve chain events', () {
    final hero = HeroModel(
      id: 'hero_7',
      name: 'เส้นทาง',
      gender: 'ชาย',
      age: 26,
      backgroundStory: 'Event chain tester',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
    );
    final party = PartyModel(
      partyId: 'chain_party',
      partyName: 'Chain Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_6',
      playerName: 'Chain Tester',
      savedParties: [party],
      allHeroes: [hero],
    );
    const shrineEvent = TowerDecisionEvent(
      id: 'shrine',
      title: 'ศาลโบราณ',
      description: '',
      options: [],
    );

    TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 5,
      event: shrineEvent,
      optionId: 'vow',
    );

    expect(player.pendingMajorChainEventId, 'pilgrim_rest');

    final chainEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 10,
    );

    expect(chainEvent, isNotNull);
    expect(chainEvent!.id, 'pilgrim_rest');

    final outcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 10,
      event: chainEvent,
      optionId: 'accept_blessing',
    );

    expect(outcome.enemyModifierDelta, lessThan(0));
    expect(player.pendingMajorChainEventId, isNull);
    expect(player.resolvedMajorChainEventIds, contains('pilgrim_rest'));
  });

  test('Equipment should directly amplify shrine outcomes', () {
    final hero = HeroModel(
      id: 'hero_8',
      name: 'ผู้ถือรีลิก',
      gender: 'หญิง',
      age: 22,
      backgroundStory: 'Equipment tester',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Priest': 1.0},
      equippedItemIds: const {'relic': 'saints_emblem'},
    );
    final party = PartyModel(
      partyId: 'gear_party',
      partyName: 'Gear Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_7',
      playerName: 'Gear Tester',
      savedParties: [party],
      allHeroes: [hero],
    );
    const shrineEvent = TowerDecisionEvent(
      id: 'shrine',
      title: 'ศาลโบราณ',
      description: '',
      options: [],
    );

    final outcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 5,
      event: shrineEvent,
      optionId: 'vow',
    );

    expect(outcome.enemyModifierDelta, -55);
    expect(outcome.rewardModifierDelta, -30);
  });

  test('Compass chain should branch into market and vault routes', () {
    final hero = HeroModel(
      id: 'hero_9',
      name: 'Navigator',
      gender: 'ชาย',
      age: 23,
      backgroundStory: 'Market chain tester',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Scout': 1.0},
      equippedItemIds: const {'relic': 'wayfinder_compass'},
      currentClass: 'ranger',
      unlockedClasses: const ['novice', 'skirmisher', 'ranger'],
    );
    final party = PartyModel(
      partyId: 'market_party',
      partyName: 'Market Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_8',
      playerName: 'Market Tester',
      savedParties: [party],
      allHeroes: [hero],
    );
    const hiddenCamp = TowerDecisionEvent(
      id: 'hidden_camp',
      title: 'Hidden Camp',
      description: '',
      options: [],
    );

    TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 10,
      event: hiddenCamp,
      optionId: 'recruit_guides',
    );

    expect(player.pendingMajorChainEventIds, contains('secret_bazaar'));

    final bazaarEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 15,
    );
    expect(bazaarEvent?.id, 'secret_bazaar');

    final bazaarOutcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 15,
      event: bazaarEvent!,
      optionId: 'broker_goods',
    );

    expect(bazaarOutcome.silverDelta, greaterThan(0));
    expect(player.pendingMajorChainEventIds, contains('vault_market'));

    final vaultEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 20,
    );
    expect(vaultEvent?.id, 'vault_market');
  });

  test('Equipment effects should appear in floor battle logs', () {
    final hero = HeroModel(
      id: 'hero_10',
      name: 'Smith Guard',
      gender: 'ชาย',
      age: 27,
      backgroundStory: 'Equipment combat tester',
      level: 14,
      baseStats: HeroStats(
        maxHp: 540,
        currentHp: 540,
        atk: 110,
        def: 95,
        spd: 70,
        maxEng: 120,
        currentEng: 120,
        luk: 32,
      ),
      currentStats: HeroStats(
        maxHp: 540,
        currentHp: 540,
        atk: 110,
        def: 95,
        spd: 70,
        maxEng: 120,
        currentEng: 120,
        luk: 32,
      ),
      aptitudes: const {'Knight': 1.0},
      equippedItemIds: const {
        'weapon': 'steel_blade',
        'armor': 'tower_mail',
        'relic': 'forge_heart',
      },
    );
    final party = PartyModel(
      partyId: 'equipment_party',
      partyName: 'Equipment Party',
      members: [hero],
      formation: 'bulwark',
    );
    final player = PlayerData(
      playerId: 'player_9',
      playerName: 'Equipment Tester',
      savedParties: [party],
      allHeroes: [hero],
    );

    final outcome = TowerRunService.resolveFloor(
      playerData: player,
      party: party,
      floor: 6,
    );

    expect(
      outcome.logLines.any((line) => line.contains('อุปกรณ์') || line.contains('เธญเธธเธ')),
      isTrue,
    );
    expect(outcome.partyPower, greaterThan(0));
  });
}
