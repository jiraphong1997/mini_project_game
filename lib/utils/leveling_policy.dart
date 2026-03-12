class LevelingPolicy {
  static const int maxLevel = 9999;

    // เกณฑ์ดาวแบบขั้นบันได
    static const int star2MinLevel = 20;
    static const int star3MinLevel = 80;
    static const int star4MinLevel = 320;
    static const int star5MinLevel = 1280;

  // Time scaling: 1 วินาทีจริง = 4 วินาทีในเกม
  static const double inGameTimeScale = 4.0;

  // เป้าหมายหลัก: ปั้นฮีโร่ 1 ตัวจากเลเวล 1 ถึง 9999 ใช้เวลา 5 ปีจริง
  static const int targetRealYearsToMax = 5;
  static const int daysPerYear = 365;

  static const int targetRealDaysToMax = targetRealYearsToMax * daysPerYear; // 1,825
  static const int targetRealSecondsToMax = targetRealDaysToMax * 24 * 60 * 60;

  static final int targetInGameSecondsToMax =
      (targetRealSecondsToMax * inGameTimeScale).toInt();

  // ค่าประมาณเวลาเฉลี่ยต่อการอัปเลเวล 1 ขั้น (ใช้วางสมดุลระบบ EXP)
  static double get avgRealSecondsPerLevel =>
      targetRealSecondsToMax / (maxLevel - 1);

  static double get avgInGameSecondsPerLevel =>
      targetInGameSecondsToMax / (maxLevel - 1);

  static int rarityFromLevel(int level) {
    if (level < star2MinLevel) {
      return 1;
    }
    if (level < star3MinLevel) {
      return 2;
    }
    if (level < star4MinLevel) {
      return 3;
    }
    if (level < star5MinLevel) {
      return 4;
    }
    return 5;
  }

  static int expRequiredForNextLevel(int level) {
    final normalizedLevel = level.clamp(1, maxLevel);
    return 60 + (normalizedLevel * 14) + (normalizedLevel * normalizedLevel * 6);
  }
}
