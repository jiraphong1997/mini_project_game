import 'dart:math';

import '../models/item_model.dart';
import '../models/party_model.dart';
import '../models/player_data.dart';

class TowerRunResult {
  final int startFloor;
  final int endFloor;
  final int clearedFloors;
  final int silverReward;
  final int goldReward;
  final bool wasDefeated;
  final bool reachedNewBest;
  final int expPerHero;
  final List<ItemModel> itemRewards;
  final String formationUsed;
  final List<String> battleLog;

  const TowerRunResult({
    required this.startFloor,
    required this.endFloor,
    required this.clearedFloors,
    required this.silverReward,
    required this.goldReward,
    required this.wasDefeated,
    required this.reachedNewBest,
    required this.expPerHero,
    required this.itemRewards,
    required this.formationUsed,
    required this.battleLog,
  });
}

class TowerFloorOutcome {
  final int floor;
  final bool succeeded;
  final bool reachedNewBest;
  final int enemyPower;
  final int partyPower;
  final int silverReward;
  final int goldReward;
  final int expPerHero;
  final List<ItemModel> itemRewards;
  final Map<String, int> levelsGained;
  final List<String> logLines;

  const TowerFloorOutcome({
    required this.floor,
    required this.succeeded,
    required this.reachedNewBest,
    required this.enemyPower,
    required this.partyPower,
    required this.silverReward,
    required this.goldReward,
    required this.expPerHero,
    required this.itemRewards,
    required this.levelsGained,
    required this.logLines,
  });
}

class TowerDecisionOption {
  final String id;
  final String title;
  final String description;

  const TowerDecisionOption({
    required this.id,
    required this.title,
    required this.description,
  });
}

class TowerDecisionEvent {
  final String id;
  final String title;
  final String description;
  final List<TowerDecisionOption> options;

  const TowerDecisionEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });
}

class TowerDecisionOutcome {
  final int enemyModifierDelta;
  final int rewardModifierDelta;
  final List<ItemModel> immediateItems;
  final int silverDelta;
  final int goldDelta;
  final List<String> logLines;

  const TowerDecisionOutcome({
    required this.enemyModifierDelta,
    required this.rewardModifierDelta,
    required this.immediateItems,
    required this.silverDelta,
    required this.goldDelta,
    required this.logLines,
  });
}

class TowerRunService {
  static final Random _random = Random();
  static const String recoveryItemId = 'ration_pack';
  static const List<String> _majorEventOrder = [
    'shrine',
    'oath_gate',
    'survivor',
  ];

  static TowerRunResult run({
    required PlayerData playerData,
    required PartyModel party,
    int maxFloorsPerRun = 5,
  }) {
    final aliveMembers = party.members.where((hero) => hero.isAlive).toList();
    final startFloor = playerData.highestTowerFloor + 1;

    if (aliveMembers.isEmpty) {
      return const TowerRunResult(
        startFloor: 1,
        endFloor: 0,
        clearedFloors: 0,
        silverReward: 0,
        goldReward: 0,
        wasDefeated: true,
        reachedNewBest: false,
        expPerHero: 0,
        itemRewards: [],
        formationUsed: 'balanced',
        battleLog: ['ไม่มีฮีโร่ที่พร้อมต่อสู้ในปาร์ตี้'],
      );
    }

    int currentFloor = startFloor;
    int silverReward = 0;
    int goldReward = 0;
    int expPerHero = 0;
    bool wasDefeated = false;
    bool reachedNewBest = false;
    final allItems = <ItemModel>[];
    final battleLog = <String>[];

    for (var i = 0; i < maxFloorsPerRun; i++) {
      final outcome = resolveFloor(
        playerData: playerData,
        party: party,
        floor: currentFloor,
      );

      silverReward += outcome.silverReward;
      goldReward += outcome.goldReward;
      expPerHero += outcome.expPerHero;
      allItems.addAll(outcome.itemRewards);
      battleLog.addAll(outcome.logLines);
      reachedNewBest = reachedNewBest || outcome.reachedNewBest;

      if (!outcome.succeeded) {
        wasDefeated = true;
        break;
      }

      currentFloor++;
    }

    final clearedFloors = currentFloor - startFloor;
    final endFloor = clearedFloors == 0 ? startFloor - 1 : currentFloor - 1;

    return TowerRunResult(
      startFloor: startFloor,
      endFloor: endFloor,
      clearedFloors: clearedFloors,
      silverReward: silverReward,
      goldReward: goldReward,
      wasDefeated: wasDefeated,
      reachedNewBest: reachedNewBest,
      expPerHero: expPerHero,
      itemRewards: allItems,
      formationUsed: party.formation,
      battleLog: battleLog,
    );
  }

