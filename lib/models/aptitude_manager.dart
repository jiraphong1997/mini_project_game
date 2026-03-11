class AptitudeManager {
  // ฟังก์ชันปรับค่าความถนัด ให้ผลรวมทั้งหมดไม่เกิน 1.0 (100%)
  static void updateAptitude(Map<String, double> aptitudes, String targetJob, double increaseValue) {
    if (!aptitudes.containsKey(targetJob)) {
      aptitudes[targetJob] = 0.0;
    }

    double originalValue = aptitudes[targetJob]!;
    double newValue = (originalValue + increaseValue).clamp(0.0, 1.0);
    double difference = newValue - originalValue;

    aptitudes[targetJob] = newValue;

    // คำนวณลดค่าตัวอื่นๆ ลงเท่าๆ กัน
    if (difference > 0 && aptitudes.length > 1) {
      double deductionPerJob = difference / (aptitudes.length - 1);
      
      for (var key in aptitudes.keys.toList()) {
        if (key != targetJob) {
          aptitudes[key] = (aptitudes[key]! - deductionPerJob).clamp(0.0, 1.0);
        }
      }
    }
  }
}
