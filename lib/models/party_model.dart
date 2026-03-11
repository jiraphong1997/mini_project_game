import 'hero_model.dart';

class PartyModel {
  String partyId;
  String partyName;
  
  // สมาชิกในปาร์ตี้ต้องมีอย่างน้อย 1 คน และสูงสุด 5 คน
  List<HeroModel> members; 
  
  // 'idle', 'tower_climbing', 'training'
  String status; 

  PartyModel({
    required this.partyId,
    required this.partyName,
    required this.members,
    this.status = 'idle',
  });

  // คำนวณพลังรวมของปาร์ตี้ (Total Power)
  int get partyPower {
    int totalPower = 0;
    for (var hero in members) {
      if (hero.isAlive) {
        // ตัวอย่างสูตรประเมินพลังคร่าวๆ จาก Status
        totalPower += hero.currentStats.maxHp +
            (hero.currentStats.atk * 2) +
            (hero.currentStats.def * 2) +
            hero.currentStats.spd;
      }
    }
    return totalPower;
  }
}