  static TowerFloorOutcome resolveFloor({
    required PlayerData playerData,
    required PartyModel party,
    required int floor,
    int enemyModifier = 0,
    int rewardModifier = 0,
  }) {
    final aliveMembers = party.members.where((hero) => hero.isAlive).toList();
    if (aliveMembers.isEmpty) {
      return const TowerFloorOutcome(
        floor: 0,
        succeeded: false,
        reachedNewBest: false,
        enemyPower: 0,
        partyPower: 0,
        silverReward: 0,
        goldReward: 0,
        expPerHero: 0,
        itemRewards: [],
        levelsGained: {},
        logLines: ['ไม่มีสมาชิกที่พร้อมต่อสู้'],
      );
    }

    final baseEnemyPower = 260 + (floor * 175);
    final enemyPower = max(100, baseEnemyPower + enemyModifier);
    final supportPower = aliveMembers.fold<int>(
      0,
      (sum, hero) => sum + hero.currentStats.spd + hero.currentStats.luk,
    );
    final randomSwing = _random.nextInt(181) - 90;
    final formationBonus = _formationBonus(party);
    final partyPower = party.partyPower + supportPower + formationBonus + randomSwing;
    final succeeded = partyPower >= enemyPower;

    final silverReward = succeeded
        ? max(50, 120 + (floor * 45) + rewardModifier)
        : 0;
    final goldReward = succeeded && floor % 5 == 0 ? 10 : 0;
    final expPerHero = succeeded
        ? max(20, 30 + (floor * 12) + (rewardModifier ~/ 2))
        : 10;
    final itemRewards = succeeded ? _generateLootRewards(floor, rewardModifier) : <ItemModel>[];
    final levelsGained = <String, int>{};
    final logLines = <String>[
      succeeded
          ? 'ชนะชั้น $floor ด้วยพลัง $partyPower ต่อ $enemyPower (${party.formationLabel})'
          : 'พ่ายแพ้ที่ชั้น $floor ด้วยพลัง $partyPower ต่อ $enemyPower (${party.formationLabel})',
    ];

    for (final hero in aliveMembers) {
      final energyLoss = 12 + (succeeded ? 6 : 16);
      final hpLoss = 10 + (succeeded ? 8 : 20);

      final gainedLevels = hero.gainExp(expPerHero);
      hero.currentStats.currentEng =
          max(0, hero.currentStats.currentEng - energyLoss);
      hero.currentStats.currentHp =
          max(hero.currentStats.maxHp ~/ 4, hero.currentStats.currentHp - hpLoss);

      hero.adjustBond(succeeded ? 2 : 1);
      hero.adjustFaith(succeeded ? 1 : -1);
      logLines.add(
        '${hero.name} EXP +$expPerHero (${hero.currentExp}/${hero.expToNextLevel()}) • Stage ${hero.experienceStage}',
      );

      if (gainedLevels > 0) {
        levelsGained[hero.id] = gainedLevels;
        logLines.add('${hero.name} เลเวลอัป +$gainedLevels เป็น Lv.${hero.level}');
      }
    }

    if (succeeded) {
      playerData.highestTowerFloor = max(playerData.highestTowerFloor, floor);
      playerData.silver += silverReward;
      playerData.gold += goldReward;
      playerData.addItemRewards(itemRewards);
    }

    playerData.lastTowerSummary = logLines.join('\n');
    party.status = succeeded ? 'tower_climbing' : 'recovering';

    return TowerFloorOutcome(
      floor: floor,
      succeeded: succeeded,
      reachedNewBest: succeeded && floor == playerData.highestTowerFloor,
      enemyPower: enemyPower,
      partyPower: partyPower,
      silverReward: silverReward,
      goldReward: goldReward,
      expPerHero: expPerHero,
      itemRewards: itemRewards,
      levelsGained: levelsGained,
      logLines: logLines,
    );
  }

