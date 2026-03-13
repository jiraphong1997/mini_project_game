import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/item_model.dart';
import 'package:mini_project_game/models/party_model.dart';
import 'package:mini_project_game/models/player_data.dart';
import 'package:mini_project_game/services/item_usage_service.dart';
import 'package:mini_project_game/services/tower_run_service.dart';

void main() {
  test(
    'TowerRunService should grant progression rewards on successful run',
    () {
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
    },
  );

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

    expect(
      TowerRunService.adviceChargesForParty(party),
      greaterThanOrEqualTo(3),
    );
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

  test('Market chain events should generate purchasable offers', () {
    final hero = HeroModel(
      id: 'hero_9b',
      name: 'Merchant Scout',
      gender: 'ชาย',
      age: 23,
      backgroundStory: 'Event inventory tester',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Scout': 1.0},
      equippedItemIds: const {'relic': 'wayfinder_compass'},
      currentClass: 'ranger',
      unlockedClasses: const ['novice', 'skirmisher', 'ranger'],
    );
    final party = PartyModel(
      partyId: 'market_party_2',
      partyName: 'Market Party 2',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_8b',
      playerName: 'Market Buyer',
      silver: 4000,
      gold: 8,
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

    final bazaarEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 15,
    );
    final buyOption = bazaarEvent!.options.firstWhere(
      (option) => option.id.startsWith('market_buy:'),
    );

    final outcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 15,
      event: bazaarEvent,
      optionId: buyOption.id,
    );

    expect(outcome.immediateItems, isNotEmpty);
    expect(outcome.silverDelta, lessThan(0));
    expect(player.pendingMajorChainEventIds, contains('vault_market'));
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
      outcome.logLines.any(
        (line) => line.contains('อุปกรณ์') || line.contains('เธญเธธเธ'),
      ),
      isTrue,
    );
    expect(
      outcome.logLines.any((line) => line.contains('ศัตรูประจำชั้น:')),
      isTrue,
    );
    expect(outcome.partyPower, greaterThan(0));
  });

  test('Event market stock should deplete within the same run', () {
    final hero = HeroModel(
      id: 'hero_stock',
      name: 'Stock Tester',
      gender: 'เธเธฒเธข',
      age: 24,
      backgroundStory: 'Stock test hero',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Scout': 1.0},
    );
    final party = PartyModel(
      partyId: 'stock_party',
      partyName: 'Stock Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_stock',
      playerName: 'Stock Player',
      silver: 10000,
      gold: 10,
      currentTowerRunId: 1,
      pendingMajorChainEventId: 'secret_bazaar',
      pendingMajorChainEventIds: const ['secret_bazaar'],
      savedParties: [party],
      allHeroes: [hero],
    );

    final event = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 15,
      party: party,
    )!;
    final buyOption = event.options.firstWhere(
      (option) => option.id.startsWith('market_buy:'),
    );
    final itemId = buyOption.id.split(':')[1];
    final stockKey = '1:secret_bazaar:$itemId';
    final stock = player.eventStockFor(stockKey);

    expect(stock, greaterThan(0));

    for (var i = 0; i < stock; i++) {
      final outcome = TowerRunService.applyDecision(
        playerData: player,
        party: party,
        floor: 15,
        event: event,
        optionId: buyOption.id,
      );
      expect(outcome.silverDelta, lessThan(0));
    }

    expect(player.eventStockFor(stockKey), 0);

    final soldOut = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 15,
      event: event,
      optionId: buyOption.id,
    );

    expect(soldOut.immediateItems, isEmpty);
    expect(soldOut.logLines.single, contains('หมดสต็อก'));
  });

  test('Blacksmith upgrade and reroll should change equipped bonuses', () {
    final hero = HeroModel(
      id: 'hero_smith',
      name: 'Smith Tester',
      gender: 'เธเธฒเธข',
      age: 26,
      backgroundStory: 'Smith test hero',
      baseStats: HeroStats.initial(),
      currentStats: HeroStats.initial(),
      aptitudes: const {'Knight': 1.0},
    );
    hero.equipItem(
      ItemUsageService.definitionFor('steel_blade')!.toItemModel(),
    );

    final party = PartyModel(
      partyId: 'smith_party',
      partyName: 'Smith Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_smith',
      playerName: 'Smith Player',
      silver: 10000,
      currentTowerRunId: 2,
      pendingMajorChainEventId: 'living_forge',
      pendingMajorChainEventIds: const ['living_forge'],
      savedParties: [party],
      allHeroes: [hero],
    );

    final forgeEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: player,
      floor: 15,
      party: party,
    )!;
    final upgradeOption = forgeEvent.options.firstWhere(
      (option) => option.id.startsWith('smith_upgrade:${hero.id}:weapon:'),
    );
    final baseAtk = hero.equippedItemBonuses['weapon']!.atk;

    final upgradeOutcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 15,
      event: forgeEvent,
      optionId: upgradeOption.id,
    );

    expect(upgradeOutcome.silverDelta, lessThan(0));
    expect(hero.equipmentUpgradeLevelForSlot(EquipmentSlot.weapon), 1);
    expect(hero.equippedItemBonuses['weapon']!.atk, greaterThan(baseAtk));

    final upgradedBonus = hero.equippedItemBonuses['weapon']!.clone();
    const smithEvent = TowerDecisionEvent(
      id: 'living_forge',
      title: 'Living Forge',
      description: '',
      options: [],
    );
    final rerollOutcome = TowerRunService.applyDecision(
      playerData: player,
      party: party,
      floor: 15,
      event: smithEvent,
      optionId: 'smith_reroll:${hero.id}:weapon:250:0',
    );
    final rerolledBonus = hero.equippedItemBonuses['weapon']!;

    expect(rerollOutcome.silverDelta, lessThan(0));
    expect(player.eventRerollCountFor('2:living_forge:reroll'), 1);
    expect(
      rerolledBonus.atk != upgradedBonus.atk ||
          rerolledBonus.spd != upgradedBonus.spd ||
          rerolledBonus.luk != upgradedBonus.luk,
      isTrue,
    );
  });

  test('Elite floors should log monster passive and elite modifier', () {
    final hero = HeroModel(
      id: 'hero_elite',
      name: 'Elite Tester',
      gender: 'เธเธฒเธข',
      age: 29,
      backgroundStory: 'Elite floor tester',
      level: 20,
      baseStats: HeroStats(
        maxHp: 900,
        currentHp: 900,
        atk: 180,
        def: 140,
        spd: 110,
        maxEng: 180,
        currentEng: 180,
        luk: 60,
      ),
      currentStats: HeroStats(
        maxHp: 900,
        currentHp: 900,
        atk: 180,
        def: 140,
        spd: 110,
        maxEng: 180,
        currentEng: 180,
        luk: 60,
      ),
      aptitudes: const {'Knight': 1.0},
      currentClass: 'warbringer',
      unlockedClasses: const ['novice', 'vanguard', 'warbringer'],
    );
    final party = PartyModel(
      partyId: 'elite_party',
      partyName: 'Elite Party',
      members: [hero],
      formation: 'assault',
    );
    final player = PlayerData(
      playerId: 'player_elite',
      playerName: 'Elite Player',
      currentTowerRunId: 4,
      savedParties: [party],
      allHeroes: [hero],
    );

    final outcome = TowerRunService.resolveFloor(
      playerData: player,
      party: party,
      floor: 8,
    );

    expect(
      outcome.logLines.any((line) => line.contains('คุณสมบัติประจำสาย')),
      isTrue,
    );
    expect(
      outcome.logLines.any((line) => line.contains('ตัวแปรชั้นพิเศษ')),
      isTrue,
    );
  });

  test('Tower resolve should produce per-hero live action reports', () {
    final hero = HeroModel(
      id: 'hero_live',
      name: 'Live Tester',
      gender: 'เธ',
      age: 25,
      backgroundStory: 'Live test',
      level: 16,
      baseStats: HeroStats(
        maxHp: 500,
        currentHp: 500,
        atk: 95,
        def: 72,
        spd: 58,
        maxEng: 110,
        currentEng: 110,
        luk: 24,
      ),
      currentStats: HeroStats(
        maxHp: 500,
        currentHp: 500,
        atk: 95,
        def: 72,
        spd: 58,
        maxEng: 110,
        currentEng: 110,
        luk: 24,
      ),
      aptitudes: const {'Knight': 1.0},
      currentClass: 'vanguard',
      unlockedClasses: const ['novice', 'vanguard'],
    );
    final party = PartyModel(
      partyId: 'live_party',
      partyName: 'Live Party',
      members: [hero],
    );
    final player = PlayerData(
      playerId: 'player_live',
      playerName: 'Live Player',
      inventory: [ItemUsageService.definitionFor('mana_potion')!.toItemModel()],
      savedParties: [party],
      allHeroes: [hero],
    );

    final outcome = TowerRunService.resolveFloor(
      playerData: player,
      party: party,
      floor: 3,
    );

    expect(outcome.heroReports, hasLength(1));
    expect(outcome.heroReports.first.action, isNotEmpty);
    expect(outcome.heroReports.first.maxMana, greaterThan(0));
  });

  test('Tower entry should consume warp stone and silver fee', () {
    final player = PlayerData(
      playerId: 'player_warp',
      playerName: 'Warp Player',
      silver: 500,
      inventory: [
        ItemUsageService.definitionFor(
          TowerRunService.towerWarpStoneItemId,
        )!.toItemModel(),
      ],
    );

    final fee = TowerRunService.entryFeeForFloor(4);
    final consumed = TowerRunService.consumeTowerEntryCost(player, 4);

    expect(consumed, isTrue);
    expect(player.silver, 500 - fee);
    expect(player.itemQuantity(TowerRunService.towerWarpStoneItemId), 0);
  });
}
