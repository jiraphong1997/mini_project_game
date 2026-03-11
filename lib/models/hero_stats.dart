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
}