  static int adviceChargesForParty(PartyModel party) {
    if (party.members.isEmpty) return 1;
    final totalTrust = party.members.fold<int>(
      0,
      (sum, hero) => sum + hero.bond + hero.faith,
    );
    final averageTrust = totalTrust ~/ (party.members.length * 2);
    return averageTrust >= 80
        ? 4
        : averageTrust >= 60
            ? 3
            : averageTrust >= 35
                ? 2
                : 1;
  }

  static TowerDecisionEvent? maybeCreateMajorEvent({
    required PlayerData playerData,
    required int floor,
  }) {
    if (floor <= 0 || floor % 5 != 0) {
      return null;
    }
    if (playerData.resolvedMajorEventFloors.contains(floor)) {
      return null;
    }

    final eventId = _majorEventOrder.firstWhere(
      (id) => !playerData.recentMajorEventIds.contains(id),
      orElse: () => _majorEventOrder[playerData.resolvedMajorEventFloors.length % _majorEventOrder.length],
    );

    switch (eventId) {
      case 'shrine':
        return const TowerDecisionEvent(
          id: 'shrine',
          title: 'Ancient Shrine',
          description: 'ศาลโบราณเบื้องหน้าไม่ใช่สิ่งเล็กน้อย มันสามารถเปลี่ยนศรัทธาของทั้งทีมได้ถาวร',
          options: [
            TowerDecisionOption(
              id: 'vow',
              title: 'ทำสัตย์ปฏิญาณ',
              description: 'ทีมได้รับศรัทธาและพลังคุ้มครองถาวร แต่การเดินทางถัดไปจะได้ทรัพยากรน้อยลง',
            ),
            TowerDecisionOption(
              id: 'break_seal',
              title: 'ทำลายผนึก',
              description: 'รับ relic และพลังโจมตีถาวร แต่ศรัทธาลดลงหนักและชั้นถัดไปอันตรายขึ้น',
            ),
          ],
        );
      case 'oath_gate':
        return const TowerDecisionEvent(
          id: 'oath_gate',
          title: 'Gate of Oaths',
          description: 'ประตูทดสอบความเป็นผู้นำของทีม การเลือกครั้งนี้จะเปลี่ยนความผูกพันของฮีโร่ต่อผู้เล่นโดยตรง',
          options: [
            TowerDecisionOption(
              id: 'lead_from_front',
              title: 'นำทีมลุยเอง',
              description: 'ทีมศรัทธาในตัวผู้เล่นมากขึ้นและพลังป้องกันถาวรเพิ่ม แต่จะเหนื่อยล้าและเสียเวลาฟื้นตัว',
            ),
            TowerDecisionOption(
              id: 'let_them_choose',
              title: 'ให้ทีมตัดสินใจ',
              description: 'ความผูกพันของทีมสูงขึ้นและ advice charge อนาคตดีขึ้น แต่ชั้นถัดไปคาดเดายากกว่า',
            ),
          ],
        );
      default:
        return const TowerDecisionEvent(
          id: 'survivor',
          title: 'Last Survivor',
          description: 'ผู้รอดชีวิตจากทีมก่อนหน้าขอร่วมทางหรือขอความช่วยเหลือ การตอบสนองของคุณจะกระทบจริยธรรมของทีม',
          options: [
            TowerDecisionOption(
              id: 'rescue',
              title: 'ช่วยเหลือ',
              description: 'ทีมผูกพันกับผู้เล่นมากขึ้น ได้เสบียงพยุงกำลัง แต่ศัตรูชั้นถัดไปทันตั้งตัว',
            ),
            TowerDecisionOption(
              id: 'leave',
              title: 'ปล่อยผ่าน',
              description: 'เดินหน้าต่อได้เร็วและได้เปรียบเชิงยุทธวิธี แต่ bond/faith ของทีมจะลดลง',
            ),
          ],
        );
    }
  }

