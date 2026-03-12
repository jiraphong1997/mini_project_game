class AptitudeManager {
  /// อัปเดตค่าความถนัดของเป้าหมาย และเกลี่ยค่าอื่นๆ ลงเพื่อให้ผลรวมยังคงเป็น 100% (1.0)
  static Map<String, double> updateAptitude(
    Map<String, double> currentAptitudes,
    String targetJob,
    double increaseAmount, // เช่น 0.05 คือเพิ่ม 5%
  ) {
    // สร้าง Map ใหม่เพื่อไม่ให้กระทบค่าเดิมโดยตรง (Immutability concept)
    final newAptitudes = Map<String, double>.from(currentAptitudes);

    // 1. ตรวจสอบว่ามี targetJob หรือไม่ ถ้าไม่มีให้เพิ่มเข้าไป
    if (!newAptitudes.containsKey(targetJob)) {
      newAptitudes[targetJob] = 0.0;
    }

    // 2. เพิ่มค่าความถนัดเป้าหมาย (Cap ไว้ที่ 1.0)
    double oldValue = newAptitudes[targetJob]!;
    double newValue = (oldValue + increaseAmount).clamp(0.0, 1.0);
    newAptitudes[targetJob] = newValue;

    // 3. คำนวณส่วนเกินที่ต้องไปหักลบออกจาก Job อื่นๆ
    // ผลรวมทั้งหมดตอนนี้อาจจะเกิน 1.0
    double currentSum = newAptitudes.values.reduce((a, b) => a + b);
    
    if (currentSum > 1.0) {
      double excess = currentSum - 1.0;
      var otherJobs = newAptitudes.keys
          .where((key) => key != targetJob && newAptitudes[key]! > 0.0)
          .toList();

      while (excess > 0.000001 && otherJobs.isNotEmpty) {
        final deductPerJob = excess / otherJobs.length;
        double reducedTotal = 0.0;

        for (final job in otherJobs) {
          final currentValue = newAptitudes[job]!;
          final actualDeduction = currentValue < deductPerJob
              ? currentValue
              : deductPerJob;
          newAptitudes[job] = currentValue - actualDeduction;
          reducedTotal += actualDeduction;
        }

        excess -= reducedTotal;
        otherJobs = newAptitudes.keys
            .where((key) => key != targetJob && newAptitudes[key]! > 0.0)
            .toList();
      }

      if (otherJobs.isEmpty) {
        newAptitudes[targetJob] = 1.0;
      }
    }

    final normalizedSum = newAptitudes.values.reduce((a, b) => a + b);
    final drift = 1.0 - normalizedSum;
    if (drift.abs() > 0.000001) {
      newAptitudes[targetJob] =
          (newAptitudes[targetJob]! + drift).clamp(0.0, 1.0);
    }

    return newAptitudes;
  }
}
