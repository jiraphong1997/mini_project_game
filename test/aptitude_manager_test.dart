import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/aptitude_manager.dart'; // ตรวจสอบ path ให้ตรงกับโปรเจกต์จริง

void main() {
  group('AptitudeManager Tests', () {
    
    test('สมดุลความถนัด: เมื่อเพิ่มค่าหนึ่ง ค่าอื่นต้องลดลง และผลรวมต้องเท่ากับ 1.0', () {
      // Setup: มี 3 อาชีพ แบ่งกันคนละ 0.33, 0.33, 0.34 (รวม 1.0)
      final currentAptitudes = {
        'Knight': 0.33,
        'Mage': 0.33,
        'Thief': 0.34,
      };

      // Action: เพิ่ม Knight อีก 0.1 (10%)
      final result = AptitudeManager.updateAptitude(currentAptitudes, 'Knight', 0.1);

      // Expect: 
      // Knight ควรเป็น 0.33 + 0.1 = 0.43
      // ส่วนเกิน 0.1 จะถูกหักออกจาก Mage และ Thief คนละ 0.05
      // Mage ควรเป็น 0.33 - 0.05 = 0.28
      // Thief ควรเป็น 0.34 - 0.05 = 0.29
      
      expect(result['Knight'], closeTo(0.43, 0.0001));
      expect(result['Mage'], closeTo(0.28, 0.0001));
      expect(result['Thief'], closeTo(0.29, 0.0001));
      
      // ตรวจสอบผลรวมต้องได้ 1.0
      double sum = result.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('Cap สูงสุด: ค่าความถนัดต้องไม่เกิน 1.0 และค่าอื่นต้องเป็น 0', () {
      final currentAptitudes = {
        'Knight': 0.5,
        'Mage': 0.5,
      };

      // เพิ่ม Knight ไปอีก 0.8 (ซึ่งจะทำให้เกิน 1.0 ถ้ารวมตรงๆ)
      final result = AptitudeManager.updateAptitude(currentAptitudes, 'Knight', 0.8);

      // Knight ควรตันที่ 1.0
      expect(result['Knight'], 1.0);
      // Mage ควรเหลือ 0.0
      expect(result['Mage'], 0.0);
      
      double sum = result.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('เมื่อ job หนึ่งลดลงจนเหลือ 0 ระบบยังต้องเกลี่ยต่อจนผลรวมกลับมาเป็น 1.0', () {
      final currentAptitudes = {
        'Knight': 0.90,
        'Mage': 0.09,
        'Thief': 0.01,
      };

      final result = AptitudeManager.updateAptitude(currentAptitudes, 'Knight', 0.1);

      expect(result['Knight'], closeTo(1.0, 0.0001));
      expect(result['Mage'], closeTo(0.0, 0.0001));
      expect(result['Thief'], closeTo(0.0, 0.0001));

      final sum = result.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
    });

  });
}
