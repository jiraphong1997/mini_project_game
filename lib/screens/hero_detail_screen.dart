import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/item_model.dart';
import '../models/hero_stats.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
import '../services/class_quest_service.dart';
import '../services/item_usage_service.dart';
import '../services/skill_progression_service.dart';
import '../utils/leveling_policy.dart';

class HeroDetailScreen extends StatefulWidget {
  final HeroModel hero;
  final PlayerData? playerData;
  final VoidCallback? onHeroChanged;

  const HeroDetailScreen({
    super.key,
    required this.hero,
    this.playerData,
    this.onHeroChanged,
  });

  factory HeroDetailScreen.mock() {
    return HeroDetailScreen(
      hero: HeroModel(
        id: 'h001',
        name: 'Arthur',
        gender: 'ชาย',
        age: 24,
        backgroundStory:
            'นักรบหนุ่มผู้ไล่ตามความฝันในการพิชิตหอคอยเพื่อค้นหาไอเทมระดับตำนาน',
        level: 65,
        currentExp: 4500,
        totalExpEarned: 32000,
        totalTowerFloorsCleared: 18,
        totalItemsUsed: 3,
        baseStats: HeroStats(
          maxHp: 1000,
          currentHp: 1000,
          atk: 120,
          def: 80,
          spd: 50,
          maxEng: 100,
          currentEng: 80,
          luk: 15,
        ),
        currentStats: HeroStats(
          maxHp: 1200,
          currentHp: 1200,
          atk: 150,
          def: 90,
          spd: 55,
          maxEng: 100,
          currentEng: 80,
          luk: 20,
        ),
        aptitudes: const {'Knight': 0.60, 'Farmer': 0.25, 'Thief': 0.15},
        currentClass: 'vanguard',
        unlockedClasses: const ['novice', 'vanguard'],
      ),
    );
  }

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  HeroModel get hero => widget.hero;

  PlayerData? get playerData => widget.playerData;

  String get _currentClassTitle =>
      ClassProgressionService.definitionFor(hero.currentClass).title;

  int get _sealCount =>
      playerData?.itemQuantity(ClassProgressionService.classTrialSealItemId) ??
      0;

  List<ClassQuestDefinition> get _visibleQuests {
    return ClassQuestService.definitions.where((quest) {
      return quest.canStart(hero) ||
          hero.activeClassQuestIds.contains(quest.id) ||
          hero.completedClassQuestIds.contains(quest.id);
    }).toList();
  }

  List<ItemCatalogEntry> get _usableItems {
    final player = playerData;
    if (player == null) {
      return const [];
    }

    return ItemUsageService.catalog.where((entry) {
      return player.itemQuantity(entry.id) > 0 && !entry.isEquippable;
    }).toList();
  }

  List<ItemCatalogEntry> get _equippableItems {
    final player = playerData;
    if (player == null) {
      return const [];
    }

    return ItemUsageService.catalog.where((entry) {
      return player.itemQuantity(entry.id) > 0 && entry.isEquippable;
    }).toList();
  }

  void _notifyChanged() {
    setState(() {});
    widget.onHeroChanged?.call();
  }

