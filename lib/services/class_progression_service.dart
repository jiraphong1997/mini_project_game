import '../models/hero_model.dart';
import '../models/hero_stats.dart';

class ClassDefinition {
  final String id;
  final String title;
  final String description;
  final String requirementText;
  final HeroStats bonusStats;
  final bool Function(HeroModel hero) requirement;

  const ClassDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.requirementText,
    required this.bonusStats,
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
      description: 'คลาสตั้งต้นที่ยืดหยุ่นและไม่มีเงื่อนไข',
      requirementText: 'พร้อมใช้งานตั้งแต่เริ่ม',
      bonusStats: HeroStats.zero(),
      requirement: (_) => true,
    ),
    ClassDefinition(
      id: 'vanguard',
      title: 'Vanguard',
      description: 'แนวหน้าโจมตีสมดุล เหมาะกับตัวละครที่เริ่มแข็งแรงแล้ว',
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
      requirement: (hero) =>
          hero.level >= 5 &&
          hero.currentStats.atk >= 18 &&
          hero.currentStats.def >= 14,
    ),
    ClassDefinition(
      id: 'skirmisher',
      title: 'Skirmisher',
      description: 'คลาสสายไว เน้นสปีดและการเอาตัวรอด',
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
      requirement: (hero) =>
          hero.level >= 5 &&
          hero.currentStats.spd >= 18 &&
          hero.currentStats.luk >= 8,
    ),
    ClassDefinition(
      id: 'acolyte',
      title: 'Acolyte',
      description: 'คลาสสนับสนุนที่เติบโตจาก faith และ bond',
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
      requirement: (hero) =>
          hero.level >= 5 && hero.faith >= 35 && hero.bond >= 25,
    ),
    ClassDefinition(
      id: 'knight',
      title: 'Knight',
      description: 'คลาสป้องกันขั้นสูง ต้องใช้สเตตัสพื้นฐานที่แน่นจริง',
      requirementText: 'Lv.12, ATK 35+, DEF 30+, Aptitude 35%+',
      bonusStats: HeroStats(
        maxHp: 50,
        currentHp: 0,
        atk: 8,
        def: 10,
        spd: -1,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.atk >= 35 &&
          hero.currentStats.def >= 30 &&
          hero.primaryAptitudeValue >= 0.35,
    ),
    ClassDefinition(
      id: 'ranger',
      title: 'Ranger',
      description: 'คลาสโจมตีระยะไกลและเคลื่อนไหวสูง',
      requirementText: 'Lv.12, SPD 34+, LUK 16+, Aptitude 30%+',
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
      requirement: (hero) =>
          hero.level >= 12 &&
          hero.currentStats.spd >= 34 &&
          hero.currentStats.luk >= 16 &&
          hero.primaryAptitudeValue >= 0.30,
    ),
    ClassDefinition(
      id: 'warden',
      title: 'Warden',
      description: 'คลาสยืนระยะขั้นสูงสำหรับฮีโร่ที่ผ่านการลุยยาว',
      requirementText: 'Lv.18, HP 500+, DEF 48+, Bond 40+',
      bonusStats: HeroStats(
        maxHp: 80,
        currentHp: 0,
        atk: 4,
        def: 12,
        spd: 0,
        maxEng: 10,
        currentEng: 0,
        luk: 0,
      ),
      requirement: (hero) =>
          hero.level >= 18 &&
          hero.currentStats.maxHp >= 500 &&
          hero.currentStats.def >= 48 &&
          hero.bond >= 40,
    ),
    ClassDefinition(
      id: 'oracle',
      title: 'Oracle',
      description: 'คลาสพิเศษสายศรัทธาและการอ่านทางล่วงหน้า',
      requirementText: 'Lv.18, Faith 60+, SPD 28+, Bond 35+',
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
      requirement: (hero) =>
          hero.level >= 18 &&
          hero.faith >= 60 &&
          hero.currentStats.spd >= 28 &&
          hero.bond >= 35,
    ),
  ];

  static List<ClassDefinition> get definitions => List.unmodifiable(_definitions);

  static ClassDefinition definitionFor(String classId) {
    return _definitions.firstWhere(
      (entry) => entry.id == classId,
      orElse: () => _definitions.first,
    );
  }

  static bool meetsDirectRequirement(HeroModel hero, String classId) {
    return definitionFor(classId).requirement(hero);
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
    return meetsDirectRequirement(hero, classId) || hasOverride;
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
    if (definition.requirement(hero)) {
      return 'สถานะครบแล้ว เปลี่ยนคลาสได้ทันที';
    }
    return '${definition.requirementText} หรือใช้ Class Trial Seal';
  }
}