  static String buildAdvice({
    required PartyModel party,
    required TowerDecisionEvent event,
  }) {
    if (party.members.isEmpty) {
      return 'ไม่มีใครกล้าให้คำแนะนำในตอนนี้';
    }

    final advisor = [...party.members]
      ..sort((a, b) => (b.bond + b.faith).compareTo(a.bond + a.faith));
    final hero = advisor.first;

    switch (event.id) {
      case 'shrine':
        return hero.faith >= hero.bond
            ? '${hero.name}: ศาลนี้ตอบสนองต่อศรัทธา การสวดอ้อนวอนน่าจะปลอดภัยกว่า'
            : '${hero.name}: ถ้าทีมพร้อมรับความเสี่ยง การชิง relic จะคุ้ม แต่ต้องยอมรับผลตามมา';
      case 'merchant':
        return hero.bond >= 60
            ? '${hero.name}: เราควรซื้อเสบียงไว้ก่อน ทีมยังต้องการแรงสนับสนุน'
            : '${hero.name}: ลองต่อราคาได้ แต่ต้องยอมรับว่าพ่อค้าอาจไม่พอใจ';
      default:
        return hero.currentStats.spd >= hero.currentStats.def
            ? '${hero.name}: ทางเสี่ยงน่าจะคุ้มถ้าเราบุกเร็วพอ'
            : '${hero.name}: ทางปลอดภัยเหมาะกับสภาพทีมตอนนี้มากกว่า';
    }
  }

