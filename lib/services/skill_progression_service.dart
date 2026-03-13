import '../models/hero_model.dart';
import '../models/skill_model.dart';

class SkillProgressionService {
  static const List<SkillModel> _skills = [
    SkillModel(
      id: 'steady_strike',
      name: 'Steady Strike',
      description: 'โจมตีปกติที่คุมจังหวะได้ดี ลดแรงปะทะศัตรูเล็กน้อย',
      unlockCondition: 'Novice Lv.1',
      classIds: ['novice'],
      unlockLevel: 1,
      manaCost: 4,
      cooldownTurns: 1,
      powerRating: 12,
      role: 'attack',
    ),
    SkillModel(
      id: 'guarded_breath',
      name: 'Guarded Breath',
      description: 'ตั้งหลัก ฟื้นกำลังและลดความเหนื่อยของตัวเอง',
      unlockCondition: 'Novice Lv.3',
      classIds: ['novice'],
      unlockLevel: 3,
      manaCost: 5,
      cooldownTurns: 2,
      powerRating: 8,
      role: 'recovery',
    ),
    SkillModel(
      id: 'shield_bash',
      name: 'Shield Bash',
      description: 'เข้าชนด้านหน้า กดศัตรูและเปิดทางให้ปาร์ตี้',
      unlockCondition: 'Vanguard Lv.5',
      classIds: ['vanguard', 'knight'],
      unlockLevel: 5,
      manaCost: 7,
      cooldownTurns: 2,
      powerRating: 20,
      role: 'attack',
    ),
    SkillModel(
      id: 'war_cry',
      name: 'War Cry',
      description: 'ปลุกขวัญทีม เพิ่มพลังบุกและลดความกลัว',
      unlockCondition: 'Vanguard Lv.8',
      classIds: ['vanguard', 'warbringer'],
      unlockLevel: 8,
      manaCost: 8,
      cooldownTurns: 3,
      powerRating: 18,
      role: 'support',
    ),
    SkillModel(
      id: 'fortress_stance',
      name: 'Fortress Stance',
      description: 'ยืนค้ำแนวหน้า ลดความเสียหายของทีม',
      unlockCondition: 'Knight Lv.12',
      classIds: ['knight'],
      unlockLevel: 12,
      manaCost: 10,
      cooldownTurns: 3,
      powerRating: 24,
      role: 'guard',
    ),
    SkillModel(
      id: 'cleave_drive',
      name: 'Cleave Drive',
      description: 'โจมตีวงกว้าง เน้นสังหารศัตรูสายถึกและฝูง',
      unlockCondition: 'Warbringer Lv.12',
      classIds: ['warbringer'],
      unlockLevel: 12,
      manaCost: 11,
      cooldownTurns: 3,
      powerRating: 28,
      role: 'attack',
    ),
    SkillModel(
      id: 'quickstep',
      name: 'Quickstep',
      description: 'เคลื่อนที่เร็ว ลดความกดดันและคุม ENG',
      unlockCondition: 'Skirmisher Lv.5',
      classIds: ['skirmisher', 'shadowblade'],
      unlockLevel: 5,
      manaCost: 6,
      cooldownTurns: 2,
      powerRating: 15,
      role: 'mobility',
    ),
    SkillModel(
      id: 'pinning_shot',
      name: 'Pinning Shot',
      description: 'กดจังหวะศัตรูและเปิดช่องให้ทีม',
      unlockCondition: 'Ranger Lv.12',
      classIds: ['ranger'],
      unlockLevel: 12,
      manaCost: 10,
      cooldownTurns: 2,
      powerRating: 24,
      role: 'attack',
    ),
    SkillModel(
      id: 'shadow_fang',
      name: 'Shadow Fang',
      description: 'พุ่งเข้าจุดอ่อน เก็บศัตรูไวและเพิ่มโอกาสของหายาก',
      unlockCondition: 'Shadowblade Lv.12',
      classIds: ['shadowblade'],
      unlockLevel: 12,
      manaCost: 11,
      cooldownTurns: 3,
      powerRating: 26,
      role: 'attack',
    ),
    SkillModel(
      id: 'healing_prayer',
      name: 'Healing Prayer',
      description: 'สวดรักษา ฟื้น HP และลดอาการบาดเจ็บ',
      unlockCondition: 'Acolyte Lv.5',
      classIds: ['acolyte', 'saint'],
      unlockLevel: 5,
      manaCost: 9,
      cooldownTurns: 2,
      powerRating: 18,
      role: 'heal',
    ),
    SkillModel(
      id: 'blessing_field',
      name: 'Blessing Field',
      description: 'คุ้มครองทีม ฟื้น ENG และต้านพิษ',
      unlockCondition: 'Acolyte Lv.8',
      classIds: ['acolyte', 'oracle', 'saint'],
      unlockLevel: 8,
      manaCost: 10,
      cooldownTurns: 3,
      powerRating: 19,
      role: 'support',
    ),
    SkillModel(
      id: 'foresight',
      name: 'Foresight',
      description: 'อ่านทางการโจมตี ลดพลังศัตรูและเพิ่มรางวัล',
      unlockCondition: 'Oracle Lv.18',
      classIds: ['oracle'],
      unlockLevel: 18,
      manaCost: 13,
      cooldownTurns: 3,
      powerRating: 28,
      role: 'support',
    ),
    SkillModel(
      id: 'purify',
      name: 'Purify',
      description: 'ล้างพิษและฟื้นสภาพร่างกายของเพื่อนร่วมทีม',
      unlockCondition: 'Saint Lv.18',
      classIds: ['saint'],
      unlockLevel: 18,
      manaCost: 12,
      cooldownTurns: 3,
      powerRating: 24,
      role: 'cleanse',
    ),
  ];

