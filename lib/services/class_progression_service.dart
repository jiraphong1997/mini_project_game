import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import 'class_quest_service.dart';

class ClassDefinition {
  final String id;
  final String title;
  final String description;
  final String requirementText;
  final HeroStats bonusStats;
  final String branch;
  final int tier;
  final bool isSpecialClass;
  final String? baseClassId;
  final String? questId;
  final bool Function(HeroModel hero) requirement;

  const ClassDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.requirementText,
    required this.bonusStats,
    required this.branch,
    required this.tier,
    required this.isSpecialClass,
    required this.baseClassId,
    required this.questId,
    required this.requirement,
  });
}

class ClassProgressionService {
  static const String noviceClassId = 'novice';
  static const String classTrialSealItemId = 'class_trial_seal';

  static final List<ClassDefinition> _definitions = [
    ClassDefinition(
      id: noviceClassId,
      title: 'Novice',
      description: 'คลาสตั้งต้นที่ยืดหยุ่นและใช้เป็นฐานสำหรับทุกสาย',
      requirementText: 'พร้อมใช้งานตั้งแต่เริ่ม',
      bonusStats: HeroStats.zero(),
      branch: 'base',
      tier: 0,
      isSpecialClass: false,
      baseClassId: null,
      questId: null,
      requirement: (_) => true,
    ),
    ClassDefinition(
      id: 'vanguard',
      title: 'Vanguard',
      description: 'แนวหน้าสมดุล เปิดทางไปสาย Knight หรือ Warbringer',
      requirementText: 'Lv.5, ATK 18+, DEF 14+',
      bonusStats: HeroStats(
        maxHp: 20,
        currentHp: 0,
        atk: 6,
        def: 4,
        spd: 0,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
      branch: 'vanguard',
      tier: 1,
      isSpecialClass: false,
      baseClassId: noviceClassId,
      questId: null,
      requirement: (hero) =>
          hero.level >= 5 &&
          hero.currentStats.atk >= 18 &&
          hero.currentStats.def >= 14,
    ),
    ClassDefinition(
      id: 'skirmisher',
      title: 'Skirmisher',
      description: 'สายคล่องตัว เปิดทางไป Ranger หรือ Shadowblade',
      requirementText: 'Lv.5, SPD 18+, LUK 8+',
      bonusStats: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 4,
        def: 0,
        spd: 7,
        maxEng: 0,
        currentEng: 0,
        luk: 2,
      ),
      branch: 'skirmisher',
      tier: 1,
      isSpecialClass: false,
      baseClassId: noviceClassId,
      questId: null,
      requirement: (hero) =>
          hero.level >= 5 &&
          hero.currentStats.spd >= 18 &&
          hero.currentStats.luk >= 8,
    ),
    ClassDefinition(
      id: 'acolyte',
      title: 'Acolyte',
      description: 'สายศรัทธาและสนับสนุน เปิดทางไป Oracle หรือ Saint',
      requirementText: 'Lv.5, Faith 35+, Bond 25+',
      bonusStats: HeroStats(
        maxHp: 10,
        currentHp: 0,
        atk: 2,
        def: 3,
        spd: 2,
        maxEng: 10,
        currentEng: 0,
        luk: 3,
      ),
      branch: 'acolyte',
      tier: 1,
      isSpecialClass: false,
      baseClassId: noviceClassId,
      questId: null,
      requirement: (hero) =>
          hero.level >= 5 && hero.faith >= 35 && hero.bond >= 25,
    ),
    ClassDefinition(
      id: 'knight',
      title: 'Knight',
      description: 'สายป้องกันขั้นสูงของ Vanguard ยืนระยะและคุ้มกันทีม',
      requirementText: 'Vanguard unlocked, Steel Resolve complete, Lv.12, ATK 35+, DEF 30+',
      bonusStats: HeroStats(
        maxHp: 55,
        currentHp: 0,
        atk: 8,
        def: 11,
        spd: -1,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
      branch: 'vanguard',
      tier: 2,
      isSpecialClass: false,
      baseClassId: 'vanguard',
      questId: 'steel_resolve',
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.atk >= 35 &&
          hero.currentStats.def >= 30 &&
          hero.primaryAptitudeValue >= 0.35,
    ),
    ClassDefinition(
      id: 'warbringer',
      title: 'Warbringer',
      description: 'สายโจมตีพิเศษของ Vanguard เน้นบุกเร็วและแรง',
      requirementText: 'Vanguard unlocked, Warpath complete, Lv.12, ATK 40+',
      bonusStats: HeroStats(
        maxHp: 20,
        currentHp: 0,
        atk: 14,
        def: 2,
        spd: 4,
        maxEng: 0,
        currentEng: 0,
        luk: 1,
      ),
      branch: 'vanguard',
      tier: 2,
      isSpecialClass: true,
      baseClassId: 'vanguard',
      questId: 'warpath',
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.atk >= 40 &&
          hero.currentStats.def >= 18,
    ),
    ClassDefinition(
      id: 'ranger',
      title: 'Ranger',
      description: 'สายยิงและคุมระยะของ Skirmisher',
      requirementText: 'Skirmisher unlocked, Wind Path complete, Lv.12, SPD 34+, LUK 16+',
      bonusStats: HeroStats(
        maxHp: 10,
        currentHp: 0,
        atk: 7,
        def: 2,
        spd: 10,
        maxEng: 0,
        currentEng: 0,
        luk: 4,
      ),
      branch: 'skirmisher',
      tier: 2,
      isSpecialClass: false,
      baseClassId: 'skirmisher',
      questId: 'wind_path',
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.spd >= 34 &&
          hero.currentStats.luk >= 16 &&
          hero.primaryAptitudeValue >= 0.30,
    ),
    ClassDefinition(
      id: 'shadowblade',
      title: 'Shadowblade',
      description: 'สายลอบสังหารพิเศษของ Skirmisher',
      requirementText: 'Skirmisher unlocked, Shadow Pact complete, Lv.12, SPD 30+, LUK 22+',
      bonusStats: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 10,
        def: 0,
        spd: 9,
        maxEng: 0,
        currentEng: 0,
        luk: 8,
      ),
      branch: 'skirmisher',
      tier: 2,
      isSpecialClass: true,
      baseClassId: 'skirmisher',
      questId: 'shadow_pact',
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.spd >= 30 &&
          hero.currentStats.luk >= 22,
    ),
    ClassDefinition(
      id: 'oracle',
      title: 'Oracle',
      description: 'สายอ่านทางและสนับสนุนขั้นสูงของ Acolyte',
      requirementText: 'Acolyte unlocked, Oracle Vision complete, Lv.18, Faith 60+',
      bonusStats: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 5,
        def: 4,
        spd: 6,
        maxEng: 20,
        currentEng: 0,
        luk: 8,
      ),
      branch: 'acolyte',
      tier: 2,
      isSpecialClass: false,
      baseClassId: 'acolyte',
      questId: 'oracle_vision',
      requirement: (hero) =>
          hero.level >= 18 &&
          hero.faith >= 60 &&
          hero.currentStats.spd >= 28 &&
          hero.bond >= 35,
    ),
    ClassDefinition(
      id: 'saint',
      title: 'Saint',
      description: 'สายศรัทธาพิเศษของ Acolyte เน้น bond/faith และความอยู่รอด',
      requirementText: 'Acolyte unlocked, Saint Oath complete, Lv.18, Faith 60+, Bond 50+',
      bonusStats: HeroStats(
        maxHp: 45,
        currentHp: 0,
        atk: 3,
        def: 8,
        spd: 2,
        maxEng: 20,
        currentEng: 0,
        luk: 4,
      ),
      branch: 'acolyte',
      tier: 2,
      isSpecialClass: true,
      baseClassId: 'acolyte',
      questId: 'saint_oath',
      requirement: (hero) =>
          hero.level >= 18 &&
          hero.faith >= 60 &&
          hero.bond >= 50,
    ),
  ];

  static List<ClassDefinition> get definitions => List.unmodifiable(_definitions);

  static ClassDefinition definitionFor(String classId) {
    return _definitions.firstWhere(
      (entry) => entry.id == classId,
      orElse: () => _definitions.first,
    );
  }

  static String branchForClass(String classId) {
    return definitionFor(classId).branch;
  }

  static String branchLabel(String branch) {
    switch (branch) {
      case 'vanguard':
        return 'Vanguard';
      case 'skirmisher':
        return 'Skirmisher';
      case 'acolyte':
        return 'Acolyte';
      case 'base':
        return 'Base';
      default:
        return branch;
    }
  }

  static bool meetsDirectRequirement(HeroModel hero, String classId) {
    return definitionFor(classId).requirement(hero);
  }

  static bool hasBaseClassRequirement(HeroModel hero, String classId) {
    final baseClassId = definitionFor(classId).baseClassId;
    if (baseClassId == null) {
      return true;
    }
    return hero.unlockedClasses.contains(baseClassId) || hero.currentClass == baseClassId;
  }

  static bool hasQuestRequirement(HeroModel hero, String classId) {
    final questId = definitionFor(classId).questId;
    if (questId == null) {
      return true;
    }
    return hero.completedClassQuestIds.contains(questId);
  }

  static bool isUnlocked(HeroModel hero, String classId) {
    return hero.unlockedClasses.contains(classId);
  }

  static bool canUnlockOrSwitch(
    HeroModel hero,
    String classId, {
    bool hasOverride = false,
  }) {
    if (isUnlocked(hero, classId)) {
      return true;
    }
    if (!hasBaseClassRequirement(hero, classId)) {
      return false;
    }

    final meetsStats = meetsDirectRequirement(hero, classId);
    final meetsQuest = hasQuestRequirement(hero, classId);
    return (meetsStats && meetsQuest) || hasOverride;
  }

  static bool applyClassChange(
    HeroModel hero,
    String classId, {
    bool useOverride = false,
  }) {
    if (!canUnlockOrSwitch(hero, classId, hasOverride: useOverride)) {
      return false;
    }

    final definition = definitionFor(classId);
    hero.changeClass(definition.id, definition.bonusStats);
    return true;
  }

  static String unlockHint(HeroModel hero, String classId) {
    final definition = definitionFor(classId);
    if (hero.unlockedClasses.contains(classId)) {
      return 'ปลดล็อกแล้ว สลับกลับได้ทันที';
    }
    if (!hasBaseClassRequirement(hero, classId)) {
      final baseClass = definition.baseClassId == null
          ? 'base'
          : definitionFor(definition.baseClassId!).title;
      return 'ต้องปลดล็อก $baseClass ก่อน';
    }

    final questId = definition.questId;
    if (questId != null && !hero.completedClassQuestIds.contains(questId)) {
      final quest = ClassQuestService.definitionFor(questId);
      if (hero.activeClassQuestIds.contains(questId)) {
        return 'ต้องทำเควส ${quest.title} ให้สำเร็จก่อน';
      }
      return 'ต้องผ่านเควส ${quest.title} ก่อน หรือใช้ Class Trial Seal';
    }

    if (definition.requirement(hero)) {
      return 'เงื่อนไขครบแล้ว เปลี่ยนคลาสได้ทันที';
    }
    return '${definition.requirementText} หรือใช้ Class Trial Seal';
  }
}
