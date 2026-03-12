class HeroStats {
  int maxHp;
  int currentHp;
  int atk;
  int def;
  int spd;
  int maxEng;
  int currentEng;
  int luk;

  HeroStats({
    required this.maxHp,
    required this.currentHp,
    required this.atk,
    required this.def,
    required this.spd,
    required this.maxEng,
    required this.currentEng,
    required this.luk,
  });

  // Factory สำหรับสร้างค่าเริ่มต้น (แก้ไข Error: Member not found: 'HeroStats.initial')
  factory HeroStats.initial() {
    return HeroStats(
      maxHp: 100,
      currentHp: 100,
      atk: 10,
      def: 5,
      spd: 10,
      maxEng: 100,
      currentEng: 100,
      luk: 5,
    );
  }

  factory HeroStats.zero() {
    return HeroStats(
      maxHp: 0,
      currentHp: 0,
      atk: 0,
      def: 0,
      spd: 0,
      maxEng: 0,
      currentEng: 0,
      luk: 0,
    );
  }

  // ฟังก์ชันสำหรับคัดลอกค่า Deep Copy (แก้ไข Error: The method 'clone' isn't defined)
  HeroStats clone() {
    return HeroStats(
      maxHp: maxHp,
      currentHp: currentHp,
      atk: atk,
      def: def,
      spd: spd,
      maxEng: maxEng,
      currentEng: currentEng,
      luk: luk,
    );
  }

  // สร้างฟังก์ชันสำหรับคัดลอก/รวมสเตตัส (เช่น สเตตัสพื้นฐาน + โบนัสจากไอเทม)
  HeroStats copyWith(HeroStats bonus) {
    return HeroStats(
      maxHp: maxHp + bonus.maxHp,
      currentHp: currentHp + bonus.currentHp,
      atk: atk + bonus.atk,
      def: def + bonus.def,
      spd: spd + bonus.spd,
      maxEng: maxEng + bonus.maxEng,
      currentEng: currentEng + bonus.currentEng,
      luk: luk + bonus.luk,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxHp': maxHp,
      'currentHp': currentHp,
      'atk': atk,
      'def': def,
      'spd': spd,
      'maxEng': maxEng,
      'currentEng': currentEng,
      'luk': luk,
    };
  }

  factory HeroStats.fromMap(Map<String, dynamic> map) {
    return HeroStats(
      maxHp: map['maxHp'] as int,
      currentHp: map['currentHp'] as int,
      atk: map['atk'] as int,
      def: map['def'] as int,
      spd: map['spd'] as int,
      maxEng: map['maxEng'] as int,
      currentEng: map['currentEng'] as int,
      luk: map['luk'] as int,
    );
  }
}
