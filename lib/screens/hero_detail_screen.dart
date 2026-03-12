import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
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
        aptitudes: const {
          'Knight': 0.60,
          'Farmer': 0.25,
          'Thief': 0.15,
        },
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

  int get _sealCount => playerData?.itemQuantity(
            ClassProgressionService.classTrialSealItemId,
          ) ??
          0;

  void _notifyChanged() {
    setState(() {});
    widget.onHeroChanged?.call();
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

    final directUnlock = ClassProgressionService.canUnlockOrSwitch(hero, classId);
    final useOverride = !directUnlock &&
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(
                  hero.rarity,
                  (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
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
            _buildStatRow('HP', '${stats.currentHp} / ${stats.maxHp}', Colors.green),
            _buildStatRow(
              'พลังงาน',
              '${stats.currentEng} / ${stats.maxEng}',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge('ATK', stats.atk.toString(), Colors.redAccent),
                ),
                Expanded(
                  child:
                      _buildStatBadge('DEF', stats.def.toString(), Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge('SPD', stats.spd.toString(), Colors.orange),
                ),
                Expanded(
                  child: _buildStatBadge('LUK', stats.luk.toString(), Colors.purple),
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
              'Class Progression',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'เปลี่ยนคลาสได้เมื่อสเตตัสถึงเงื่อนไข หรือใช้ Class Trial Seal จากการลุยหอเพื่อปลดล็อกแบบพิเศษ',
            ),
            const SizedBox(height: 12),
            ...definitions.map((definition) {
              final isCurrent = hero.currentClass == definition.id;
              final isUnlocked =
                  ClassProgressionService.isUnlocked(hero, definition.id);
              final meetsRequirement =
                  ClassProgressionService.meetsDirectRequirement(hero, definition.id);
              final canUseOverride = !meetsRequirement && _sealCount > 0;

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
                        if (isCurrent)
                          const Chip(label: Text('ใช้งานอยู่'))
                        else if (isUnlocked)
                          const Chip(label: Text('ปลดล็อกแล้ว')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(definition.description),
                    const SizedBox(height: 4),
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
                            child: Text(isUnlocked ? 'สลับใช้' : 'ปลดล็อกตามสเตตัส'),
                          ),
                        if (!isCurrent && canUseOverride)
                          FilledButton(
                            onPressed: () => _attemptClassChange(definition.id),
                            child: const Text('ใช้ Seal ปลดล็อก'),
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
                    Text('${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%'),
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
            Text(hero.backgroundStory, style: const TextStyle(fontSize: 14, height: 1.5)),
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
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}
