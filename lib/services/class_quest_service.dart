import '../models/hero_model.dart';

class QuestObjectiveStatus {
  final String label;
  final int current;
  final int target;

  const QuestObjectiveStatus({
    required this.label,
    required this.current,
    required this.target,
  });

  bool get isComplete => current >= target;
}

class ClassQuestDefinition {
  final String id;
  final String title;
  final String description;
  final List<String> relatedClassIds;
  final bool Function(HeroModel hero) canStart;
  final List<QuestObjectiveStatus> Function(HeroModel hero) objectives;

  const ClassQuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.relatedClassIds,
    required this.canStart,
    required this.objectives,
  });
}

class ClassQuestService {
  static final List<ClassQuestDefinition> _definitions = [
    ClassQuestDefinition(
      id: 'steel_resolve',
      title: 'Steel Resolve',
      description: 'พิสูจน์ว่าฮีโร่คนนี้ยืนแนวหน้าได้จริงเพื่อเข้าสาย Knight',
      relatedClassIds: const ['knight'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('vanguard') && hero.level >= 10,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 8,
        ),
        QuestObjectiveStatus(
          label: 'DEF',
          current: hero.currentStats.def,
          target: 30,
        ),
        QuestObjectiveStatus(
          label: 'Bond',
          current: hero.bond,
          target: 30,
        ),
      ],
    ),
    ClassQuestDefinition(
      id: 'warpath',
      title: 'Warpath',
      description: 'ทดสอบความดุดันและการใช้ทรัพยากรเพื่อเข้าสาย Warbringer',
      relatedClassIds: const ['warbringer'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('vanguard') && hero.level >= 10,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 8,
        ),
        QuestObjectiveStatus(
          label: 'ATK',
          current: hero.currentStats.atk,
          target: 40,
        ),
        QuestObjectiveStatus(
          label: 'Items used',
          current: hero.totalItemsUsed,
          target: 1,
        ),
      ],
    ),
    ClassQuestDefinition(
      id: 'wind_path',
      title: 'Wind Path',
      description: 'ฝึกความเร็วและการเอาตัวรอดเพื่อเข้าสาย Ranger',
      relatedClassIds: const ['ranger'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('skirmisher') && hero.level >= 10,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 8,
        ),
        QuestObjectiveStatus(
          label: 'SPD',
          current: hero.currentStats.spd,
          target: 34,
        ),
        QuestObjectiveStatus(
          label: 'Items used',
          current: hero.totalItemsUsed,
          target: 2,
        ),
      ],
    ),
    ClassQuestDefinition(
      id: 'shadow_pact',
      title: 'Shadow Pact',
      description: 'ขัดเกลาสายลอบเร้นเพื่อเปิดคลาส Shadowblade',
      relatedClassIds: const ['shadowblade'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('skirmisher') && hero.level >= 12,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 10,
        ),
        QuestObjectiveStatus(
          label: 'LUK',
          current: hero.currentStats.luk,
          target: 22,
        ),
        QuestObjectiveStatus(
          label: 'Bond',
          current: hero.bond,
          target: 35,
        ),
      ],
    ),
    ClassQuestDefinition(
      id: 'oracle_vision',
      title: 'Oracle Vision',
      description: 'เปิดจิตรับนิมิตเพื่อเข้าสาย Oracle',
      relatedClassIds: const ['oracle'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('acolyte') && hero.level >= 12,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 6,
        ),
        QuestObjectiveStatus(
          label: 'Faith',
          current: hero.faith,
          target: 55,
        ),
        QuestObjectiveStatus(
          label: 'Items used',
          current: hero.totalItemsUsed,
          target: 1,
        ),
      ],
    ),
    ClassQuestDefinition(
      id: 'saint_oath',
      title: 'Saint Oath',
      description: 'พิสูจน์ศรัทธาและความไว้ใจเพื่อเปิดคลาส Saint',
      relatedClassIds: const ['saint'],
      canStart: (hero) =>
          hero.unlockedClasses.contains('acolyte') && hero.level >= 14,
      objectives: (hero) => [
        QuestObjectiveStatus(
          label: 'Tower floors cleared',
          current: hero.totalTowerFloorsCleared,
          target: 10,
        ),
        QuestObjectiveStatus(
          label: 'Faith',
          current: hero.faith,
          target: 60,
        ),
        QuestObjectiveStatus(
          label: 'Bond',
          current: hero.bond,
          target: 50,
        ),
      ],
    ),
  ];

  static List<ClassQuestDefinition> get definitions => List.unmodifiable(_definitions);

  static ClassQuestDefinition definitionFor(String questId) {
    return _definitions.firstWhere(
      (entry) => entry.id == questId,
      orElse: () => _definitions.first,
    );
  }

  static List<ClassQuestDefinition> availableQuestsForHero(HeroModel hero) {
    return _definitions.where((quest) => quest.canStart(hero)).toList();
  }

  static bool canStartQuest(HeroModel hero, String questId) {
    final quest = definitionFor(questId);
    if (hero.activeClassQuestIds.contains(questId) ||
        hero.completedClassQuestIds.contains(questId)) {
      return false;
    }
    return quest.canStart(hero);
  }

  static bool canCompleteQuest(HeroModel hero, String questId) {
    if (!hero.activeClassQuestIds.contains(questId)) {
      return false;
    }
    return definitionFor(questId)
        .objectives(hero)
        .every((objective) => objective.isComplete);
  }

  static void startQuest(HeroModel hero, String questId) {
    if (!canStartQuest(hero, questId)) {
      return;
    }
    hero.startClassQuest(questId);
  }

  static void completeQuest(HeroModel hero, String questId) {
    if (!canCompleteQuest(hero, questId)) {
      return;
    }
    hero.completeClassQuest(questId);
  }

  static String questStatusLabel(HeroModel hero, String questId) {
    if (hero.completedClassQuestIds.contains(questId)) {
      return 'Completed';
    }
    if (hero.activeClassQuestIds.contains(questId)) {
      return canCompleteQuest(hero, questId) ? 'Ready to Complete' : 'In Progress';
    }
    return canStartQuest(hero, questId) ? 'Available' : 'Locked';
  }
}
