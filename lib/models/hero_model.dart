import 'dart:math';

import '../utils/leveling_policy.dart';
import 'hero_stats.dart';
import 'item_model.dart';

class HeroModel {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String backgroundStory;

  int level;
  int currentExp;
  int totalExpEarned;
  int totalTowerFloorsCleared;
  int totalItemsUsed;
  HeroStats baseStats;
  late HeroStats currentStats;
  HeroStats classBonusStats;

  Map<String, double> aptitudes;

  bool isAlive;
  bool isInTower;
  int bond;
  int faith;
  String currentClass;
  List<String> unlockedClasses;
  List<String> activeClassQuestIds;
  List<String> completedClassQuestIds;
  Map<String, String> equippedItemIds;
  Map<String, HeroStats> equippedItemBonuses;
  Map<String, int> equipmentUpgradeLevels;
  int maxMana;
  int currentMana;
  String bodyCondition;
  List<String> statusEffects;
  Map<String, int> skillCooldowns;
  String? currentAction;
  String? currentTarget;
  int? recoveryReadyAtEpochMs;

  HeroModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.backgroundStory,
    this.level = 1,
    this.currentExp = 0,
    this.totalExpEarned = 0,
    this.totalTowerFloorsCleared = 0,
    this.totalItemsUsed = 0,
    required this.baseStats,
    HeroStats? currentStats,
    HeroStats? classBonusStats,
    required this.aptitudes,
    this.isAlive = true,
    this.isInTower = false,
    this.bond = 20,
    this.faith = 20,
    String? currentClass,
    List<String>? unlockedClasses,
    List<String>? activeClassQuestIds,
    List<String>? completedClassQuestIds,
    Map<String, String>? equippedItemIds,
    Map<String, HeroStats>? equippedItemBonuses,
    Map<String, int>? equipmentUpgradeLevels,
    int? maxMana,
    int? currentMana,
    String? bodyCondition,
    List<String>? statusEffects,
    Map<String, int>? skillCooldowns,
    this.currentAction,
    this.currentTarget,
    this.recoveryReadyAtEpochMs,
  }) : currentStats = currentStats ?? baseStats.clone(),
       classBonusStats = classBonusStats?.clone() ?? HeroStats.zero(),
       currentClass = currentClass ?? 'novice',
       unlockedClasses = List<String>.from(
         unlockedClasses ?? [currentClass ?? 'novice'],
       ),
       activeClassQuestIds = List<String>.from(activeClassQuestIds ?? const []),
       completedClassQuestIds = List<String>.from(
         completedClassQuestIds ?? const [],
       ),
       equippedItemIds = Map<String, String>.from(equippedItemIds ?? const {}),
       equippedItemBonuses = Map<String, HeroStats>.fromEntries(
         (equippedItemBonuses ?? const {}).entries.map(
           (entry) => MapEntry(entry.key, entry.value.clone()),
         ),
       ),
       equipmentUpgradeLevels = Map<String, int>.from(
         equipmentUpgradeLevels ?? const {},
       ),
       maxMana =
           maxMana ??
           _defaultMaxMana(baseStats, level, currentClass ?? 'novice'),
       currentMana =
           currentMana ??
           (maxMana ??
               _defaultMaxMana(baseStats, level, currentClass ?? 'novice')),
       bodyCondition = bodyCondition ?? 'healthy',
       statusEffects = List<String>.from(statusEffects ?? const []),
       skillCooldowns = Map<String, int>.from(skillCooldowns ?? const {}) {
    if (!this.unlockedClasses.contains(this.currentClass)) {
      this.unlockedClasses.add(this.currentClass);
    }
  }

  int get rarity {
    if (level >= 1280) return 5;
    if (level >= 320) return 4;
    if (level >= 80) return 3;
    if (level >= 20) return 2;
    return 1;
  }

  String get rarityTitle {
    switch (rarity) {
      case 5:
        return 'Divine Warrior';
      case 4:
        return 'Legendary';
      case 3:
        return 'Epic';
      case 2:
        return 'Rare';
      default:
        return 'Common';
    }
  }

  String get currentJobRole {
    if (aptitudes.isEmpty) {
      return 'Novice';
    }

    final sortedEntries = aptitudes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  double get primaryAptitudeValue {
    if (aptitudes.isEmpty) {
      return 0.0;
    }

    final sortedEntries = aptitudes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.value;
  }

  String get experienceStage {
    if (level >= 80 || totalExpEarned >= 250000) return 'Mythic';
    if (level >= 40 || totalExpEarned >= 100000) return 'Elite';
    if (level >= 20 || totalExpEarned >= 25000) return 'Veteran';
    if (level >= 10 || totalExpEarned >= 5000) return 'Seasoned';
    return 'Recruit';
  }

  Duration get recoveryCooldownRemaining {
    final readyAt = recoveryReadyAtEpochMs;
    if (readyAt == null) {
      return Duration.zero;
    }

    final remainingMs = readyAt - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: remainingMs);
  }

  bool get isRecovering => recoveryCooldownRemaining > Duration.zero;
  bool get isPoisoned => statusEffects.contains('poisoned');
  bool get isExhausted => statusEffects.contains('exhausted');
  bool get isWounded => statusEffects.contains('wounded');

  int expToNextLevel() => LevelingPolicy.expRequiredForNextLevel(level);

  void startRecoveryCooldown(Duration duration) {
    if (duration <= Duration.zero) {
      recoveryReadyAtEpochMs = null;
      return;
    }

    recoveryReadyAtEpochMs = DateTime.now()
        .add(duration)
        .millisecondsSinceEpoch;
  }

  void reduceRecoveryCooldown(Duration duration) {
    final readyAt = recoveryReadyAtEpochMs;
    if (readyAt == null) {
      return;
    }

    final updatedReadyAt = readyAt - duration.inMilliseconds;
    if (updatedReadyAt <= DateTime.now().millisecondsSinceEpoch) {
      recoveryReadyAtEpochMs = null;
      return;
    }
    recoveryReadyAtEpochMs = updatedReadyAt;
  }

  void fullyRecover() {
    currentStats.currentHp = currentStats.maxHp;
    currentStats.currentEng = currentStats.maxEng;
    currentMana = maxMana;
    statusEffects = statusEffects
        .where((effect) => effect != 'exhausted' && effect != 'wounded')
        .toList();
    bodyCondition = 'healthy';
    recoveryReadyAtEpochMs = null;
  }

  void changeClass(String nextClass, HeroStats nextBonus) {
    _applyClassBonus(classBonusStats, direction: -1);
    classBonusStats = nextBonus.clone();
    _applyClassBonus(classBonusStats, direction: 1);
    currentClass = nextClass;
    maxMana = _defaultMaxMana(currentStats, level, nextClass);
    currentMana = min(currentMana, maxMana);
    if (!unlockedClasses.contains(nextClass)) {
      unlockedClasses = [...unlockedClasses, nextClass];
    }
  }

  void restoreMana(int amount) {
    currentMana = (currentMana + amount).clamp(0, maxMana);
  }

  bool spendMana(int amount) {
    if (currentMana < amount) {
      return false;
    }
    currentMana -= amount;
    return true;
  }

  void tickSkillCooldowns() {
    final next = <String, int>{};
    for (final entry in skillCooldowns.entries) {
      final value = entry.value - 1;
      if (value > 0) {
        next[entry.key] = value;
      }
    }
    skillCooldowns = next;
  }

  int skillCooldownFor(String skillId) => skillCooldowns[skillId] ?? 0;

  void setSkillCooldown(String skillId, int turns) {
    if (turns <= 0) {
      skillCooldowns = Map<String, int>.from(skillCooldowns)..remove(skillId);
      return;
    }
    skillCooldowns = {...skillCooldowns, skillId: turns};
  }

  void addStatusEffect(String effect) {
    if (statusEffects.contains(effect)) {
      return;
    }
    statusEffects = [...statusEffects, effect];
    _refreshBodyCondition();
  }

  void removeStatusEffect(String effect) {
    statusEffects = statusEffects.where((value) => value != effect).toList();
    _refreshBodyCondition();
  }

  void setAction(String action, {String? target}) {
    currentAction = action;
    currentTarget = target;
  }

  void clearAction() {
    currentAction = null;
    currentTarget = null;
  }

  void refreshBodyCondition() {
    _refreshBodyCondition();
  }

  void startClassQuest(String questId) {
    if (activeClassQuestIds.contains(questId) ||
        completedClassQuestIds.contains(questId)) {
      return;
    }
    activeClassQuestIds = [...activeClassQuestIds, questId];
  }

  void completeClassQuest(String questId) {
    if (!completedClassQuestIds.contains(questId)) {
      completedClassQuestIds = [...completedClassQuestIds, questId];
    }
    activeClassQuestIds = activeClassQuestIds
        .where((entry) => entry != questId)
        .toList();
  }

  String? equippedItemIdForSlot(EquipmentSlot slot) {
    return equippedItemIds[slot.name];
  }

  void equipItem(ItemModel item) {
    final slot = item.equipmentSlot;
    final bonus = item.statBonus;
    if (slot == null || bonus == null) {
      return;
    }

    final existingBonus = equippedItemBonuses[slot.name];
    if (existingBonus != null) {
      _applyClassBonus(existingBonus, direction: -1);
    }

    equippedItemIds = {...equippedItemIds, slot.name: item.id};
    equippedItemBonuses = {...equippedItemBonuses, slot.name: bonus.clone()};
    equipmentUpgradeLevels = {...equipmentUpgradeLevels, slot.name: 0};
    _applyClassBonus(bonus, direction: 1);
  }

  int equipmentUpgradeLevelForSlot(EquipmentSlot slot) {
    return equipmentUpgradeLevels[slot.name] ?? 0;
  }

  void reforgeEquippedItem(
    EquipmentSlot slot,
    HeroStats nextBonus, {
    int? upgradeLevel,
  }) {
    final existingBonus = equippedItemBonuses[slot.name];
    if (existingBonus == null) {
      return;
    }

    _applyClassBonus(existingBonus, direction: -1);
    equippedItemBonuses = {
      ...equippedItemBonuses,
      slot.name: nextBonus.clone(),
    };
    if (upgradeLevel != null) {
      equipmentUpgradeLevels = {
        ...equipmentUpgradeLevels,
        slot.name: upgradeLevel,
      };
    }
    _applyClassBonus(nextBonus, direction: 1);
  }

  void unequipSlot(EquipmentSlot slot) {
    final existingBonus = equippedItemBonuses[slot.name];
    if (existingBonus == null) {
      return;
    }

    _applyClassBonus(existingBonus, direction: -1);
    final nextIds = Map<String, String>.from(equippedItemIds)
      ..remove(slot.name);
    final nextBonuses = Map<String, HeroStats>.from(equippedItemBonuses)
      ..remove(slot.name);
    final nextUpgradeLevels = Map<String, int>.from(equipmentUpgradeLevels)
      ..remove(slot.name);
    equippedItemIds = nextIds;
    equippedItemBonuses = nextBonuses;
    equipmentUpgradeLevels = nextUpgradeLevels;
  }

  @override
  String toString() {
    return '$name (Lv.$level $rarityTitle) - Job: $currentJobRole / Class: $currentClass\n'
        'Aptitudes: $aptitudes';
  }

  int gainExp(int amount) {
    if (amount <= 0 || level >= LevelingPolicy.maxLevel) {
      return 0;
    }

    totalExpEarned += amount;
    currentExp += amount;
    int levelsGained = 0;

    while (level < LevelingPolicy.maxLevel &&
        currentExp >= LevelingPolicy.expRequiredForNextLevel(level)) {
      currentExp -= LevelingPolicy.expRequiredForNextLevel(level);
      level += 1;
      levelsGained += 1;
      _applyLevelUp();
    }

    return levelsGained;
  }

  void _applyLevelUp() {
    final hpGain = 10 + rarity;
    final atkGain = 2 + (rarity >= 3 ? 1 : 0);
    final defGain = 2 + (rarity >= 4 ? 1 : 0);
    final spdGain = 1 + (rarity >= 5 ? 1 : 0);
    final lukGain = level % 10 == 0 ? 1 : 0;

    baseStats.maxHp += hpGain;
    baseStats.currentHp += hpGain;
    baseStats.atk += atkGain;
    baseStats.def += defGain;
    baseStats.spd += spdGain;
    baseStats.luk += lukGain;

    currentStats.maxHp += hpGain;
    currentStats.currentHp += hpGain;
    currentStats.atk += atkGain;
    currentStats.def += defGain;
    currentStats.spd += spdGain;
    currentStats.luk += lukGain;
    maxMana +=
        2 +
        (currentClass == 'acolyte' ||
                currentClass == 'oracle' ||
                currentClass == 'saint'
            ? 1
            : 0);
    currentMana = min(maxMana, currentMana + 3);
  }

  void adjustBond(int delta) {
    bond = (bond + delta).clamp(0, 100);
  }

  void adjustFaith(int delta) {
    faith = (faith + delta).clamp(0, 100);
  }

  void _refreshBodyCondition() {
    final hpRatio = currentStats.maxHp <= 0
        ? 1.0
        : currentStats.currentHp / currentStats.maxHp;
    final engRatio = currentStats.maxEng <= 0
        ? 1.0
        : currentStats.currentEng / currentStats.maxEng;

    if (statusEffects.contains('poisoned')) {
      bodyCondition = 'poisoned';
      return;
    }
    if (hpRatio < 0.35) {
      bodyCondition = 'critical';
      if (!statusEffects.contains('wounded')) {
        statusEffects = [...statusEffects, 'wounded'];
      }
      return;
    }
    if (engRatio < 0.25) {
      bodyCondition = 'exhausted';
      if (!statusEffects.contains('exhausted')) {
        statusEffects = [...statusEffects, 'exhausted'];
      }
      return;
    }

    statusEffects = statusEffects
        .where((effect) => effect != 'wounded' && effect != 'exhausted')
        .toList();
    bodyCondition = hpRatio < 0.65 ? 'strained' : 'healthy';
  }

  static int _defaultMaxMana(HeroStats stats, int level, String classId) {
    var mana = 18 + (level * 2) + (stats.maxEng ~/ 6) + (stats.luk ~/ 2);
    if (classId == 'acolyte' || classId == 'oracle' || classId == 'saint') {
      mana += 18;
    } else if (classId == 'shadowblade' || classId == 'ranger') {
      mana += 6;
    }
    return max(12, mana);
  }

  void _applyClassBonus(HeroStats bonus, {required int direction}) {
    if (direction == 0) {
      return;
    }

    baseStats.maxHp = max(1, baseStats.maxHp + (bonus.maxHp * direction));
    currentStats.maxHp = max(1, currentStats.maxHp + (bonus.maxHp * direction));
    baseStats.atk = max(1, baseStats.atk + (bonus.atk * direction));
    currentStats.atk = max(1, currentStats.atk + (bonus.atk * direction));
    baseStats.def = max(1, baseStats.def + (bonus.def * direction));
    currentStats.def = max(1, currentStats.def + (bonus.def * direction));
    baseStats.spd = max(1, baseStats.spd + (bonus.spd * direction));
    currentStats.spd = max(1, currentStats.spd + (bonus.spd * direction));
    baseStats.maxEng = max(1, baseStats.maxEng + (bonus.maxEng * direction));
    currentStats.maxEng = max(
      1,
      currentStats.maxEng + (bonus.maxEng * direction),
    );
    baseStats.luk = max(0, baseStats.luk + (bonus.luk * direction));
    currentStats.luk = max(0, currentStats.luk + (bonus.luk * direction));

    if (direction > 0) {
      baseStats.currentHp = min(
        baseStats.maxHp,
        baseStats.currentHp + bonus.maxHp,
      );
      currentStats.currentHp = min(
        currentStats.maxHp,
        currentStats.currentHp + bonus.maxHp,
      );
      baseStats.currentEng = min(
        baseStats.maxEng,
        baseStats.currentEng + bonus.maxEng,
      );
      currentStats.currentEng = min(
        currentStats.maxEng,
        currentStats.currentEng + bonus.maxEng,
      );
    } else {
      baseStats.currentHp = min(baseStats.currentHp, baseStats.maxHp);
      currentStats.currentHp = min(currentStats.currentHp, currentStats.maxHp);
      baseStats.currentEng = min(baseStats.currentEng, baseStats.maxEng);
      currentStats.currentEng = min(
        currentStats.currentEng,
        currentStats.maxEng,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'backgroundStory': backgroundStory,
      'level': level,
      'currentExp': currentExp,
      'totalExpEarned': totalExpEarned,
      'totalTowerFloorsCleared': totalTowerFloorsCleared,
      'totalItemsUsed': totalItemsUsed,
      'baseStats': baseStats.toMap(),
      'currentStats': currentStats.toMap(),
      'classBonusStats': classBonusStats.toMap(),
      'aptitudes': aptitudes,
      'isAlive': isAlive,
      'isInTower': isInTower,
      'bond': bond,
      'faith': faith,
      'currentClass': currentClass,
      'unlockedClasses': unlockedClasses,
      'activeClassQuestIds': activeClassQuestIds,
      'completedClassQuestIds': completedClassQuestIds,
      'equippedItemIds': equippedItemIds,
      'equippedItemBonuses': equippedItemBonuses.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'equipmentUpgradeLevels': equipmentUpgradeLevels,
      'maxMana': maxMana,
      'currentMana': currentMana,
      'bodyCondition': bodyCondition,
      'statusEffects': statusEffects,
      'skillCooldowns': skillCooldowns,
      'currentAction': currentAction,
      'currentTarget': currentTarget,
      'recoveryReadyAtEpochMs': recoveryReadyAtEpochMs,
    };
  }

  factory HeroModel.fromMap(Map<String, dynamic> map) {
    final aptitudesMap = Map<String, dynamic>.from(map['aptitudes'] as Map);

    return HeroModel(
      id: map['id'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      age: map['age'] as int,
      backgroundStory: map['backgroundStory'] as String,
      level: map['level'] as int,
      currentExp: map['currentExp'] as int,
      totalExpEarned: map['totalExpEarned'] as int? ?? 0,
      totalTowerFloorsCleared: map['totalTowerFloorsCleared'] as int? ?? 0,
      totalItemsUsed: map['totalItemsUsed'] as int? ?? 0,
      baseStats: HeroStats.fromMap(
        Map<String, dynamic>.from(map['baseStats'] as Map),
      ),
      currentStats: HeroStats.fromMap(
        Map<String, dynamic>.from(map['currentStats'] as Map),
      ),
      classBonusStats: map['classBonusStats'] == null
          ? HeroStats.zero()
          : HeroStats.fromMap(
              Map<String, dynamic>.from(map['classBonusStats'] as Map),
            ),
      aptitudes: aptitudesMap.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      isAlive: map['isAlive'] as bool? ?? true,
      isInTower: map['isInTower'] as bool? ?? false,
      bond: map['bond'] as int? ?? 20,
      faith: map['faith'] as int? ?? 20,
      currentClass: map['currentClass'] as String? ?? 'novice',
      unlockedClasses:
          (map['unlockedClasses'] as List<dynamic>? ?? const ['novice'])
              .map((value) => value.toString())
              .toList(),
      activeClassQuestIds:
          (map['activeClassQuestIds'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
      completedClassQuestIds:
          (map['completedClassQuestIds'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
      equippedItemIds: Map<String, String>.from(
        (map['equippedItemIds'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const {},
      ),
      equippedItemBonuses: ((map['equippedItemBonuses'] as Map?) ?? const {})
          .map(
            (key, value) => MapEntry(
              key.toString(),
              HeroStats.fromMap(Map<String, dynamic>.from(value as Map)),
            ),
          ),
      equipmentUpgradeLevels: Map<String, int>.from(
        ((map['equipmentUpgradeLevels'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
      maxMana: map['maxMana'] as int?,
      currentMana: map['currentMana'] as int?,
      bodyCondition: map['bodyCondition'] as String?,
      statusEffects: (map['statusEffects'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      skillCooldowns: Map<String, int>.from(
        ((map['skillCooldowns'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
      currentAction: map['currentAction'] as String?,
      currentTarget: map['currentTarget'] as String?,
      recoveryReadyAtEpochMs: map['recoveryReadyAtEpochMs'] as int?,
    );
  }
}
