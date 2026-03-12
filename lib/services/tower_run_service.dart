import 'dart:math';

import '../models/hero_model.dart';
import '../models/item_model.dart';
import '../models/party_model.dart';
import '../models/player_data.dart';
import 'item_usage_service.dart';

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
  static const Set<String> _holyClasses = {
    'acolyte',
    'oracle',
    'saint',
  };
  static const Set<String> _frontlineClasses = {
    'vanguard',
    'knight',
    'warbringer',
  };
  static const Set<String> _scoutClasses = {
    'skirmisher',
    'ranger',
    'shadowblade',
  };
  static const Set<String> _guardianClasses = {
    'knight',
    'saint',
    'acolyte',
  };

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
        battleLog: ['ไม่มีฮีโร่ที่พร้อมลุยอยู่ในปาร์ตี้'],
      );
    }

    var currentFloor = startFloor;
    var silverReward = 0;
    var goldReward = 0;
    var expPerHero = 0;
    var wasDefeated = false;
    var reachedNewBest = false;
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

      currentFloor += 1;
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
        logLines: ['ไม่มีสมาชิกในปาร์ตี้ที่พร้อมต่อสู้'],
      );
    }

    final baseEnemyPower = 280 + (floor * 180);
    var enemyPower = max(100, baseEnemyPower + enemyModifier);
    final supportPower = aliveMembers.fold<int>(
      0,
      (sum, hero) => sum + hero.currentStats.spd + hero.currentStats.luk,
    );
    final totalHeroPower = aliveMembers.fold<double>(
      0,
      (sum, hero) => sum + _heroCombatPower(hero),
    );
    final randomSwing = _random.nextInt(171) - 85;
    final formationBonus = _formationBonus(party);
    final classSynergyBonus = _classSynergyBonus(party);
    final equipmentPowerBonus = aliveMembers.fold<int>(
      0,
      (sum, hero) => sum + _heroEquipmentBattlePower(hero),
    );
    final equipmentShieldBonus = aliveMembers.fold<int>(
      0,
      (sum, hero) => sum + _heroEquipmentShield(hero),
    );
    final equipmentRewardBonus = aliveMembers.fold<int>(
      0,
      (sum, hero) => sum + _heroEquipmentRewardBonus(hero),
    );
    enemyPower = max(100, enemyPower - equipmentShieldBonus);
    final partyPower = party.partyPower +
        supportPower +
        formationBonus +
        classSynergyBonus +
        equipmentPowerBonus +
        randomSwing;
    final succeeded = partyPower >= enemyPower;
    final reachedNewBest = succeeded && floor > playerData.highestTowerFloor;

    final silverReward = succeeded
        ? max(50, 120 + (floor * 45) + rewardModifier + equipmentRewardBonus)
        : 0;
    final goldReward = succeeded && floor % 5 == 0
        ? 10 + (equipmentRewardBonus >= 24 ? 1 : 0)
        : 0;
    final expPerHero = succeeded
        ? max(
            20,
            30 + (floor * 12) + (rewardModifier ~/ 2) + (equipmentRewardBonus ~/ 4),
          )
        : 10;
    final itemRewards =
        succeeded ? _generateLootRewards(floor, rewardModifier) : <ItemModel>[];
    final levelsGained = <String, int>{};
    final logLines = <String>[
      succeeded
          ? 'ชนะชั้น $floor ด้วยพลัง $partyPower ต่อ $enemyPower (${party.formationLabel})'
          : 'พ่ายแพ้ที่ชั้น $floor ด้วยพลัง $partyPower ต่อ $enemyPower (${party.formationLabel})',
    ];

    if (classSynergyBonus > 0) {
      logLines.add('ซินเนอร์จี้คลาส +$classSynergyBonus');
    }
    if (equipmentPowerBonus > 0) {
      logLines.add('พลังจากอุปกรณ์ระหว่างการต่อสู้ +$equipmentPowerBonus');
    }
    if (equipmentShieldBonus > 0) {
      logLines.add('อุปกรณ์ช่วยลดแรงกดดันของมอนสเตอร์ลง $equipmentShieldBonus');
    }
    if (equipmentRewardBonus > 0 && succeeded) {
      logLines.add('อุปกรณ์ช่วยเพิ่มคุณภาพการเก็บของ +$equipmentRewardBonus');
    }

    for (final hero in aliveMembers) {
      final combatShare = totalHeroPower <= 0
          ? 1 / aliveMembers.length
          : _heroCombatPower(hero) / totalHeroPower;
      final energyLoss = _heroEnergyLoss(
        hero,
        floor: floor,
        enemyPower: enemyPower,
        succeeded: succeeded,
        combatShare: combatShare,
        formation: party.formation,
      );
      final hpLoss = _heroHpLoss(
        hero,
        floor: floor,
        enemyPower: enemyPower,
        succeeded: succeeded,
        combatShare: combatShare,
        formation: party.formation,
      );
      final minimumHp = max(1, hero.currentStats.maxHp ~/ (succeeded ? 5 : 6));

      final gainedLevels = hero.gainExp(expPerHero);
      hero.currentStats.currentEng =
          max(0, hero.currentStats.currentEng - energyLoss);
      hero.currentStats.currentHp =
          max(minimumHp, hero.currentStats.currentHp - hpLoss);

      hero.adjustBond(succeeded ? 2 : 1);
      hero.adjustFaith(succeeded ? 1 : -1);
      if (succeeded) {
        hero.totalTowerFloorsCleared += 1;
      }

      logLines.add(
        '${hero.name} ใช้แรง $energyLoss ENG รับแรงปะทะ $hpLoss HP และได้ EXP +$expPerHero (${hero.currentExp}/${hero.expToNextLevel()})',
      );

      if (gainedLevels > 0) {
        levelsGained[hero.id] = gainedLevels;
        logLines.add('${hero.name} เลเวลอัป +$gainedLevels เป็น Lv.${hero.level}');
      }
    }

    if (itemRewards.isNotEmpty) {
      logLines.add(
        'เก็บของได้: ${itemRewards.map((item) => '${item.name} x${item.quantity}').join(', ')}',
      );
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
      reachedNewBest: reachedNewBest,
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
    if (party.members.isEmpty) {
      return 1;
    }

    final totalTrust = party.members.fold<int>(
      0,
      (sum, hero) => sum + hero.bond + hero.faith,
    );
    final averageTrust = totalTrust ~/ (party.members.length * 2);
    if (averageTrust >= 80) {
      return 4;
    }
    if (averageTrust >= 60) {
      return 3;
    }
    if (averageTrust >= 35) {
      return 2;
    }
    return 1;
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

    final pendingChainId = playerData.pendingMajorChainEventIds.isNotEmpty
        ? playerData.pendingMajorChainEventIds.first
        : playerData.pendingMajorChainEventId;
    if (pendingChainId != null) {
      if (playerData.resolvedMajorChainEventIds.contains(pendingChainId)) {
        if (playerData.pendingMajorChainEventIds.isNotEmpty) {
          playerData.pendingMajorChainEventIds =
              playerData.pendingMajorChainEventIds.where((id) => id != pendingChainId).toList();
        }
        playerData.pendingMajorChainEventId = playerData.pendingMajorChainEventIds.isEmpty
            ? null
            : playerData.pendingMajorChainEventIds.first;
      } else {
        final chainEvent = _buildChainEvent(pendingChainId);
        if (chainEvent != null) {
          return chainEvent;
        }
      }
    }

    final eventId = _majorEventOrder.firstWhere(
      (id) => !playerData.recentMajorEventIds.contains(id),
      orElse: () => _majorEventOrder[
          playerData.resolvedMajorEventFloors.length % _majorEventOrder.length],
    );

    switch (eventId) {
      case 'shrine':
        return const TowerDecisionEvent(
          id: 'shrine',
          title: 'ศาลโบราณ',
          description:
              'ศาลเก่ากลางหอคอยยังมีพลังตอบรับอยู่ การเลือกที่นี่จะเปลี่ยนศรัทธาและเส้นทางของทีมแบบถาวร',
          options: [
            TowerDecisionOption(
              id: 'vow',
              title: 'ถวายสัตย์',
              description:
                  'รับการคุ้มครองและศรัทธาระยะยาว แต่รางวัลช่วงสั้นจะลดลง',
            ),
            TowerDecisionOption(
              id: 'break_seal',
              title: 'ทำลายผนึก',
              description:
                  'ชิงวัตถุศักดิ์สิทธิ์และพลังโจมตีทันที แต่ศรัทธาจะลดลงและชั้นถัดไปอันตรายขึ้น',
            ),
          ],
        );
      case 'oath_gate':
        return const TowerDecisionEvent(
          id: 'oath_gate',
          title: 'ประตูคำสัตย์',
          description:
              'ประตูนี้วัดว่าทีมเชื่อมือผู้นำแค่ไหน การตัดสินใจจะกระทบทั้งความไว้ใจและจังหวะการปีนหอ',
          options: [
            TowerDecisionOption(
              id: 'lead_from_front',
              title: 'นำทีมบุกเอง',
              description:
                  'เพิ่มศรัทธาและวินัยแนวหน้า แต่ทีมจะเหนื่อยและต้องพักนานขึ้น',
            ),
            TowerDecisionOption(
              id: 'let_them_choose',
              title: 'ให้ทีมตัดสินใจ',
              description:
                  'Bond และการขอคำแนะนำดีขึ้น แต่ชั้นถัดไปจะควบคุมได้ยากกว่า',
            ),
          ],
        );
      default:
        return const TowerDecisionEvent(
          id: 'survivor',
          title: 'ผู้รอดชีวิตคนสุดท้าย',
          description:
              'ผู้รอดชีวิตจากคณะก่อนหน้าขอความช่วยเหลือ การตอบสนองของคุณจะกระทบจริยธรรม ทรัพยากร และความสัมพันธ์ของทีม',
          options: [
            TowerDecisionOption(
              id: 'rescue',
              title: 'ช่วยเหลือ',
              description:
                  'ได้เสบียงและความไว้ใจ แต่ศัตรูชั้นถัดไปจะมีเวลาตั้งตัว',
            ),
            TowerDecisionOption(
              id: 'leave',
              title: 'ปล่อยผ่าน',
              description:
                  'เดินหน้าต่อได้เร็วและได้เปรียบเชิงเส้นทาง แต่ Bond/Faith ของทีมจะลดลง',
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
      return 'ตอนนี้ไม่มีใครพร้อมให้คำแนะนำ';
    }

    final advisor = [...party.members]
      ..sort((a, b) => (b.bond + b.faith).compareTo(a.bond + a.faith));
    final hero = advisor.first;
    final hasHolyGuide = _countClasses(party, _holyClasses) > 0;
    final hasFrontliner = _countClasses(party, _frontlineClasses) > 0;
    final hasScout = _countClasses(party, _scoutClasses) > 0;
    final hasEmblem = _countEquippedItems(party, {'saints_emblem'}) > 0;
    final hasTowerMail = _countEquippedItems(party, {'tower_mail'}) > 0;
    final hasStrikeGear =
        _countEquippedItems(party, {'steel_blade', 'ranger_bow'}) > 0;
    final seed = '${event.id}:${hero.id}:${party.formation}:${hero.bond}:${hero.faith}';

    if (_isChainEvent(event.id)) {
      switch (event.id) {
        case 'pilgrim_rest':
          return hasEmblem
              ? _pickVariant(seed, [
                  '${hero.name}: ตราศรัทธากำลังตอบสนอง จุดนี้รับพรแล้วคุมความเสี่ยงของชั้นถัดไปได้ดีมาก',
                  '${hero.name}: ถ้ามีตราศรัทธาอยู่ รับพรคุ้มกว่า เราจะได้พักแบบไม่เสียจังหวะจนเกินไป',
                ])
              : _pickVariant(seed, [
                  '${hero.name}: จุดนี้เหมาะกับการฟื้นกำลัง รับพรจะปลอดภัยกว่า แต่ถ้าต้องเร่งชั้นก็ยังฝืนต่อได้',
                  '${hero.name}: ถ้าเรายังไหว ค่อยกดต่อก็ได้ แต่โดยรวมการรับพรทำให้รอบนี้เสถียรกว่า',
                ]);
        case 'relic_echo':
          return hasStrikeGear
              ? _pickVariant(seed, [
                  '${hero.name}: อาวุธชุดนี้รีดพลังจากเศษรีลิกได้ คุ้มถ้าจะเร่งของ แต่ชั้นถัดไปจะโหดขึ้นแน่',
                  '${hero.name}: ถ้าจะเปิดพลังรีลิก ตอนนี้อุปกรณ์เรารองรับอยู่ แต่ต้องยอมรับความเสี่ยงของเส้นทางต่อไป',
                ])
              : _pickVariant(seed, [
                  '${hero.name}: ผนึกมันกลับจะนิ่งกว่า ถ้าเปิดพลังตอนนี้เราจะได้ของเพิ่มก็จริง แต่ความเสี่ยงจะพุ่ง',
                  '${hero.name}: ทางปลอดภัยคือกดมันไว้ก่อน ช่องทางรวยเร็วมี แต่แลกกับชั้นหน้าที่แรงกว่าเดิม',
                ]);
        case 'vanguard_camp':
          return hasTowerMail
              ? _pickVariant(seed, [
                  '${hero.name}: ชุดเกราะเราพอจะยึดค่ายนี้ไว้ได้ ถ้าตั้งรับก่อน ชั้นถัดไปจะเบาลงชัดเจน',
                  '${hero.name}: ถ้าจะปักค่ายจริง ตอนนี้อุปกรณ์พร้อม ตั้งค่ายก่อนแล้วค่อยดันจะนิ่งกว่า',
                ])
              : _pickVariant(seed, [
                  '${hero.name}: ค่ายนี้คือจุดเลือกระหว่างความนิ่งกับความเร็ว ตั้งค่ายจะปลอดภัยกว่า ส่วนบุกต่อจะคุ้มรางวัล',
                  '${hero.name}: ถ้าทีมเริ่มล้าให้ตั้งค่าย แต่ถ้ายังแรงอยู่ การเปิดบุกต่อจะได้จังหวะดีกว่า',
                ]);
        case 'council_fire':
          return _pickVariant(seed, [
            '${hero.name}: ถ้าฟังทีมตอนนี้ Bond จะขึ้นแรงและคำแนะนำรอบหน้าจะเชื่อถือได้มากขึ้น',
            '${hero.name}: ถ้าต้องการความไว้ใจระยะยาว ให้เปิดวงคุย แต่ถ้าจะเร่งเกมค่อยตัดบทแล้วสั่งตรง ๆ',
          ]);
        case 'hidden_camp':
          return _pickVariant(seed, [
            '${hero.name}: ถ้าทีมล้าให้เอาเสบียง แต่ถ้าทีมยังมีแรง การรับคนนำทางจะคุ้มกับชั้นถัดไปมากกว่า',
            '${hero.name}: ของในค่ายช่วยเรื่องพักฟื้น ส่วนไกด์ช่วยเรื่องเส้นทาง เลือกตามสภาพทีมตอนนี้ได้เลย',
          ]);
      }
    }

    if (event.id == 'shrine' && hasHolyGuide) {
      return _pickVariant(seed, [
        '${hero.name}: สายศรัทธาในทีมช่วยประคองศาลนี้ได้ ถ้าถวายสัตว์ ความเสี่ยงของชั้นถัดไปจะลดลงมาก',
        '${hero.name}: คลาสศรัทธาคุมพิธีได้อยู่ เลือกถวายสัตย์จะปลอดภัยกว่าและไม่กระทบความไว้ใจระยะยาว',
      ]);
    }

    if (event.id == 'oath_gate' && hasFrontliner) {
      return _pickVariant(seed, [
        '${hero.name}: แนวหน้าของเรารับแรงกดดันจากประตูนี้ไหว ถ้านำทีมบุกเองศึกชั้นหน้าจะเบาลง',
        '${hero.name}: ตอนนี้มีตัวชนที่พอถือแนวได้ การนำบุกเองคุมจังหวะชั้นต่อไปได้ดีกว่า',
      ]);
    }

    if (event.id == 'oath_gate') {
      if (hero.bond >= 60) {
        return _pickVariant(seed, [
          '${hero.name}: ทีมเชื่อมือคุณอยู่ ถ้านำบุกเองประตูนี้จะนิ่งกว่า แม้จะแลกกับความเหนื่อย',
          '${hero.name}: ตอนนี้สั่งตรงได้ ทีมจะตาม แต่ต้องเผื่อแรงสำหรับการพักหลังจากนั้นด้วย',
        ]);
      }
      return _pickVariant(seed, [
        '${hero.name}: ถ้าให้ทีมช่วยตัดสินใจ Bond จะขึ้นเร็วกว่า แต่ชั้นถัดไปจะคาดเดายากขึ้น',
        '${hero.name}: ทางเลือกปลอดภัยด้านความสัมพันธ์คือเปิดให้ทีมมีเสียง แม้จังหวะเกมจะไม่นิ่งเท่าเดิม',
      ]);
    }

    if (event.id == 'survivor' && hasScout) {
      return _pickVariant(seed, [
        '${hero.name}: สายลาดตระเวนพาเลี่ยงเส้นทางเสี่ยงได้ ถ้าจะปล่อยผ่านตอนนี้โทษจะเบากว่าปกติ',
        '${hero.name}: เราอ่านทางออกได้ ถ้าไม่ช่วยก็ยังคุมความเสียหายด้านความสัมพันธ์ได้อยู่',
      ]);
    }

    switch (event.id) {
      case 'shrine':
        if (hero.faith >= hero.bond) {
          return _pickVariant(seed, [
            '${hero.name}: ศาลนี้ตอบสนองต่อศรัทธาโดยตรง ถวายสัตว์จะนิ่งและปลอดภัยกว่า',
            '${hero.name}: ถ้าดูจากบรรยากาศที่นี่ การให้ความเคารพจะได้ผลดีกว่าการฝืนเอาของ',
          ]);
        }
        return _pickVariant(seed, [
          '${hero.name}: ถ้าทีมพร้อมรับความเสี่ยง การชิงรีลิกก็มีค่ามาก แต่ต้องรับผลตามมาด้วย',
          '${hero.name}: จุดนี้รวยเร็วได้จากการทำลายผนึก แต่ชั้นหน้าจะไม่ง่ายแล้ว',
        ]);
      case 'survivor':
        if (hero.bond >= hero.faith) {
          return _pickVariant(seed, [
            '${hero.name}: ถ้ายังพอมีแรง การช่วยเขาจะทำให้ทีมเชื่อใจคุณขึ้นมาก',
            '${hero.name}: เรื่องแบบนี้กระทบ Bond ตรง ๆ ถ้าช่วยตอนนี้ทีมจะจำไว้แน่',
          ]);
        }
        return _pickVariant(seed, [
          '${hero.name}: ถ้าเราปล่อยผ่านก็ยังเดินต่อได้ แต่ต้องยอมรับว่า Faith ของทีมจะตกลง',
          '${hero.name}: ทางเร็วคือไม่หยุดช่วย แต่ผลด้านความศรัทธาจะตามมาแน่นอน',
        ]);
      default:
        if (hero.currentStats.spd >= hero.currentStats.def) {
          return _pickVariant(seed, [
            '${hero.name}: ถ้าจะเล่นเสี่ยง ตอนนี้ทีมยังพอเร่งจังหวะได้',
            '${hero.name}: สภาพทีมยังพอรับแผนบุกเร็วได้ ถ้าจะเดิมพันก็เป็นช่วงนี้',
          ]);
        }
        return _pickVariant(seed, [
          '${hero.name}: ทางที่นิ่งกว่าเหมาะกับทีมตอนนี้ ถ้าฝืนเร่งอาจไม่คุ้ม',
          '${hero.name}: ตอนนี้เซฟแรงไว้ก่อนจะมั่นคงกว่า เพราะทีมเริ่มรับแรงชนหนักพอสมควรแล้ว',
        ]);
    }
  }

  static TowerDecisionOutcome applyDecision({
    required PlayerData playerData,
    required PartyModel party,
    required int floor,
    required TowerDecisionEvent event,
    required String optionId,
  }) {
    final holyCount = _countClasses(party, _holyClasses);
    final frontlineCount = _countClasses(party, _frontlineClasses);
    final scoutCount = _countClasses(party, _scoutClasses);
    final guardianCount = _countClasses(party, _guardianClasses);
    final emblemCount = _countEquippedItems(party, {'saints_emblem'});
    final guardGearCount = _countEquippedItems(party, {'tower_mail'});
    final strikeGearCount =
        _countEquippedItems(party, {'steel_blade', 'ranger_bow'});
    final holySupport = holyCount + emblemCount;
    final frontlineSupport = frontlineCount + guardGearCount;
    final scoutSupport = scoutCount + strikeGearCount;
    final guardianSupport = guardianCount + guardGearCount;

    if (_isChainEvent(event.id)) {
      return _applyChainDecision(
        playerData: playerData,
        party: party,
        floor: floor,
        event: event,
        optionId: optionId,
      );
    }

    if (event.id == 'shrine' && optionId == 'vow' && holySupport > 0) {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'pilgrim_rest');
      for (final hero in party.members) {
        hero.currentStats.currentHp =
            min(hero.currentStats.maxHp, hero.currentStats.currentHp + 30);
        hero.currentStats.currentEng = min(
          hero.currentStats.maxEng,
          hero.currentStats.currentEng + 30 + (emblemCount > 0 ? 10 : 0),
        );
        hero.adjustFaith(14 + (emblemCount > 0 ? 2 : 0));
        hero.baseStats.def += 2;
        hero.currentStats.def += 2;
      }
      return TowerDecisionOutcome(
        enemyModifierDelta: -45 - (emblemCount > 0 ? 10 : 0),
        rewardModifierDelta: -40 + (emblemCount > 0 ? 10 : 0),
        immediateItems: const [],
        silverDelta: 0,
        goldDelta: 0,
        logLines: [
          'พิธีที่ศาลนิ่งขึ้นเพราะสายศรัทธาในทีม ชั้นถัดไปจะอ่อนแรงลงชัดเจน',
          if (emblemCount > 0)
            'ตราศรัทธาช่วยขยายผลของพิธี ทำให้ความเสี่ยงลดลงมากกว่าเดิม',
        ],
      );
    }

    if (event.id == 'oath_gate' &&
        optionId == 'lead_from_front' &&
        frontlineSupport > 0) {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'vanguard_camp');
      for (final hero in party.members) {
        hero.adjustFaith(8);
        hero.adjustBond(4);
        hero.currentStats.currentEng =
            max(0, hero.currentStats.currentEng - (guardGearCount > 0 ? 5 : 10));
        hero.baseStats.def += 2;
        hero.currentStats.def += 2;
      }
      return TowerDecisionOutcome(
        enemyModifierDelta: -30 - (guardGearCount > 0 ? 10 : 0),
        rewardModifierDelta: 15 + (guardGearCount > 0 ? 10 : 0),
        immediateItems: const [],
        silverDelta: 0,
        goldDelta: 0,
        logLines: [
          'แนวหน้ารับแรงกดของประตูคำสัตย์ไว้ได้ ทีมเชื่อมือคำสั่งและขยับต่ออย่างเป็นระเบียบ',
          if (guardGearCount > 0)
            'เกราะหอคอยช่วยให้แนวหน้ารับแรงได้ดีขึ้น ความเหนื่อยจึงลดลง',
        ],
      );
    }

    if (event.id == 'survivor' && optionId == 'rescue' && guardianSupport > 0) {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'hidden_camp');
      final supply = _itemReward('survivor_cache');
      final ration = _itemReward('ration_pack');
      playerData.addItemRewards([supply, ration]);
      for (final hero in party.members) {
        hero.adjustBond(12);
        hero.adjustFaith(7);
        hero.currentStats.currentHp = min(
          hero.currentStats.maxHp,
          hero.currentStats.currentHp + 20 + (guardGearCount > 0 ? 10 : 0),
        );
      }
      return TowerDecisionOutcome(
        enemyModifierDelta: guardGearCount > 0 ? 10 : 15,
        rewardModifierDelta: 25 + (guardGearCount > 0 ? 10 : 0),
        immediateItems: [supply, ration],
        silverDelta: 0,
        goldDelta: 0,
        logLines: [
          'การช่วยเหลือเป็นระบบเพราะมีตัวคุ้มกัน ทีมได้ทั้งกำลังใจ การฟื้นตัว และเสบียงกลับมาทันที',
          if (guardGearCount > 0)
            'เกราะหอคอยช่วยให้การถอนกำลังระหว่างช่วยเหลือไม่แตกแถว',
        ],
      );
    }

    if (event.id == 'survivor' && optionId == 'leave' && scoutSupport > 0) {
      _recordMajorEvent(playerData, event.id, floor: floor);
      for (final hero in party.members) {
        hero.adjustBond(-4);
        hero.adjustFaith(-3);
      }
      return TowerDecisionOutcome(
        enemyModifierDelta: -55,
        rewardModifierDelta: 10 + (strikeGearCount > 0 ? 10 : 0),
        immediateItems: const [],
        silverDelta: 50 + (strikeGearCount > 0 ? 25 : 0),
        goldDelta: 0,
        logLines: [
          'หน่วยลาดตระเวนพาทีมออกจากจุดนี้อย่างสะอาด ความเสียหายด้านความสัมพันธ์จึงเบากว่าปกติ',
          if (strikeGearCount > 0)
            'อุปกรณ์สายบุกช่วยให้แนวหลังถอนตัวพร้อมเก็บทรัพยากรเพิ่มได้',
        ],
      );
    }

    if (event.id == 'shrine' && optionId == 'vow') {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'pilgrim_rest');
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
        logLines: [
          'ทีมถวายสัตย์ต่อศาลโบราณ ศรัทธาเพิ่ม เกราะใจแข็งขึ้น และเปิดทางไปยังจุดพักของผู้แสวงบุญ',
        ],
      );
    }

    if (event.id == 'shrine' && optionId == 'break_seal') {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'relic_echo');
      final relic = _itemReward('shrine_relic');
      for (final hero in party.members) {
        hero.adjustFaith(-10);
        hero.baseStats.atk += 3;
        hero.currentStats.atk += 3;
      }
      playerData.addItemRewards([relic]);
      return TowerDecisionOutcome(
        enemyModifierDelta: strikeGearCount > 0 ? 70 : 90,
        rewardModifierDelta: strikeGearCount > 0 ? 45 : 30,
        immediateItems: [relic],
        silverDelta: strikeGearCount > 0 ? 60 : 0,
        goldDelta: 0,
        logLines: [
          'ผนึกถูกทำลายและรีลิกถูกชิงออกมา เส้นทางต่อจากนี้จะถูกรบกวนด้วยเสียงสะท้อนของมัน',
          if (strikeGearCount > 0)
            'อุปกรณ์สายบุกช่วยให้ชิงรีลิกได้เร็วและเก็บเศษทรัพยากรเพิ่มทันที',
        ],
      );
    }

    if (event.id == 'oath_gate' && optionId == 'lead_from_front') {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'vanguard_camp');
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
        logLines: [
          'ผู้นำพาทีมฝ่าประตูด้วยตัวเอง ศรัทธาและวินัยแนวหน้าของทีมเพิ่มขึ้น',
        ],
      );
    }

    if (event.id == 'oath_gate' && optionId == 'let_them_choose') {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'council_fire');
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
        logLines: [
          'ทีมได้มีเสียงร่วมกัน Bond เพิ่มขึ้นชัดเจน และเส้นทางต่อไปจะนำไปสู่กองไฟประชุม',
        ],
      );
    }

    if (event.id == 'survivor' && optionId == 'rescue') {
      _recordMajorEvent(playerData, event.id, floor: floor);
      _queueChainEvent(playerData, 'hidden_camp');
      final supply = _itemReward('survivor_cache');
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
        logLines: const [
          'ผู้รอดชีวิตบอกตำแหน่งค่ายลับในชั้นลึกให้ก่อนจากกัน',
        ],
      );
    }

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
            logLines: ['ทีมถวายสัตย์ต่อศาลโบราณ ศรัทธาและการคุ้มกันเพิ่มขึ้นถาวร'],
          );
        }

        final relic = _itemReward('shrine_relic');
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
          logLines: ['ทีมทำลายผนึกและชิงเศษรีลิกมาได้ พลังโจมตีเพิ่มขึ้น แต่ศรัทธาของทีมลดลงหนัก'],
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
            logLines: ['ผู้นำพาทีมฝ่าประตูด้วยตัวเอง ศรัทธาและวินัยแนวหน้าของทีมเพิ่มขึ้น'],
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
          logLines: ['ผู้นำเปิดให้ทีมร่วมตัดสินใจ Bond เพิ่มขึ้นชัดเจนและบรรยากาศดีขึ้น'],
        );
      default:
        _recordMajorEvent(playerData, event.id, floor: floor);
        if (optionId == 'rescue') {
          final supply = _itemReward('survivor_cache');
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
            logLines: const [
              'ทีมช่วยผู้รอดชีวิตไว้ได้ ความผูกพันและศรัทธาเพิ่มขึ้น แต่ศัตรูชั้นถัดไปจะตั้งตัวทัน',
            ],
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
          logLines: ['ทีมปล่อยผู้รอดชีวิตไว้ข้างหลัง เดินหน้าได้เร็วขึ้น แต่ Bond และ Faith ลดลงอย่างชัดเจน'],
        );
    }
  }

  static bool _isChainEvent(String eventId) {
    switch (eventId) {
      case 'pilgrim_rest':
      case 'relic_echo':
      case 'vanguard_camp':
      case 'council_fire':
      case 'hidden_camp':
      case 'secret_bazaar':
      case 'vault_market':
      case 'living_forge':
      case 'ember_forge':
      case 'sanctum_echo':
      case 'dawn_vault':
        return true;
      default:
        return false;
    }
  }

  static TowerDecisionEvent? _buildChainEvent(String eventId) {
    switch (eventId) {
      case 'pilgrim_rest':
        return const TowerDecisionEvent(
          id: 'pilgrim_rest',
          title: 'ที่พักผู้แสวงบุญ',
          description:
              'เพราะคำสัตย์ก่อนหน้า เส้นทางลับนำทีมมาถึงศาลาพักสงบ คุณจะรับพรเพื่อความมั่นคง หรือเร่งเดินต่อก่อนทางจะปิด',
          options: [
            TowerDecisionOption(
              id: 'accept_blessing',
              title: 'รับพร',
              description:
                  'ฟื้นตัว เพิ่มศรัทธา และลดแรงกดดันของชั้นถัดไป แต่รางวัลจะไม่มากนัก',
            ),
            TowerDecisionOption(
              id: 'press_on',
              title: 'เดินหน้าต่อ',
              description:
                  'รักษาจังหวะของรอบนี้ไว้ ได้ผลตอบแทนดีกว่า แต่ฟื้นฟูได้น้อยลง',
            ),
          ],
        );
      case 'relic_echo':
        return const TowerDecisionEvent(
          id: 'relic_echo',
          title: 'เสียงสะท้อนของรีลิก',
          description:
              'รีลิกที่ชิงมาเริ่มปล่อยพลังไม่เสถียร คุณจะรีดมันออกมาเป็นแรงบุก หรือผนึกมันกลับไว้ก่อน',
          options: [
            TowerDecisionOption(
              id: 'channel_power',
              title: 'รีดพลังออกมา',
              description: 'เพิ่มแรงบุกและของดรอป แต่ชั้นถัดไปจะอันตรายขึ้น',
            ),
            TowerDecisionOption(
              id: 'seal_it_away',
              title: 'กดพลังไว้',
              description:
                  'เสถียรกว่า ได้ขวัญกำลังใจและลดแรงกดดัน แต่เสียผลตอบแทนบางส่วน',
            ),
          ],
        );
      case 'vanguard_camp':
        return const TowerDecisionEvent(
          id: 'vanguard_camp',
          title: 'ค่ายแนวหน้า',
          description:
              'ระหว่างบุกต่อพบจุดรวมพลเก่า คุณจะตั้งค่ายเพื่อคุมสถานการณ์ หรือใช้เป็นฐานส่งบุกทันที',
          options: [
            TowerDecisionOption(
              id: 'fortify_camp',
              title: 'ตั้งค่ายให้มั่นคง',
              description: 'ลดแรงกดดันและฟื้นแนวรบก่อนขึ้นต่อ',
            ),
            TowerDecisionOption(
              id: 'launch_assault',
              title: 'ใช้เป็นฐานบุก',
              description:
                  'แลกความนิ่งกับความเร็ว เพื่อเพิ่มรางวัลของชั้นถัดไป',
            ),
          ],
        );
      case 'council_fire':
        return const TowerDecisionEvent(
          id: 'council_fire',
          title: 'กองไฟประชุม',
          description:
              'หลังได้รับความไว้วางใจ ทีมรวมตัวเปิดใจรอบกองไฟ คุณจะฟังให้สุด หรือสรุปคำสั่งให้ชัด',
          options: [
            TowerDecisionOption(
              id: 'hear_them_out',
              title: 'ฟังความเห็นทุกคน',
              description:
                  'Bond เพิ่มแรงและคำแนะนำในอนาคตน่าเชื่อถือขึ้น แต่จังหวะการลุยจะช้าลงเล็กน้อย',
            ),
            TowerDecisionOption(
              id: 'take_command',
              title: 'ตัดสินใจทันที',
              description: 'คุมจังหวะและเร่งเกมได้ดี แต่ Bond จะขึ้นไม่มาก',
            ),
          ],
        );
      case 'hidden_camp':
        return const TowerDecisionEvent(
          id: 'hidden_camp',
          title: 'ค่ายลับ',
          description:
              'ผู้รอดชีวิตพาทีมมาถึงค่ายซ่อนที่มีเสบียงและบันทึกเส้นทาง คุณจะขนของกลับ หรือรับคนนำทางไปต่อ',
          options: [
            TowerDecisionOption(
              id: 'trade_supplies',
              title: 'ขนเสบียงกลับ',
              description:
                  'แปลงจุดนี้เป็นเสบียงและเงินสำหรับพักฟื้นทันที',
            ),
            TowerDecisionOption(
              id: 'recruit_guides',
              title: 'รับคนนำทาง',
              description:
                  'เน้นข้อมูลเส้นทางแทนการสะสมของ ทำให้ชั้นถัดไปง่ายขึ้น',
            ),
          ],
        );
      case 'secret_bazaar':
        return const TowerDecisionEvent(
          id: 'secret_bazaar',
          title: 'ตลาดลับกลางหอ',
          description:
              'คาราวานเงาเปิดร้านลับในโพรงหอ รับซื้อวัตถุดิบ รับแลกของหายาก และอาจพาไปยังโกดังชั้นใน',
          options: [
            TowerDecisionOption(
              id: 'broker_goods',
              title: 'เปิดโต๊ะเจรจา',
              description: 'เปลี่ยนของในคลังเป็นเงินหมุนพร้อมข่าวการค้า',
            ),
            TowerDecisionOption(
              id: 'buy_route_map',
              title: 'ซื้อแผนที่ลักลอบ',
              description: 'จ่ายเงินเพื่อให้เส้นทางถัดไปปลอดภัยและเก็บของได้คุ้มขึ้น',
            ),
          ],
        );
      case 'vault_market':
        return const TowerDecisionEvent(
          id: 'vault_market',
          title: 'โกดังใต้เงา',
          description:
              'ตลาดลับชั้นในเปิดประมูล relic และวัตถุดิบระดับสูง ทุกการตัดสินใจที่นี่แลกมาด้วยต้นทุนจริง',
          options: [
            TowerDecisionOption(
              id: 'acquire_relic',
              title: 'ทุ่มทุนซื้อ relic',
              description: 'ใช้เงินก้อนใหญ่เพื่อแลกของหายากและแรงส่งระยะยาว',
            ),
            TowerDecisionOption(
              id: 'cash_out',
              title: 'ขายของถอนทุน',
              description: 'เปลี่ยน loot เป็นเงินสดและทองทันที',
            ),
          ],
        );
      case 'living_forge':
        return const TowerDecisionEvent(
          id: 'living_forge',
          title: 'เตาหลอมมีชีวิต',
          description:
              'ช่างตีเหล็กเร่ปลุกเตาหลอมโบราณขึ้นมาอีกครั้ง เขายอมช่วยรีดศักยภาพอุปกรณ์หรือเปิดทางไปยังแกนเพลิงชั้นลึก',
          options: [
            TowerDecisionOption(
              id: 'reforge_arms',
              title: 'ตีอาวุธใหม่',
              description: 'เพิ่มพลังบุกของรอบถัดไปและเปิดทางสู่แกนเพลิง',
            ),
            TowerDecisionOption(
              id: 'temper_mail',
              title: 'ชุบเกราะ',
              description: 'ลดแรงปะทะและความเหนื่อยของทีมให้ลุยต่อได้นิ่งขึ้น',
            ),
          ],
        );
      case 'ember_forge':
        return const TowerDecisionEvent(
          id: 'ember_forge',
          title: 'แกนเพลิงโลหิต',
          description:
              'แกนเพลิงลึกสุดพร้อมแลกความร้อนกับของชิ้นเอก จะหลอมของหายากหรือเก็บประกายไฟไว้เป็นทุน',
          options: [
            TowerDecisionOption(
              id: 'shape_masterwork',
              title: 'หลอมของชิ้นเอก',
              description: 'แลกความเสี่ยงกับอุปกรณ์หายากที่ส่งผลต่อการลุยจริง',
            ),
            TowerDecisionOption(
              id: 'bank_the_flame',
              title: 'กักเก็บประกายไฟ',
              description: 'รับเงินและวัตถุดิบกลับฐานแบบปลอดภัยกว่า',
            ),
          ],
        );
      case 'sanctum_echo':
        return const TowerDecisionEvent(
          id: 'sanctum_echo',
          title: 'เสียงสะท้อนแห่งวิหาร',
          description:
              'ตะเกียงศักดิ์สิทธิ์พาทีมมาถึงวิหารซ้อนชั้น เสียงของนักบวชเก่ากำลังยื่นข้อเสนอที่แลกด้วยศรัทธา',
          options: [
            TowerDecisionOption(
              id: 'offer_light',
              title: 'ถวายแสง',
              description: 'ใช้ศรัทธาเพื่อเปิดปาฏิหาริย์และทางไปยังคลังชั้นลึก',
            ),
            TowerDecisionOption(
              id: 'record_prophecy',
              title: 'จดคำพยากรณ์',
              description: 'เก็บข้อมูลและคำแนะนำแทนการเร่งรับพลัง',
            ),
          ],
        );
      case 'dawn_vault':
        return const TowerDecisionEvent(
          id: 'dawn_vault',
          title: 'คลังรุ่งอรุณ',
          description:
              'ชั้นในสุดของวิหารเก็บ relic และเครื่องบรรณาการไว้ จะรับพระคุณเพื่อความมั่นคงหรือเก็บทรัพยากรกลับฐาน',
          options: [
            TowerDecisionOption(
              id: 'claim_grace',
              title: 'รับพระคุณ',
              description: 'ฟื้นตัว เสริมศรัทธา และรับของศักดิ์สิทธิ์',
            ),
            TowerDecisionOption(
              id: 'take_tithe',
              title: 'เก็บเครื่องบรรณาการ',
              description: 'รับทรัพยากรระดับสูงมากขึ้น แต่ศรัทธาทีมอาจสั่นคลอน',
            ),
          ],
        );
      default:
        return null;
    }
  }

  static void _queueChainEvent(PlayerData playerData, String eventId) {
    if (playerData.resolvedMajorChainEventIds.contains(eventId) ||
        playerData.pendingMajorChainEventIds.contains(eventId) ||
        playerData.pendingMajorChainEventId == eventId) {
      return;
    }
    playerData.pendingMajorChainEventIds = [
      ...playerData.pendingMajorChainEventIds,
      eventId,
    ];
    playerData.pendingMajorChainEventId = playerData.pendingMajorChainEventIds.first;
  }

  static void _resolveChainEvent(
    PlayerData playerData,
    String eventId, {
    required int floor,
  }) {
    playerData.pendingMajorChainEventIds =
        playerData.pendingMajorChainEventIds.where((id) => id != eventId).toList();
    playerData.pendingMajorChainEventId = playerData.pendingMajorChainEventIds.isEmpty
        ? null
        : playerData.pendingMajorChainEventIds.first;
    if (!playerData.resolvedMajorChainEventIds.contains(eventId)) {
      playerData.resolvedMajorChainEventIds = [
        ...playerData.resolvedMajorChainEventIds,
        eventId,
      ];
    }
    if (!playerData.resolvedMajorEventFloors.contains(floor)) {
      playerData.resolvedMajorEventFloors = [
        ...playerData.resolvedMajorEventFloors,
        floor,
      ];
    }
  }

  static TowerDecisionOutcome _applyChainDecision({
    required PlayerData playerData,
    required PartyModel party,
    required int floor,
    required TowerDecisionEvent event,
    required String optionId,
  }) {
    final emblemCount = _countEquippedItems(party, {'saints_emblem'});
    final guardGearCount = _countEquippedItems(party, {'tower_mail'});
    final strikeGearCount =
        _countEquippedItems(party, {'steel_blade', 'ranger_bow'});
    final compassCount = _countEquippedItems(party, {'wayfinder_compass'});
    final forgeHeartCount = _countEquippedItems(party, {'forge_heart'});
    final lanternCount = _countEquippedItems(party, {'sanctum_lantern'});
    _resolveChainEvent(playerData, event.id, floor: floor);

    switch (event.id) {
      case 'pilgrim_rest':
        if (optionId == 'accept_blessing') {
          if (lanternCount > 0) {
            _queueChainEvent(playerData, 'sanctum_echo');
          }
          for (final hero in party.members) {
            hero.adjustFaith(8 + (emblemCount > 0 ? 2 : 0));
            hero.currentStats.currentHp =
                min(hero.currentStats.maxHp, hero.currentStats.currentHp + 35);
            hero.currentStats.currentEng =
                min(hero.currentStats.maxEng, hero.currentStats.currentEng + 25);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: -25 - (emblemCount > 0 ? 10 : 0),
            rewardModifierDelta: -10,
            immediateItems: const [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: [
              'ทีมพักในศาลาสงบและรับพร ศรัทธากับสภาพร่างกายฟื้นขึ้นพร้อมกัน',
              if (emblemCount > 0)
                'ตราศรัทธาสะท้อนกับสถานที่ ทำให้พรลึกขึ้นกว่าปกติ',
            ],
          );
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -5,
          rewardModifierDelta: 25,
          immediateItems: [],
          silverDelta: 40,
          goldDelta: 0,
          logLines: [
            'ทีมฉวยจังหวะจากคำสัตย์เดิมและเร่งเดินต่อ ได้ผลตอบแทนเพิ่มเล็กน้อย',
          ],
        );
      case 'relic_echo':
        if (optionId == 'channel_power') {
          final shard = _itemReward('relic_shard');
          playerData.addItemRewards([shard]);
          for (final hero in party.members) {
            hero.baseStats.atk += 2;
            hero.currentStats.atk += 2;
            hero.adjustFaith(-6);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: 35,
            rewardModifierDelta: 35 + (strikeGearCount > 0 ? 10 : 0),
            immediateItems: [shard],
            silverDelta: strikeGearCount > 0 ? 60 : 30,
            goldDelta: 0,
            logLines: [
              'พลังสะท้อนของรีลิกถูกรีดออกมาเป็นแรงบุก ทำให้เส้นทางต่อจากนี้ปั่นป่วนขึ้น',
              if (strikeGearCount > 0)
                'อุปกรณ์สายบุกช่วยเปลี่ยนพลังสะท้อนเป็นเศษวัตถุดิบเพิ่ม',
            ],
          );
        }
        for (final hero in party.members) {
          hero.baseStats.def += 2;
          hero.currentStats.def += 2;
          hero.adjustBond(4);
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -20,
          rewardModifierDelta: -10,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: [
            'รีลิกถูกกดพลังกลับลง เส้นทางนิ่งขึ้นและทีมกลับมาเชื่อมั่นกันมากขึ้น',
          ],
        );
      case 'vanguard_camp':
        if (optionId == 'fortify_camp') {
          if (forgeHeartCount > 0) {
            _queueChainEvent(playerData, 'living_forge');
          }
          for (final hero in party.members) {
            hero.currentStats.currentHp =
                min(hero.currentStats.maxHp, hero.currentStats.currentHp + 20);
            hero.currentStats.currentEng = min(
              hero.currentStats.maxEng,
              hero.currentStats.currentEng + 20 + (guardGearCount > 0 ? 10 : 0),
            );
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: -30 - (guardGearCount > 0 ? 10 : 0),
            rewardModifierDelta: 0,
            immediateItems: const [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: [
              'ค่ายแนวหน้าถูกเสริมให้มั่นคงก่อนเคลื่อนพลต่อ ทำให้ชั้นถัดไปกดดันน้อยลง',
              if (guardGearCount > 0)
                'เกราะหอคอยช่วยให้ค่ายชั่วคราวกลายเป็นจุดตั้งรับที่ใช้งานได้จริง',
            ],
          );
        }
        if (forgeHeartCount > 0) {
          _queueChainEvent(playerData, 'living_forge');
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: 10,
          rewardModifierDelta: 30,
          immediateItems: [],
          silverDelta: 50,
          goldDelta: 0,
          logLines: [
            'ทีมใช้ค่ายเป็นฐานส่งบุกทันที จังหวะของรอบนี้เร็วขึ้นและได้ผลตอบแทนเพิ่ม',
          ],
        );
      case 'council_fire':
        if (optionId == 'hear_them_out') {
          for (final hero in party.members) {
            hero.adjustBond(12);
            hero.adjustFaith(4);
          }
          return const TowerDecisionOutcome(
            enemyModifierDelta: -10,
            rewardModifierDelta: 5,
            immediateItems: [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: [
              'ทุกคนได้พูดรอบกองไฟอย่างเปิดใจ ความเหนียวแน่นของทีมเพิ่มขึ้นมาก',
            ],
          );
        }
        for (final hero in party.members) {
          hero.adjustFaith(6);
          hero.adjustBond(4);
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -5,
          rewardModifierDelta: 20,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: [
            'หลังฟังความเห็น ผู้นำสรุปคำสั่งชัดเจน ทำให้ทีมรักษาจังหวะได้โดยไม่เสียการควบคุม',
          ],
        );
      case 'hidden_camp':
        if (optionId == 'trade_supplies') {
          if (compassCount > 0) {
            _queueChainEvent(playerData, 'secret_bazaar');
          }
          final ration = _itemReward('ration_pack', quantity: 2);
          playerData.addItemRewards([ration]);
          return TowerDecisionOutcome(
            enemyModifierDelta: 0,
            rewardModifierDelta: 0,
            immediateItems: [ration],
            silverDelta: 120,
            goldDelta: 0,
            logLines: const [
              'ค่ายลับถูกขนออกมาเป็นเสบียงและเงินพร้อมใช้สำหรับการพักฟื้น',
            ],
          );
        }
        if (compassCount > 0) {
          _queueChainEvent(playerData, 'secret_bazaar');
        }
        for (final hero in party.members) {
          hero.adjustBond(6);
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -20,
          rewardModifierDelta: 15,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: [
            'ผู้รอดชีวิตพาทีมหลบเส้นทางตายและเลือกจุดปะทะที่ได้เปรียบกว่า',
          ],
        );
      case 'secret_bazaar':
        if (optionId == 'broker_goods') {
          final soldValue = max(
            120,
            playerData.inventory.fold<int>(
                  0,
                  (sum, item) =>
                      sum + ((ItemUsageService.definitionFor(item.id)?.sellSilverValue ?? 8) * item.quantity),
                ) ~/
                5,
          );
          if (compassCount > 0) {
            _queueChainEvent(playerData, 'vault_market');
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: -15,
            rewardModifierDelta: 18,
            immediateItems: const [],
            silverDelta: soldValue,
            goldDelta: compassCount > 0 ? 1 : 0,
            logLines: [
              'ตลาดลับช่วยเปลี่ยนของในมือให้เป็นเงินหมุนและข่าวการค้า',
              if (compassCount > 0) 'พิกัดของโกดังใต้เงาถูกเปิดเผยต่อทีม',
            ],
          );
        }
        return TowerDecisionOutcome(
          enemyModifierDelta: -35,
          rewardModifierDelta: 25,
          immediateItems: const [],
          silverDelta: -(compassCount > 0 ? 120 : 180),
          goldDelta: 0,
          logLines: const [
            'ทีมซื้อแผนที่ลักลอบ ทำให้ทางข้างหน้าปลอดภัยและคุ้มกับการเก็บของขึ้น',
          ],
        );
      case 'vault_market':
        if (optionId == 'acquire_relic') {
          final reward = compassCount > 0
              ? _itemReward('wayfinder_compass')
              : _itemReward('relic_shard', quantity: 2);
          playerData.addItemRewards([reward]);
          return TowerDecisionOutcome(
            enemyModifierDelta: -10,
            rewardModifierDelta: 35,
            immediateItems: [reward],
            silverDelta: -220,
            goldDelta: 0,
            logLines: const [
              'โกดังใต้เงายอมปล่อยของหายากให้ทีมแลกกับต้นทุนก้อนใหญ่',
            ],
          );
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: 0,
          rewardModifierDelta: 10,
          immediateItems: [],
          silverDelta: 260,
          goldDelta: 1,
          logLines: ['ทีมขายของส่วนเกินในโกดังใต้เงาและถอนทุนกลับมา'],
        );
      case 'living_forge':
        if (optionId == 'reforge_arms') {
          if (forgeHeartCount > 0) {
            _queueChainEvent(playerData, 'ember_forge');
          }
          for (final hero in party.members) {
            hero.baseStats.atk += 2;
            hero.currentStats.atk += 2;
            hero.currentStats.currentEng =
                max(0, hero.currentStats.currentEng - 8);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: 5,
            rewardModifierDelta: 28,
            immediateItems: const [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: [
              'ช่างตีเหล็กรีดศักยภาพของอาวุธออกมาเต็มที่',
              if (forgeHeartCount > 0) 'Forge Heart ปลุกแกนเพลิงโลหิตในชั้นลึก',
            ],
          );
        }
        for (final hero in party.members) {
          hero.currentStats.currentHp =
              min(hero.currentStats.maxHp, hero.currentStats.currentHp + 18);
          hero.currentStats.currentEng =
              min(hero.currentStats.maxEng, hero.currentStats.currentEng + 18);
        }
        return const TowerDecisionOutcome(
          enemyModifierDelta: -40,
          rewardModifierDelta: 8,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: ['เกราะและอุปกรณ์ของทีมถูกชุบใหม่ ทำให้ชั้นถัดไปเบาลง'],
        );
      case 'ember_forge':
        if (optionId == 'shape_masterwork') {
          final reward = forgeHeartCount > 0
              ? _itemReward('forge_heart')
              : _itemReward('steel_blade');
          playerData.addItemRewards([reward]);
          return TowerDecisionOutcome(
            enemyModifierDelta: 12,
            rewardModifierDelta: 42,
            immediateItems: [reward],
            silverDelta: -80,
            goldDelta: 0,
            logLines: const [
              'แกนเพลิงถูกใช้หลอมของชิ้นเอก ทำให้ทีมได้อุปกรณ์ระดับสูง',
            ],
          );
        }
        final forgeLoot = [
          _itemReward('tower_ore_3'),
          _itemReward('iron_shard', quantity: 2),
        ];
        playerData.addItemRewards(forgeLoot);
        return TowerDecisionOutcome(
          enemyModifierDelta: -10,
          rewardModifierDelta: 18,
          immediateItems: forgeLoot,
          silverDelta: 140,
          goldDelta: 0,
          logLines: const [
            'ทีมกักเก็บประกายไฟไว้เป็นทุน ได้ทั้งเงินและวัตถุดิบกลับฐาน',
          ],
        );
      case 'sanctum_echo':
        if (optionId == 'offer_light') {
          if (lanternCount > 0) {
            _queueChainEvent(playerData, 'dawn_vault');
          }
          for (final hero in party.members) {
            hero.adjustFaith(10 + (lanternCount > 0 ? 3 : 0));
            hero.adjustBond(4);
            hero.currentStats.currentHp =
                min(hero.currentStats.maxHp, hero.currentStats.currentHp + 22);
            hero.currentStats.currentEng =
                min(hero.currentStats.maxEng, hero.currentStats.currentEng + 22);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: -30,
            rewardModifierDelta: 12,
            immediateItems: const [],
            silverDelta: 0,
            goldDelta: 0,
            logLines: [
              'ทีมถวายแสงต่อวิหารและได้รับการคุ้มครอง',
              if (lanternCount > 0) 'คลังรุ่งอรุณตอบสนองและเปิดเส้นทางต่อ',
            ],
          );
        }
        return TowerDecisionOutcome(
          enemyModifierDelta: -18,
          rewardModifierDelta: 20,
          immediateItems: const [],
          silverDelta: 60,
          goldDelta: 0,
          logLines: const [
            'คำพยากรณ์ถูกจดไว้เป็นคู่มือ ทำให้ทีมคุมรอบถัดไปได้ดีขึ้น',
          ],
        );
      case 'dawn_vault':
        if (optionId == 'claim_grace') {
          final reward = lanternCount > 0
              ? _itemReward('sanctum_lantern')
              : _itemReward('shrine_relic');
          playerData.addItemRewards([reward]);
          for (final hero in party.members) {
            hero.adjustFaith(6);
            hero.currentStats.currentHp =
                min(hero.currentStats.maxHp, hero.currentStats.currentHp + 28);
            hero.currentStats.currentEng =
                min(hero.currentStats.maxEng, hero.currentStats.currentEng + 24);
          }
          return TowerDecisionOutcome(
            enemyModifierDelta: -32,
            rewardModifierDelta: 14,
            immediateItems: [reward],
            silverDelta: 0,
            goldDelta: 1,
            logLines: const [
              'คลังรุ่งอรุณมอบพระคุณและของศักดิ์สิทธิ์ให้ทีม',
            ],
          );
        }
        final dawnLoot = [
          _itemReward('relic_shard', quantity: 2),
          _itemReward('tower_ore_3'),
        ];
        playerData.addItemRewards(dawnLoot);
        for (final hero in party.members) {
          hero.adjustFaith(-4);
        }
        return TowerDecisionOutcome(
          enemyModifierDelta: 6,
          rewardModifierDelta: 32,
          immediateItems: dawnLoot,
          silverDelta: 120,
          goldDelta: 1,
          logLines: const [
            'ทีมเก็บเครื่องบรรณาการจากคลังรุ่งอรุณกลับมา ได้ทรัพยากรระดับสูง',
          ],
        );
      default:
        return const TowerDecisionOutcome(
          enemyModifierDelta: 0,
          rewardModifierDelta: 0,
          immediateItems: [],
          silverDelta: 0,
          goldDelta: 0,
          logLines: ['ไม่มีผลพิเศษจากเหตุการณ์ต่อเนื่องนี้'],
        );
    }
  }

  static void _recordMajorEvent(
    PlayerData playerData,
    String eventId, {
    required int floor,
  }) {
    final updatedIds = [
      ...playerData.recentMajorEventIds.where((id) => id != eventId),
      eventId,
    ];
    if (updatedIds.length > 3) {
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

    var maxDuration = Duration.zero;
    for (final hero in party.members) {
      final duration = _heroRecoveryDuration(
        hero,
        clearedFloors: clearedFloors,
      );
      hero.startRecoveryCooldown(duration);
      if (duration > maxDuration) {
        maxDuration = duration;
      }
    }

    party.status = maxDuration > Duration.zero ? 'recovering' : 'idle';
    return maxDuration;
  }

  static void refreshRecoveryState(PartyModel party) {
    var hasRecoveringMember = false;
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

    final totalFatigue =
        party.members.fold<int>(0, (sum, hero) => sum + _fatigueScore(hero));
    final remainingMinutes = party.members.fold<int>(
      0,
      (sum, hero) => sum + hero.recoveryCooldownRemaining.inMinutes,
    );

    return (100 +
            (party.members.length * 30) +
            (totalFatigue ~/ 6) +
            (remainingMinutes * 3))
        .clamp(120, 1800);
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

  static int _countClasses(PartyModel party, Set<String> classIds) {
    return party.members
        .where((hero) => classIds.contains(hero.currentClass))
        .length;
  }

  static int _countEquippedItems(PartyModel party, Set<String> itemIds) {
    return party.members
        .map((hero) => hero.equippedItemIds.values)
        .expand((ids) => ids)
        .where(itemIds.contains)
        .length;
  }

  static String _pickVariant(String seed, List<String> options) {
    if (options.isEmpty) {
      return '';
    }
    final score = seed.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return options[score % options.length];
  }

  static double _heroCombatPower(HeroModel hero) {
    final stats = hero.currentStats;
    return (stats.maxHp * 0.35) +
        (stats.atk * 4.4) +
        (stats.def * 3.6) +
        (stats.spd * 2.4) +
        (stats.maxEng * 1.3) +
        (stats.luk * 1.4);
  }

  static int _heroEquipmentBattlePower(HeroModel hero) {
    final weaponId = hero.equippedItemIds[EquipmentSlot.weapon.name];
    final armorId = hero.equippedItemIds[EquipmentSlot.armor.name];
    final relicId = hero.equippedItemIds[EquipmentSlot.relic.name];
    var bonus = 0;

    switch (weaponId) {
      case 'steel_blade':
        bonus += 22;
        break;
      case 'ranger_bow':
        bonus += 18;
        break;
    }

    if (armorId == 'tower_mail') {
      bonus += 10;
    }

    switch (relicId) {
      case 'saints_emblem':
        bonus += 12;
        break;
      case 'wayfinder_compass':
        bonus += 16;
        break;
      case 'forge_heart':
        bonus += 24;
        break;
      case 'sanctum_lantern':
        bonus += 14;
        break;
    }

    return bonus + (hero.equippedItemBonuses.length * 2);
  }

  static int _heroEquipmentShield(HeroModel hero) {
    final armorId = hero.equippedItemIds[EquipmentSlot.armor.name];
    final relicId = hero.equippedItemIds[EquipmentSlot.relic.name];
    var shield = 0;

    if (armorId == 'tower_mail') {
      shield += 24;
    }

    switch (relicId) {
      case 'saints_emblem':
        shield += 8;
        break;
      case 'forge_heart':
        shield += 14;
        break;
      case 'sanctum_lantern':
        shield += 12;
        break;
    }

    return shield + (hero.currentStats.def ~/ 6);
  }

  static int _heroEquipmentRewardBonus(HeroModel hero) {
    final weaponId = hero.equippedItemIds[EquipmentSlot.weapon.name];
    final relicId = hero.equippedItemIds[EquipmentSlot.relic.name];
    var bonus = 0;

    if (weaponId == 'ranger_bow') {
      bonus += 8;
    }
    if (weaponId == 'steel_blade') {
      bonus += 6;
    }

    switch (relicId) {
      case 'saints_emblem':
        bonus += 6;
        break;
      case 'wayfinder_compass':
        bonus += 14;
        break;
      case 'forge_heart':
        bonus += 8;
        break;
      case 'sanctum_lantern':
        bonus += 10;
        break;
    }

    return bonus + max(0, hero.currentStats.luk ~/ 8);
  }

  static double _heroEquipmentFatigueFactor(HeroModel hero) {
    final armorId = hero.equippedItemIds[EquipmentSlot.armor.name];
    final relicId = hero.equippedItemIds[EquipmentSlot.relic.name];
    var factor = 1.0;

    if (armorId == 'tower_mail') {
      factor -= 0.08;
    }
    if (relicId == 'saints_emblem') {
      factor -= 0.05;
    }
    if (relicId == 'forge_heart') {
      factor -= 0.04;
    }
    if (relicId == 'sanctum_lantern') {
      factor -= 0.06;
    }

    return factor.clamp(0.72, 1.0);
  }

  static int _heroEnergyLoss(
    HeroModel hero, {
    required int floor,
    required int enemyPower,
    required bool succeeded,
    required double combatShare,
    required String formation,
  }) {
    final stats = hero.currentStats;
    final endurance = stats.maxEng + (stats.def * 2) + stats.spd;
    final enduranceReduction = min(0.38, endurance / (enemyPower + 260));
    final exhaustionPenalty = stats.maxEng <= 0
        ? 0.0
        : (1 - (stats.currentEng / stats.maxEng)) * 0.18;
    final base = (10 + (floor * 1.7) + (enemyPower / 140)) *
        (succeeded ? 0.92 : 1.28);
    final contributionFactor = 0.75 + (combatShare * 0.8);
    final formationFactor = _formationEnergyFactor(formation);
    final roleFactor = _roleEnergyFactor(hero.currentClass);
    final equipmentFactor = _heroEquipmentFatigueFactor(hero);
    final loss = (base *
            formationFactor *
            roleFactor *
            contributionFactor *
            equipmentFactor *
            (1.18 - enduranceReduction + exhaustionPenalty))
        .round();
    return loss.clamp(succeeded ? 8 : 12, succeeded ? 42 : 58);
  }

  static int _heroHpLoss(
    HeroModel hero, {
    required int floor,
    required int enemyPower,
    required bool succeeded,
    required double combatShare,
    required String formation,
  }) {
    final stats = hero.currentStats;
    final resilience =
        (stats.def * 2.4) + (stats.maxHp / 9) + stats.spd + (hero.bond / 2);
    final mitigation = min(0.42, resilience / (enemyPower + 320));
    final exhaustionPenalty = stats.maxEng <= 0
        ? 0.0
        : (1 - (stats.currentEng / stats.maxEng)) * 0.22;
    final base = (7 + (floor * 1.35) + (enemyPower / 180)) *
        (succeeded ? 0.82 : 1.45);
    final contributionFactor = 0.70 + (combatShare * 0.75);
    final formationFactor = _formationHpFactor(formation);
    final roleFactor = _roleHpFactor(hero.currentClass);
    final equipmentFactor = _heroEquipmentFatigueFactor(hero);
    final loss = (base *
            formationFactor *
            roleFactor *
            contributionFactor *
            equipmentFactor *
            (1.20 - mitigation + exhaustionPenalty))
        .round();
    return loss.clamp(succeeded ? 5 : 10, succeeded ? 36 : 60);
  }

  static int _fatigueScore(HeroModel hero) {
    final hpLoss = max(0, hero.currentStats.maxHp - hero.currentStats.currentHp);
    final engLoss = max(0, hero.currentStats.maxEng - hero.currentStats.currentEng);
    final hpRatio = hero.currentStats.maxHp <= 0
        ? 0
        : (hpLoss * 100) ~/ hero.currentStats.maxHp;
    final engRatio = hero.currentStats.maxEng <= 0
        ? 0
        : (engLoss * 100) ~/ hero.currentStats.maxEng;
    return hpLoss + (engLoss * 2) + hpRatio + engRatio;
  }

  static Duration _heroRecoveryDuration(
    HeroModel hero, {
    required int clearedFloors,
  }) {
    final fatigue = _fatigueScore(hero);
    if (fatigue <= 0 && clearedFloors <= 0) {
      return Duration.zero;
    }

    final recoveryStat = hero.currentStats.def +
        hero.currentStats.spd +
        (hero.currentStats.maxEng ~/ 5);
    final recoveryFactor =
        1.25 - min(0.45, recoveryStat / (260 + (hero.level * 6)));
    final minutes =
        ((6 + (clearedFloors * 4) + (fatigue / 18)) * recoveryFactor)
            .round()
            .clamp(6, 240);
    return Duration(minutes: minutes);
  }

  static double _formationEnergyFactor(String formation) {
    switch (formation) {
      case 'assault':
        return 1.14;
      case 'bulwark':
        return 0.90;
      case 'swift':
        return 1.02;
      default:
        return 1.0;
    }
  }

  static double _formationHpFactor(String formation) {
    switch (formation) {
      case 'assault':
        return 1.08;
      case 'bulwark':
        return 0.88;
      case 'swift':
        return 0.92;
      default:
        return 1.0;
    }
  }

  static double _roleEnergyFactor(String classId) {
    if (_scoutClasses.contains(classId)) {
      return 1.08;
    }
    if (_holyClasses.contains(classId)) {
      return 0.95;
    }
    if (_frontlineClasses.contains(classId)) {
      return 1.02;
    }
    return 1.0;
  }

  static double _roleHpFactor(String classId) {
    if (_frontlineClasses.contains(classId)) {
      return 1.12;
    }
    if (_scoutClasses.contains(classId)) {
      return 0.88;
    }
    if (_holyClasses.contains(classId)) {
      return 0.92;
    }
    return 1.0;
  }

  static ItemModel _itemReward(String itemId, {int quantity = 1}) {
    final definition = ItemUsageService.definitionFor(itemId);
    if (definition != null) {
      return definition.toItemModel(quantity: quantity);
    }

    return ItemModel(
      id: itemId,
      name: itemId,
      type: ItemType.material,
      rarity: 1,
      quantity: quantity,
    );
  }

  static int _formationBonus(PartyModel party) {
    switch (party.formation) {
      case 'assault':
        return party.members.fold<int>(
              0,
              (sum, hero) => sum + hero.currentStats.atk,
            ) ~/
            2;
      case 'bulwark':
        return party.members.fold<int>(
              0,
              (sum, hero) => sum + hero.currentStats.def,
            ) ~/
            2;
      case 'swift':
        return party.members.fold<int>(
              0,
              (sum, hero) => sum + hero.currentStats.spd + hero.currentStats.luk,
            ) ~/
            2;
      default:
        return party.members.fold<int>(
              0,
              (sum, hero) => sum + hero.currentStats.luk,
            ) ~/
            3;
    }
  }

  static int _classSynergyBonus(PartyModel party) {
    var bonus = 0;
    for (final hero in party.members) {
      switch (hero.currentClass) {
        case 'knight':
        case 'warden':
          bonus += 22;
          break;
        case 'warbringer':
          bonus += 26;
          break;
        case 'ranger':
          bonus += 18;
          break;
        case 'shadowblade':
          bonus += 20;
          break;
        case 'oracle':
        case 'saint':
          bonus += 16;
          break;
        default:
          break;
      }
    }
    return bonus;
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

    rewards.add(_itemReward('tower_ore_$rarity', quantity: 1 + _random.nextInt(2)));

    final commonMaterials = <ItemModel>[
      _itemReward('cloth_scrap', quantity: 1 + _random.nextInt(2)),
      _itemReward('iron_shard', quantity: 1 + _random.nextInt(2)),
      _itemReward('monster_bone', quantity: 1 + _random.nextInt(2)),
      _itemReward('beast_meat', quantity: 1 + _random.nextInt(3)),
    ];
    rewards.add(commonMaterials[_random.nextInt(commonMaterials.length)]);

    if (_random.nextDouble() > 0.55) {
      rewards.add(_itemReward('ration_pack'));
    }

    if (adjustedFloor >= 5 && _random.nextDouble() > 0.48) {
      final extraMaterials = <ItemModel>[
        _itemReward('cloth_scrap', quantity: 2),
        _itemReward('iron_shard', quantity: 2),
        _itemReward('monster_bone', quantity: 2),
        _itemReward('beast_meat', quantity: 2),
      ];
      rewards.add(extraMaterials[_random.nextInt(extraMaterials.length)]);
    }

    if (adjustedFloor >= 10 && _random.nextDouble() > 0.82) {
      rewards.add(_itemReward('class_trial_seal'));
    }

    if (adjustedFloor >= 6 && _random.nextDouble() > 0.76) {
      final utilityItems = <ItemModel>[
        _itemReward('battle_tonic'),
        _itemReward('guard_tonic'),
        _itemReward('swift_tonic'),
        _itemReward('trust_token'),
        _itemReward('prayer_candle'),
      ];
      rewards.add(utilityItems[_random.nextInt(utilityItems.length)]);
    }

    if (adjustedFloor >= 8 && _random.nextDouble() > 0.78) {
      rewards.add(_itemReward('survivor_cache'));
    }

    if (adjustedFloor >= 8 && _random.nextDouble() > 0.74) {
      final equipmentRewards = <ItemModel>[
        _itemReward('steel_blade'),
        _itemReward('ranger_bow'),
        _itemReward('tower_mail'),
        _itemReward('saints_emblem'),
      ];
      rewards.add(equipmentRewards[_random.nextInt(equipmentRewards.length)]);
    }

    if (rarity >= 3 && _random.nextDouble() > 0.7) {
      rewards.add(
        _random.nextBool()
            ? _itemReward('shrine_relic')
            : _itemReward('relic_shard'),
      );
    }

    if (adjustedFloor >= 12 && _random.nextDouble() > 0.92) {
      final relicRewards = <ItemModel>[
        _itemReward('wayfinder_compass'),
        _itemReward('forge_heart'),
        _itemReward('sanctum_lantern'),
      ];
      rewards.add(relicRewards[_random.nextInt(relicRewards.length)]);
    }

    return rewards;
  }
}
