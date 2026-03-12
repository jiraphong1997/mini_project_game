import 'dart:math';
import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import 'leveling_policy.dart';

class GachaManager {
  static final Random _rand = Random();

  static const int commonCost = 100; // ใช้ 100 Gold
  static const int specialCost = 500; // ใช้ 500 Gold

  // สุ่มหาตัวละคร
  static HeroModel rollGacha({required bool isSpecial}) {
    int startLevel = _rollLevelRates(isSpecial: isSpecial);
    return _generateHeroByLevel(startLevel);
  }

  // ระบบสุ่มอ้างอิงและเกิดมาพร้อม "เลเวลเริ่มต้น" (Level 1 - 9999)
  static int _rollLevelRates({required bool isSpecial}) {
    // ใช้ nextDouble() เพื่อความละเอียดทศนิยม: สุ่มตั้งแต่ 0.0000 แน่นอนไปจนถึง 99.9999
    double roll = _rand.nextDouble() * 100;

    if (!isSpecial) {
      // ตู้ปกติ: โอกาสดรอปตัว Epic ขึ้นไป (Level 80+) ต่ำกว่า 0.0000001%
      if (roll < 0.00000005) {
        // แม้จะเข้าเรทแจ็คพ็อต ก็ยังต้องสุ่มว่าจะได้ช่วงดาวไหน
        double ultraRoll = _rand.nextDouble() * 100;
        if (ultraRoll < 1.0) return _randomLevelInRarity(5);  // 5 ดาว (1%)
        if (ultraRoll < 10.0) return _randomLevelInRarity(4); // 4 ดาว (9%)
        return _randomLevelInRarity(3);                        // 3 ดาว (90%)
      } else if (roll < 5.0) {
        return _randomLevelInRarity(2); // 2 ดาว Rare (ประมาณ 5% ในตู้ปกติ)
      } else {
        return _randomLevelInRarity(1); // 1 ดาว Common (ส่วนใหญ่ตกช่วงเลเวลระดับต้น)
      }
    } else {
      // ตู้พิเศษ (Premium) - โอกาสได้ของดีสูงขึ้น
      if (roll < 5.0) return _randomLevelInRarity(5);  // 5 ดาว (5%)
      if (roll < 25.0) return _randomLevelInRarity(4); // 4 ดาว (20%)
      if (roll < 70.0) return _randomLevelInRarity(3); // 3 ดาว (45%)
      return _randomLevelInRarity(2);                  // แย่สุด 2 ดาว (30%)
    }
  }

  static int _randomLevelInRarity(int rarity) {
    switch (rarity) {
      case 1:
        return 1 + _rand.nextInt(LevelingPolicy.star2MinLevel - 1); // 1-19
      case 2:
        return LevelingPolicy.star2MinLevel +
            _rand.nextInt(LevelingPolicy.star3MinLevel - LevelingPolicy.star2MinLevel); // 20-79
      case 3:
        return LevelingPolicy.star3MinLevel +
            _rand.nextInt(LevelingPolicy.star4MinLevel - LevelingPolicy.star3MinLevel); // 80-319
      case 4:
        return LevelingPolicy.star4MinLevel +
            _rand.nextInt(LevelingPolicy.star5MinLevel - LevelingPolicy.star4MinLevel); // 320-1279
      case 5:
      default:
        return LevelingPolicy.star5MinLevel +
            _rand.nextInt(LevelingPolicy.maxLevel - LevelingPolicy.star5MinLevel + 1); // 1280-9999
    }
  }

  // สร้าง Hero แบบสุ่มจากเลเวลเกิด
  static HeroModel _generateHeroByLevel(int initLevel) {
    int idNumber = _rand.nextInt(9999);
    String heroId = 'H$idNumber';
    
    List<String> names = ['เลออน', 'เฟรยา', 'อาเธอร์', 'ลูคัส', 'ไคล์', 'โซเฟีย', 'อีริค', 'อลิซ']; // สุ่มชื่อ
    String name = names[_rand.nextInt(names.length)];
    String gender = _rand.nextBool() ? 'ชาย' : 'หญิง';
    int age = 16 + _rand.nextInt(30);

    // ดึงค่า Rarity เพื่อใช้เป็นตัวคูณ Status ตอนเกิด
    int initialRarity = LevelingPolicy.rarityFromLevel(initLevel);

    int baseMult = initialRarity * 10;
    HeroStats stats = HeroStats(
      maxHp: 100 * baseMult + _rand.nextInt(50),
      currentHp: 100 * baseMult + _rand.nextInt(50),
      atk: 10 * baseMult + _rand.nextInt(10),
      def: 8 * baseMult + _rand.nextInt(10),
      spd: 5 * baseMult + _rand.nextInt(5),
      maxEng: 100,
      currentEng: 100,
      luk: initialRarity * 5 + _rand.nextInt(5),
    );

    // สุ่ม Aptitude
    List<String> jobs = ['อัศวิน', 'นักเวท', 'โจร', 'ช่างตีเหล็ก', 'ชาวนา', 'หมอ'];
    jobs.shuffle();
    
    // แบ่งสัดส่วนออกเป็น 3 สายความถนัดรวมกัน 1.0
    double a1 = (_rand.nextInt(50) + 20) / 100.0; // 0.20 - 0.70
    double a2 = (_rand.nextInt((100 - (a1 * 100).toInt())) ) / 100.0;
    double a3 = 1.0 - a1 - a2;

    Map<String, double> aptitudes = {
      jobs[0]: a1,
      jobs[1]: a2,
      jobs[2]: a3,
    };

    return HeroModel(
      id: heroId,
      name: name,
      gender: gender,
      age: age,
      backgroundStory: 'นักผจญภัยที่ถูกอัญเชิญมาจากหินวิญญาณแห่งหอคอยบรรพกาล',
      level: initLevel,
      baseStats: stats,
      currentStats: stats.clone(), // แยก instance ออกจาก baseStats
      aptitudes: aptitudes,
      currentExp: 0,
      bond: 15 + _rand.nextInt(26),
      faith: 10 + _rand.nextInt(31),
    );
  }
}
