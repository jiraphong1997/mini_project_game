import 'dart:math';

import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import 'leveling_policy.dart';

class GachaManager {
  static final Random _rand = Random();

  static const int commonCost = 100;
  static const int specialCost = 500;

  static const List<String> _baseNames = [
    'เลออน',
    'เฟรยา',
    'อาเธอร์',
    'ลูคัส',
    'ไมเคิล',
    'โซเฟีย',
    'อีริค',
    'อลิซ',
    'เรน',
    'เซริน',
    'คาอิน',
    'มีรา',
    'ไคลน์',
    'ลูนา',
    'โรวาน',
    'เอลิน',
    'เดนท์',
    'ไอริส',
    'วาเลน',
    'เซลีน',
  ];

  static const List<String> _nameTitles = [
    'แห่งสายลม',
    'ผู้เฝ้ายาม',
    'ดาบรุ่งอรุณ',
    'แห่งเถ้าถ่าน',
    'ผู้ถือคำสัตย์',
    'แห่งหมอก',
    'ผู้รอดกลับมา',
    'แห่งระฆังเงิน',
    'ผู้ล่าเงา',
    'แห่งคบเพลิง',
  ];

  static HeroModel rollGacha({
    required bool isSpecial,
    Set<String> existingNames = const {},
  }) {
    final startLevel = _rollLevelRates(isSpecial: isSpecial);
    return _generateHeroByLevel(
      startLevel,
      existingNames: existingNames,
    );
  }

  static int _rollLevelRates({required bool isSpecial}) {
    final roll = _rand.nextDouble() * 100;

    if (!isSpecial) {
      if (roll < 0.00000005) {
        final ultraRoll = _rand.nextDouble() * 100;
        if (ultraRoll < 1.0) return _randomLevelInRarity(5);
        if (ultraRoll < 10.0) return _randomLevelInRarity(4);
        return _randomLevelInRarity(3);
      } else if (roll < 5.0) {
        return _randomLevelInRarity(2);
      } else {
        return _randomLevelInRarity(1);
      }
    }

    if (roll < 5.0) return _randomLevelInRarity(5);
    if (roll < 25.0) return _randomLevelInRarity(4);
    if (roll < 70.0) return _randomLevelInRarity(3);
    return _randomLevelInRarity(2);
  }

  static int _randomLevelInRarity(int rarity) {
    switch (rarity) {
      case 1:
        return 1 + _rand.nextInt(LevelingPolicy.star2MinLevel - 1);
      case 2:
        return LevelingPolicy.star2MinLevel +
            _rand.nextInt(
              LevelingPolicy.star3MinLevel - LevelingPolicy.star2MinLevel,
            );
      case 3:
        return LevelingPolicy.star3MinLevel +
            _rand.nextInt(
              LevelingPolicy.star4MinLevel - LevelingPolicy.star3MinLevel,
            );
      case 4:
        return LevelingPolicy.star4MinLevel +
            _rand.nextInt(
              LevelingPolicy.star5MinLevel - LevelingPolicy.star4MinLevel,
            );
      case 5:
      default:
        return LevelingPolicy.star5MinLevel +
            _rand.nextInt(
              LevelingPolicy.maxLevel - LevelingPolicy.star5MinLevel + 1,
            );
    }
  }

  static HeroModel _generateHeroByLevel(
    int initLevel, {
    required Set<String> existingNames,
  }) {
    final heroId = 'H${1000 + _rand.nextInt(900000)}';
    final name = _generateUniqueName(existingNames);
    final gender = _rand.nextBool() ? 'ชาย' : 'หญิง';
    final age = 16 + _rand.nextInt(30);
    final initialRarity = LevelingPolicy.rarityFromLevel(initLevel);

    final baseMult = initialRarity * 10;
    final stats = HeroStats(
      maxHp: 100 * baseMult + _rand.nextInt(50),
      currentHp: 100 * baseMult + _rand.nextInt(50),
      atk: 10 * baseMult + _rand.nextInt(10),
      def: 8 * baseMult + _rand.nextInt(10),
      spd: 5 * baseMult + _rand.nextInt(5),
      maxEng: 100,
      currentEng: 100,
      luk: initialRarity * 5 + _rand.nextInt(5),
    );

    final jobs = ['อัศวิน', 'นักเวท', 'โจร', 'ช่างตีเหล็ก', 'ชาวนา', 'หมอ']
      ..shuffle(_rand);

    final a1 = (_rand.nextInt(50) + 20) / 100.0;
    final a2 = (_rand.nextInt(100 - (a1 * 100).toInt())) / 100.0;
    final a3 = 1.0 - a1 - a2;

    return HeroModel(
      id: heroId,
      name: name,
      gender: gender,
      age: age,
      backgroundStory: 'นักผจญภัยที่ถูกอัญเชิญมาจากหินวิญญาณแห่งหอคอยบรรพกาล',
      level: initLevel,
      baseStats: stats,
      currentStats: stats.clone(),
      aptitudes: {
        jobs[0]: a1,
        jobs[1]: a2,
        jobs[2]: a3,
      },
      currentExp: 0,
      bond: 15 + _rand.nextInt(26),
      faith: 10 + _rand.nextInt(31),
    );
  }

  static String _generateUniqueName(Set<String> existingNames) {
    final candidates = <String>[
      ..._baseNames,
      for (final name in _baseNames)
        for (final title in _nameTitles) '$name$title',
    ]..shuffle(_rand);

    for (final candidate in candidates) {
      if (!existingNames.contains(candidate)) {
        return candidate;
      }
    }

    final root = _baseNames[_rand.nextInt(_baseNames.length)];
    var suffix = 2;
    while (true) {
      final candidate = '$root-$suffix';
      if (!existingNames.contains(candidate)) {
        return candidate;
      }
      suffix += 1;
    }
  }
}