  void _startQuest(String questId) {
    ClassQuestService.startQuest(hero, questId);
    _notifyChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เริ่มเควส ${ClassQuestService.definitionFor(questId).title} แล้ว',
        ),
      ),
    );
  }

  void _completeQuest(String questId) {
    if (!ClassQuestService.canCompleteQuest(hero, questId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เงื่อนไขเควสยังไม่ครบ')));
      return;
    }

    ClassQuestService.completeQuest(hero, questId);
    _notifyChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เควส ${ClassQuestService.definitionFor(questId).title} สำเร็จแล้ว',
        ),
      ),
    );
  }

  void _useItem(String itemId) {
    final player = playerData;
    if (player == null) {
      return;
    }

    final result = ItemUsageService.useItem(player, hero, itemId);
    if (result.success) {
      _notifyChanged();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _equipItem(String itemId) {
    final player = playerData;
    if (player == null) {
      return;
    }

    final result = ItemUsageService.equipItem(player, hero, itemId);
    if (result.success) {
      _notifyChanged();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _unequipSlot(EquipmentSlot slot) {
    final player = playerData;
    if (player == null) {
      return;
    }

    final result = ItemUsageService.unequipItem(player, hero, slot);
    if (result.success) {
      _notifyChanged();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _attemptClassChange(String classId) {
    final definition = ClassProgressionService.definitionFor(classId);
    final hasOverride = _sealCount > 0;
    final canChange = ClassProgressionService.canUnlockOrSwitch(
      hero,
      classId,
      hasOverride: hasOverride,
    );

    if (!canChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยังเปลี่ยนเป็น ${definition.title} ไม่ได้')),
      );
      return;
    }

    final directUnlock = ClassProgressionService.canUnlockOrSwitch(
      hero,
      classId,
    );
    final useOverride =
        !directUnlock &&
        !ClassProgressionService.isUnlocked(hero, classId) &&
        hasOverride;
    if (useOverride) {
      final consumed = playerData?.consumeItem(
        ClassProgressionService.classTrialSealItemId,
      );
      if (consumed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มี Class Trial Seal ให้ใช้')),
        );
        return;
      }
    }

    final changed = ClassProgressionService.applyClassChange(
      hero,
      classId,
      useOverride: useOverride,
    );
    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนเป็น ${definition.title} ไม่สำเร็จ')),
      );
      return;
    }

    _notifyChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          useOverride
              ? 'ใช้ Class Trial Seal ปลดล็อก ${definition.title} สำเร็จ'
              : 'เปลี่ยนคลาสเป็น ${definition.title} แล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลฮีโร่ - ${hero.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildProgressCard(),
            const SizedBox(height: 16),
            _buildSkillCard(),
            const SizedBox(height: 16),
            _buildEquipmentCard(),
            const SizedBox(height: 16),
            _buildItemUsageCard(),
            const SizedBox(height: 16),
            _buildQuestCard(),
            const SizedBox(height: 16),
            _buildClassCard(),
            const SizedBox(height: 16),
            _buildAptitudesCard(),
            const SizedBox(height: 16),
            _buildBackgroundStoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getRarityColor(hero.rarity), width: 3),
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hero.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  hero.rarity,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lv. ${hero.level} | Class: $_currentClassTitle',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
              Text(
                'สายถนัด: ${hero.currentJobRole} | EXP Stage: ${hero.experienceStage}',
              ),
              Text('เพศ: ${hero.gender} | อายุ: ${hero.age} ปี'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final stats = hero.currentStats;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ค่าสถานะ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatRow(
              'HP',
              '${stats.currentHp} / ${stats.maxHp}',
              Colors.green,
            ),
            _buildStatRow(
              'พลังงาน',
              '${stats.currentEng} / ${stats.maxEng}',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge(
                    'ATK',
                    stats.atk.toString(),
                    Colors.redAccent,
                  ),
                ),
                Expanded(
                  child: _buildStatBadge(
                    'DEF',
                    stats.def.toString(),
                    Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge(
                    'SPD',
                    stats.spd.toString(),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatBadge(
                    'LUK',
                    stats.luk.toString(),
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final nextLevelExp = LevelingPolicy.expRequiredForNextLevel(hero.level);
    final progress = nextLevelExp == 0
        ? 0.0
        : (hero.currentExp / nextLevelExp).clamp(0.0, 1.0);
    final recovery = hero.recoveryCooldownRemaining;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text('EXP: ${hero.currentExp} / $nextLevelExp'),
            Text('Total EXP Earned: ${hero.totalExpEarned}'),
            Text('Tower Floors Cleared: ${hero.totalTowerFloorsCleared}'),
            Text('Items Used: ${hero.totalItemsUsed}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            Text('Bond: ${hero.bond} / 100'),
            Text('Faith: ${hero.faith} / 100'),
            Text('Mana: ${hero.currentMana} / ${hero.maxMana}'),
            Text('Body Condition: ${hero.bodyCondition}'),
            Text(
              'Status Effects: ${hero.statusEffects.isEmpty ? 'None' : hero.statusEffects.join(', ')}',
            ),
            Text('คลาสปัจจุบัน: $_currentClassTitle'),
            Text(
              hero.isRecovering
                  ? 'Recovery: อีก ${_formatDuration(recovery)}'
                  : 'Recovery: พร้อมใช้งาน',
            ),
            if (playerData != null) ...[
              const SizedBox(height: 8),
              Text('Class Trial Seal: $_sealCount'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillCard() {
    final skills = SkillProgressionService.unlockedSkillsFor(hero);
    final nextUnlocks = SkillProgressionService.nextUnlocksFor(hero);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'สกิลจะเปิดตามคลาสปัจจุบันและเลเวล เมื่อเปลี่ยนคลาส รูปแบบการใช้สกิลจะเปลี่ยนตามไปด้วย',
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              const Text('ยังไม่มีสกิลที่ปลดล็อก')
            else
              ...skills.map((skill) {
                final cooldown = hero.skillCooldownFor(skill.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(skill.description),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${skill.role} • MP ${skill.manaCost} • Cooldown ${skill.cooldownTurns}',
                      ),
                      if (cooldown > 0) Text('คูลดาวน์ค้าง: $cooldown'),
                    ],
                  ),
                );
              }),
            if (nextUnlocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Next Unlocks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...nextUnlocks
                  .take(3)
                  .map(
                    (skill) => Text('${skill.name} • ${skill.unlockCondition}'),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemUsageCard() {
    final player = playerData;
    if (player == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ใช้ไอเทมกับฮีโร่โดยตรงเพื่อเร่ง build, ขยับค่าสถานะ, หรือเติม bond/faith',
            ),
            const SizedBox(height: 12),
            if (_usableItems.isEmpty)
              const Text('ยังไม่มีไอเทมที่ใช้กับฮีโร่ได้ในคลัง')
            else
              ..._usableItems.map((item) {
                final quantity = player.itemQuantity(item.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.name} x$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.description),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: () => _useItem(item.id),
                        child: const Text('Use'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard() {
    final player = playerData;
    if (player == null) {
      return const SizedBox.shrink();
    }

    final slots = EquipmentSlot.values;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...slots.map((slot) {
              final equippedId = hero.equippedItemIdForSlot(slot);
              final equippedDefinition = equippedId == null
                  ? null
                  : ItemUsageService.definitionFor(equippedId);
              final candidates = _equippableItems
                  .where((item) => item.equipmentSlot == slot)
                  .toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.name.toUpperCase()}: ${equippedDefinition?.name ?? 'Empty'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (equippedDefinition?.statBonus != null)
                      Text(_bonusLabel(equippedDefinition!.statBonus!)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (equippedId != null)
                          FilledButton.tonal(
                            onPressed: () => _unequipSlot(slot),
                            child: const Text('Unequip'),
                          ),
                        ...candidates.map((item) {
                          final quantity = player.itemQuantity(item.id);
                          return OutlinedButton(
                            onPressed: () => _equipItem(item.id),
                            child: Text('${item.name} x$quantity'),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (_equippableItems.isEmpty) const Text('ยังไม่มีอุปกรณ์ในคลัง'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard() {
    final quests = _visibleQuests;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Quests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'คลาสขั้นสูงและคลาสพิเศษต้องผ่านเควสสายอาชีพก่อน ยกเว้นจะข้ามด้วย Class Trial Seal',
            ),
            const SizedBox(height: 12),
            if (quests.isEmpty)
              const Text('ยังไม่มีเควสอาชีพที่เปิดให้เริ่มสำหรับฮีโร่คนนี้')
            else
              ...quests.map((quest) {
                final status = ClassQuestService.questStatusLabel(
                  hero,
                  quest.id,
                );
                final objectives = quest.objectives(hero);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quest.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Chip(label: Text(status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(quest.description),
                      const SizedBox(height: 8),
                      ...objectives.map(
                        (objective) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${objective.label}: ${objective.current}/${objective.target}'
                            '${objective.isComplete ? ' • done' : ''}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (ClassQuestService.canStartQuest(hero, quest.id))
                            FilledButton.tonal(
                              onPressed: () => _startQuest(quest.id),
                              child: const Text('Start Quest'),
                            ),
                          if (ClassQuestService.canCompleteQuest(
                            hero,
                            quest.id,
                          ))
                            FilledButton(
                              onPressed: () => _completeQuest(quest.id),
                              child: const Text('Complete Quest'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard() {
    final definitions = ClassProgressionService.definitions;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Branches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'แต่ละสายมี base class ของตัวเอง และจะแตก branch เป็น advanced หรือ special class ตามเควสและสเตตัส',
            ),
            const SizedBox(height: 12),
            ...definitions.map((definition) {
              final isCurrent = hero.currentClass == definition.id;
              final isUnlocked = ClassProgressionService.isUnlocked(
                hero,
                definition.id,
              );
              final meetsRequirement =
                  ClassProgressionService.meetsDirectRequirement(
                    hero,
                    definition.id,
                  );
              final canUseOverride = !meetsRequirement && _sealCount > 0;
              final tierLabel = switch (definition.tier) {
                0 => 'Base',
                1 => 'Core',
                2 => definition.isSpecialClass ? 'Special' : 'Advanced',
                _ => 'Tier ${definition.tier}',
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isCurrent
                      ? Colors.indigo.withValues(alpha: 0.08)
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: isCurrent ? Colors.indigo : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            definition.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Chip(label: Text(tierLabel)),
                        const SizedBox(width: 6),
                        if (isCurrent)
                          const Chip(label: Text('ใช้งานอยู่'))
                        else if (isUnlocked)
                          const Chip(label: Text('ปลดล็อกแล้ว')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(definition.description),
                    const SizedBox(height: 4),
                    Text('Branch: ${definition.branch}'),
                    Text(
                      ClassProgressionService.unlockHint(hero, definition.id),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isCurrent)
                          FilledButton.tonal(
                            onPressed: isUnlocked || meetsRequirement
                                ? () => _attemptClassChange(definition.id)
                                : null,
                            child: Text(
                              isUnlocked ? 'Switch' : 'Unlock with Stats',
                            ),
                          ),
                        if (!isCurrent && canUseOverride)
                          FilledButton(
                            onPressed: () => _attemptClassChange(definition.id),
                            child: const Text('Use Seal'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAptitudesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aptitudes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...hero.aptitudes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.grey[200],
                      color: Colors.indigoAccent,
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Story',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              hero.backgroundStory,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return Colors.orangeAccent;
      case 4:
        return Colors.purpleAccent;
      case 3:
        return Colors.blueAccent;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return 'พร้อม';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _bonusLabel(HeroStats bonus) {
    final parts = <String>[];
    if (bonus.maxHp != 0) {
      parts.add('HP ${bonus.maxHp > 0 ? '+' : ''}${bonus.maxHp}');
    }
    if (bonus.atk != 0) {
      parts.add('ATK ${bonus.atk > 0 ? '+' : ''}${bonus.atk}');
    }
    if (bonus.def != 0) {
      parts.add('DEF ${bonus.def > 0 ? '+' : ''}${bonus.def}');
    }
    if (bonus.spd != 0) {
      parts.add('SPD ${bonus.spd > 0 ? '+' : ''}${bonus.spd}');
    }
    if (bonus.maxEng != 0) {
      parts.add('ENG ${bonus.maxEng > 0 ? '+' : ''}${bonus.maxEng}');
    }
    if (bonus.luk != 0) {
      parts.add('LUK ${bonus.luk > 0 ? '+' : ''}${bonus.luk}');
    }
    return parts.join(' • ');
  }
}