  static List<SkillModel> get definitions => List.unmodifiable(_skills);

  static List<SkillModel> unlockedSkillsFor(HeroModel hero) {
    final eligibleClasses = {
      'novice',
      hero.currentClass,
      if (hero.unlockedClasses.contains('vanguard')) 'vanguard',
      if (hero.unlockedClasses.contains('skirmisher')) 'skirmisher',
      if (hero.unlockedClasses.contains('acolyte')) 'acolyte',
    };

    return _skills.where((skill) {
      final matchesClass = skill.classIds.any(eligibleClasses.contains);
      return matchesClass && hero.level >= skill.unlockLevel;
    }).toList()..sort((a, b) {
      final levelCompare = a.unlockLevel.compareTo(b.unlockLevel);
      if (levelCompare != 0) {
        return levelCompare;
      }
      return a.name.compareTo(b.name);
    });
  }

  static List<SkillModel> nextUnlocksFor(HeroModel hero) {
    final unlockedIds = unlockedSkillsFor(
      hero,
    ).map((skill) => skill.id).toSet();
    return _skills.where((skill) {
      final matchesClass = skill.classIds.contains(hero.currentClass);
      return matchesClass && !unlockedIds.contains(skill.id);
    }).toList()..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
  }

  static SkillModel? chooseCombatSkill(
    HeroModel hero, {
    required bool lowHp,
    required bool lowMana,
    required bool poisoned,
  }) {
    final available = unlockedSkillsFor(hero).where((skill) {
      return hero.currentMana >= skill.manaCost &&
          hero.skillCooldownFor(skill.id) <= 0;
    }).toList();
    if (available.isEmpty) {
      return null;
    }

    SkillModel? pickByRole(String role) {
      for (final skill in available) {
        if (skill.role == role) {
          return skill;
        }
      }
      return null;
    }

    if (poisoned) {
      return pickByRole('cleanse') ?? pickByRole('heal') ?? available.first;
    }
    if (lowHp) {
      return pickByRole('heal') ?? pickByRole('guard') ?? available.first;
    }
    if (lowMana) {
      return pickByRole('recovery') ?? pickByRole('support') ?? available.first;
    }
    return pickByRole('attack') ??
        pickByRole('support') ??
        pickByRole('mobility') ??
        available.first;
  }
}
