import 'party_model.dart';
import 'hero_model.dart';

class PlayerData {
  String playerId;
  String playerName;
  
  int silver; // เงินในเกม ใช้จ่ายในร้านค้าและอัปเกรด
  int gold;   // ค่าเงินพรีเมียม ใช้แลก Silver และตั๋วสุ่มฮีโร่
  
  int baseBuildingLevel; 
  
  List<PartyModel> savedParties; 
  List<HeroModel> allHeroes;

  PlayerData({
    required this.playerId,
    required this.playerName,
    this.silver = 0,
    this.gold = 0,
    this.baseBuildingLevel = 1,
    this.savedParties = const [],
    this.allHeroes = const [],
  });

  // Base Power = ระดับสิ่งก่อสร้าง + เลเวลฮีโร่ทั้งหมด + พลังปาร์ตี้หรืออะไรทำนองนี้
  int get basePower {
    int totalHeroPower = 0;
    for (var hero in allHeroes) {
      totalHeroPower += hero.level * 10; // สมมติสูตร: ฮีโร่ 1 เลเวล = 10 power
      totalHeroPower += hero.currentStats.atk + hero.currentStats.def; 
    }
    
    // พลังรวมฐาน = โบนัสเลเวลของฐานบ้าน + พลังฮีโร่รวมทั้งหมด
    return (baseBuildingLevel * 100) + totalHeroPower;
  }
}