  static TowerDecisionOutcome applyDecision({
    required PlayerData playerData,
    required PartyModel party,
    required int floor,
    required TowerDecisionEvent event,
    required String optionId,
  }) {
    switch (event.id) {
      case 'shrine':
        _recordMajorEvent(playerData, event.id, floor: floor);
        if (optionId == 'vow') {
          for (final hero in party.members) {
            hero.currentStats.currentHp =
                min(hero.currentStats.maxHp, hero.currentStats.currentHp + 30);
            hero.currentStats.currentEng =
                min(hero.currentStats.maxEng, hero.currentStats.currentEng + 20);
            hero.adjustFaith(10);
            hero.baseStats.def += 2;
            hero.currentStats.def += 2;
          }
          return const TowerDecisionOutcome(
            enemyModifierDelta: -30,
            rewardModifierDelta: -60,
            immediateItems: [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: ['ทีมทำสัตย์ปฏิญาณต่อศาลโบราณ ศรัทธาและพลังป้องกันเพิ่มถาวร'],
          );
        }

        final relic = ItemModel(
          id: 'shrine_relic',
          name: 'Shrine Relic',
          type: ItemType.material,
          rarity: 3,
          quantity: 1,
        );
        for (final hero in party.members) {
          hero.adjustFaith(-10);
          hero.baseStats.atk += 3;
          hero.currentStats.atk += 3;
        }
        playerData.addItemRewards([relic]);
        return TowerDecisionOutcome(
          enemyModifierDelta: 90,
          rewardModifierDelta: 30,
          immediateItems: [relic],
          silverDelta: 0,
          goldDelta: 0,
          logLines: ['ทีมทำลายผนึกและชิง Shrine Relic พลังโจมตีเพิ่มถาวร แต่ศรัทธาลดลงหนัก'],
        );
      case 'oath_gate':
        _recordMajorEvent(playerData, event.id, floor: floor);
        if (optionId == 'lead_from_front') {
          for (final hero in party.members) {
            hero.adjustFaith(8);
            hero.currentStats.currentEng =
                max(0, hero.currentStats.currentEng - 10);
            hero.baseStats.def += 2;
            hero.currentStats.def += 2;
          }
          return const TowerDecisionOutcome(
            enemyModifierDelta: -10,
            rewardModifierDelta: 0,
            immediateItems: [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: ['ผู้เล่นนำทีมฝ่าประตูด้วยตนเอง ทีมศรัทธาเพิ่มและพลังป้องกันถาวรสูงขึ้น'],
          );
        }

        for (final hero in party.members) {
          hero.adjustBond(10);
          hero.currentStats.luk += 1;
          hero.baseStats.luk += 1;
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: 25,
          rewardModifierDelta: 20,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: ['ผู้เล่นให้ทีมเลือกทางเอง ความผูกพันของทีมเพิ่มขึ้นชัดเจนและลางสังหรณ์ดีขึ้น'],
        );

      default:
        _recordMajorEvent(playerData, event.id, floor: floor);
        if (optionId == 'rescue') {
          final supply = ItemModel(
            id: 'survivor_cache',
            name: 'Survivor Cache',
            type: ItemType.consumable,
            rarity: 2,
            quantity: 1,
          );
          playerData.addItemRewards([supply]);
          for (final hero in party.members) {
            hero.adjustBond(8);
            hero.adjustFaith(5);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: 35,
            rewardModifierDelta: 10,
            immediateItems: [supply],
            silverDelta: 0,
            goldDelta: 0,
            logLines: const ['ทีมช่วยเหลือผู้รอดชีวิต ความผูกพันและศรัทธาเพิ่ม แต่ศัตรูชั้นถัดไปทันตั้งตัว'],
          );
        }

        for (final hero in party.members) {
          hero.adjustBond(-8);
          hero.adjustFaith(-6);
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -40,
          rewardModifierDelta: 0,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: ['ทีมปล่อยผู้รอดชีวิตไว้เบื้องหลัง เดินหน้าได้เร็วขึ้น แต่ bond และ faith ลดลงอย่างชัดเจน'],
        );
    }
  }

  static void _recordMajorEvent(
    PlayerData playerData,
    String eventId, {
    required int floor,
  }) {
    final updatedIds = [...playerData.recentMajorEventIds.where((id) => id != eventId), eventId];
    if (updatedIds.length > 2) {
      updatedIds.removeAt(0);
    }
    playerData.recentMajorEventIds = updatedIds;
    if (!playerData.resolvedMajorEventFloors.contains(floor)) {
      playerData.resolvedMajorEventFloors = [
        ...playerData.resolvedMajorEventFloors,
        floor,
      ];
    }
  }

  static void recoverParty(PartyModel party) {
    for (final hero in party.members) {
      hero.fullyRecover();
    }
    party.status = 'idle';
  }

  static Duration scheduleRecoveryCooldown(
    PartyModel party, {
    required int clearedFloors,
  }) {
    if (party.members.isEmpty) {
      party.status = 'idle';
      return Duration.zero;
    }

    final totalFatigue = party.members.fold<int>(0, (sum, hero) {
      final hpLoss = hero.currentStats.maxHp - hero.currentStats.currentHp;
      final engLoss = hero.currentStats.maxEng - hero.currentStats.currentEng;
      return sum + hpLoss + (engLoss * 2);
    });
    final averageFatigue = totalFatigue ~/ party.members.length;
    final minutes =
        (6 + (clearedFloors * 4) + (averageFatigue ~/ 40)).clamp(6, 180);
    final duration = Duration(minutes: minutes);

    for (final hero in party.members) {
      hero.startRecoveryCooldown(duration);
    }
    party.status = 'recovering';
    return duration;
  }

  static void refreshRecoveryState(PartyModel party) {
    bool hasRecoveringMember = false;
    for (final hero in party.members) {
      if (hero.isRecovering) {
        hasRecoveringMember = true;
        continue;
      }

      if (hero.recoveryReadyAtEpochMs != null) {
        hero.fullyRecover();
      }
    }

    party.status = hasRecoveringMember ? 'recovering' : 'idle';
  }

  static bool canStartExpedition(PartyModel party) {
    refreshRecoveryState(party);
    return party.members.isNotEmpty &&
        party.members.every((hero) => !hero.isRecovering);
  }

  static int quickRecoverySilverCost(PartyModel party) {
    if (party.members.isEmpty) {
      return 0;
    }

    final totalFatigue = party.members.fold<int>(0, (sum, hero) {
      final hpLoss = hero.currentStats.maxHp - hero.currentStats.currentHp;
      final engLoss = hero.currentStats.maxEng - hero.currentStats.currentEng;
      return sum + hpLoss + (engLoss * 2);
    });
    return (90 + (party.members.length * 40) + (totalFatigue ~/ 10))
        .clamp(120, 1200);
  }

  static bool quickRecoverWithSilver(PlayerData playerData, PartyModel party) {
    final cost = quickRecoverySilverCost(party);
    if (playerData.silver < cost) {
      return false;
    }

    playerData.silver -= cost;
    recoverParty(party);
    return true;
  }

  static bool quickRecoverWithItem(PlayerData playerData, PartyModel party) {
    final consumed = playerData.consumeItem(recoveryItemId);
    if (!consumed) {
      return false;
    }

    recoverParty(party);
    return true;
  }

  static int _formationBonus(PartyModel party) {
    switch (party.formation) {
      case 'assault':
        return party.members.fold<int>(0, (sum, hero) => sum + hero.currentStats.atk) ~/ 2;
      case 'bulwark':
        return party.members.fold<int>(0, (sum, hero) => sum + hero.currentStats.def) ~/ 2;
      case 'swift':
        return party.members.fold<int>(0, (sum, hero) => sum + hero.currentStats.spd + hero.currentStats.luk) ~/ 2;
      default:
        return party.members.fold<int>(0, (sum, hero) => sum + hero.currentStats.luk) ~/ 3;
    }
  }

  static List<ItemModel> _generateLootRewards(int floor, int rewardModifier) {
    final rewards = <ItemModel>[];
    final adjustedFloor = floor + max(0, rewardModifier ~/ 30);
    final rarity = adjustedFloor >= 15
        ? 4
        : adjustedFloor >= 8
            ? 3
            : adjustedFloor >= 4
                ? 2
                : 1;

    rewards.add(
      ItemModel(
        id: 'tower_ore_$rarity',
        name: rarity >= 3 ? 'Arcane Ore' : 'Tower Ore',
        type: ItemType.material,
        rarity: rarity,
        quantity: 1 + _random.nextInt(2),
      ),
    );

    if (_random.nextDouble() > 0.55) {
      rewards.add(
        ItemModel(
          id: 'ration_pack',
          name: 'Field Ration',
          type: ItemType.consumable,
          rarity: 1,
          quantity: 1,
        ),
      );
    }

    if (adjustedFloor >= 10 && _random.nextDouble() > 0.82) {
      rewards.add(
        ItemModel(
          id: 'class_trial_seal',
          name: 'Class Trial Seal',
          type: ItemType.consumable,
          rarity: adjustedFloor >= 20 ? 4 : 3,
          quantity: 1,
        ),
      );
    }

    if (rarity >= 3 && _random.nextDouble() > 0.7) {
      rewards.add(
        ItemModel(
          id: 'tower_relic_$rarity',
          name: 'Tower Relic',
          type: ItemType.material,
          rarity: rarity,
          quantity: 1,
        ),
      );
    }

    return rewards;
  }
}
