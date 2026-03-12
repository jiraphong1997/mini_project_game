import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
import '../services/class_quest_service.dart';

class ClassQuestBoardScreen extends StatefulWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;
  final ValueChanged<HeroModel> onOpenHero;

  const ClassQuestBoardScreen({
    super.key,
    required this.playerData,
    required this.onDataChanged,
    required this.onOpenHero,
  });

  @override
  State<ClassQuestBoardScreen> createState() => _ClassQuestBoardScreenState();
}

class _ClassQuestBoardScreenState extends State<ClassQuestBoardScreen> {
  String _filter = 'active';
  String _branchFilter = 'all';

  List<HeroModel> get _heroes {
    final heroes = [...widget.playerData.allHeroes];
    heroes.sort((a, b) {
      final aScore = _priorityForHero(a);
      final bScore = _priorityForHero(b);
      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }
      return b.level.compareTo(a.level);
    });
    return heroes.where(_matchesFilter).toList();
  }

  int _priorityForHero(HeroModel hero) {
    final activeReady = hero.activeClassQuestIds.where((questId) {
      return ClassQuestService.canCompleteQuest(hero, questId);
    }).length;
    if (activeReady > 0) {
      return 4;
    }
    if (hero.activeClassQuestIds.isNotEmpty) {
      return 3;
    }
    if (ClassQuestService.availableQuestsForHero(hero).isNotEmpty) {
      return 2;
    }
    if (hero.completedClassQuestIds.isNotEmpty) {
      return 1;
    }
    return 0;
  }

  bool _matchesFilter(HeroModel hero) {
    final branch = ClassProgressionService.branchForClass(hero.currentClass);
    final branchMatches = _branchFilter == 'all' || branch == _branchFilter;
    if (!branchMatches) {
      return false;
    }

    switch (_filter) {
      case 'ready':
        return hero.activeClassQuestIds.any(
          (questId) => ClassQuestService.canCompleteQuest(hero, questId),
        );
      case 'available':
        return ClassQuestService.availableQuestsForHero(hero).isNotEmpty &&
            hero.activeClassQuestIds.isEmpty;
      case 'completed':
        return hero.completedClassQuestIds.isNotEmpty;
      default:
        return hero.activeClassQuestIds.isNotEmpty ||
            ClassQuestService.availableQuestsForHero(hero).isNotEmpty;
    }
  }

  void _startQuest(HeroModel hero, String questId) {
    ClassQuestService.startQuest(hero, questId);
    widget.onDataChanged();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เริ่ม ${ClassQuestService.definitionFor(questId).title} แล้ว'),
      ),
    );
  }

  void _completeQuest(HeroModel hero, String questId) {
    if (!ClassQuestService.canCompleteQuest(hero, questId)) {
      return;
    }
    ClassQuestService.completeQuest(hero, questId);
    widget.onDataChanged();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('สำเร็จ ${ClassQuestService.definitionFor(questId).title}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroes = _heroes;
    final readyCount = widget.playerData.allHeroes.where((hero) {
      return hero.activeClassQuestIds.any(
        (questId) => ClassQuestService.canCompleteQuest(hero, questId),
      );
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('กระดานเควสคลาส'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              border: const Border(
                bottom: BorderSide(color: Color(0x22000000)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'พร้อมส่งเควส: $readyCount ตัว',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('active', 'กำลังทำ / มีให้รับ'),
                    _filterChip('ready', 'พร้อมส่ง'),
                    _filterChip('available', 'รับได้'),
                    _filterChip('completed', 'สำเร็จแล้ว'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _branchChip('all', 'ทุกสาย'),
                    _branchChip('vanguard', ClassProgressionService.branchLabel('vanguard')),
                    _branchChip(
                      'skirmisher',
                      ClassProgressionService.branchLabel('skirmisher'),
                    ),
                    _branchChip('acolyte', ClassProgressionService.branchLabel('acolyte')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: heroes.isEmpty
                ? const Center(
                    child: Text('ยังไม่มีฮีโร่ที่ตรงกับตัวกรองของกระดานเควส'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: heroes.length,
                    itemBuilder: (context, index) {
                      final hero = heroes[index];
                      return _HeroQuestCard(
                        hero: hero,
                        onStartQuest: (questId) => _startQuest(hero, questId),
                        onCompleteQuest: (questId) =>
                            _completeQuest(hero, questId),
                        onOpenHero: () => widget.onOpenHero(hero),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _branchChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _branchFilter == value,
      onSelected: (_) => setState(() => _branchFilter = value),
    );
  }
}

class _HeroQuestCard extends StatelessWidget {
  final HeroModel hero;
  final ValueChanged<String> onStartQuest;
  final ValueChanged<String> onCompleteQuest;
  final VoidCallback onOpenHero;

  const _HeroQuestCard({
    required this.hero,
    required this.onStartQuest,
    required this.onCompleteQuest,
    required this.onOpenHero,
  });

  @override
  Widget build(BuildContext context) {
    final relevantQuests = ClassQuestService.definitions.where((quest) {
      return ClassQuestService.canStartQuest(hero, quest.id) ||
          hero.activeClassQuestIds.contains(quest.id) ||
          hero.completedClassQuestIds.contains(quest.id);
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          hero.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Lv.${hero.level} ${ClassProgressionService.definitionFor(hero.currentClass).title}'
          ' • สาย ${ClassProgressionService.branchLabel(ClassProgressionService.branchForClass(hero.currentClass))}'
          ' • เควสทำอยู่ ${hero.activeClassQuestIds.length}'
          ' • สำเร็จ ${hero.completedClassQuestIds.length}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bond ${hero.bond} • Faith ${hero.faith} • Floors ${hero.totalTowerFloorsCleared}',
                ),
              ),
              TextButton(
                onPressed: onOpenHero,
                child: const Text('ดูฮีโร่'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (relevantQuests.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ยังไม่มี class quest ที่เปิดให้ตัวนี้'),
            )
          else
            ...relevantQuests.map((quest) {
              final objectives = quest.objectives(hero);
              final status = ClassQuestService.questStatusLabel(hero, quest.id);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(quest.description),
                    const SizedBox(height: 8),
                    ...objectives.map(
                      (objective) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '- ${objective.label}: ${objective.current}/${objective.target}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (ClassQuestService.canStartQuest(hero, quest.id))
                          ElevatedButton(
                            onPressed: () => onStartQuest(quest.id),
                            child: const Text('เริ่ม'),
                          ),
                        if (ClassQuestService.canCompleteQuest(hero, quest.id))
                          ElevatedButton(
                            onPressed: () => onCompleteQuest(quest.id),
                            child: const Text('ส่งเควส'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Ready to Complete':
        return 'พร้อมส่ง';
      case 'In Progress':
        return 'กำลังทำ';
      case 'Available':
        return 'รับได้';
      default:
        return 'ยังไม่เปิด';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ready to Complete':
        return Colors.green;
      case 'In Progress':
        return Colors.indigo;
      case 'Available':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
