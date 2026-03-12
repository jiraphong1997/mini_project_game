# โครงสร้างข้อมูล (Data Models) สำหรับระบบใน Flutter

อ้างอิงจากแผนการออกแบบเกม (GDD) เราสามารถแบ่ง Model หลักๆ ออกเป็นคลาสสำหรับโปรเจกต์ Flutter/Dart ได้ดังนี้:

## 1. Hero Model
คลาสที่เป็นศูนย์กลางของเกม จัดเก็บข้อมูลทั้งหมดที่เกี่ยวข้องกับฮีโร่แต่ละตัว

```dart
class HeroModel {
  final String id;
  final String name;
  final String gender; // เพศของฮีโร่ (Background Story)
  final int age;       // อายุของฮีโร่ (Background Story)
  final String backgroundStory; // ประวัติความเป็นมาของฮีโร่
  final int rarity; // ระดับความหายาก 1-5
  
  // สายอาชีพจะเปลี่ยนไปตามความถนัดที่มีค่าเปอร์เซ็นต์สูงสุด
  String get currentJobRole {
    if (aptitudes.isEmpty) return 'Novice';
    return aptitudes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int level;
  int currentExp;
  
  HeroStats baseStats; // สเตตัสพื้นฐาน (HP, ATK, DEF, ฯลฯ)
  HeroStats currentStats; // สเตตัสใช้งานจริงรวมโบนัส
  
  Map<String, double> aptitudes; // ค่าความถนัดรวมกันต้องไม่เกิน 1.0 (100%)
  
  List<SkillModel> skills; // สกิลที่มี (สูงสุดเลเวล 10)
  List<ItemModel> equipments; // ไอเทมสวมใส่ รวมถึง "หินวาร์ปกลับ"
  
  bool isAlive; // สถานะการมีชีวิต (Permadeath)
  bool isInTower; // กำลังปีนหอคอยอยู่หรือไม่
}
```

## 2. Hero Stats & Aptitude
ค่าความสามารถและสเตตัสต่างๆ

```dart
class HeroStats {
  int maxHp;
  int currentHp;
  int atk;
  int def;
  int spd;
  int maxEng; // พลังงานความเหนื่อยล้าสูงสุด
  int currentEng;
  int luk;
}

// ตัวอย่างกติกาค่าความถนัด: เกลี่ย % หากผลรวมเกิน 100
class AptitudeManager {
  // Updated: คืนค่าเป็น Map ใหม่เพื่อความ Immutability
  static Map<String, double> updateAptitude(Map<String, double> currentAptitudes, String targetJob, double increaseAmount) {
    // 1. เพิ่มค่าเป้าหมาย
    // 2. คำนวณส่วนเกิน
    // 3. หักลบค่าอื่นๆ เฉลี่ยกันให้ผลรวมกลับมาเป็น 1.0
    return newAptitudes;
  }
}
```

## 3. Item Model
คลาสสำหรับไอเทม อุปกรณ์ และของดรอปในหอคอย

```dart
enum ItemType { weapon, armor, consumable, material, warpItem }

class ItemModel {
  final String id;
  final String name;
  final ItemType type;
  final int rarity; // ระดับความยากการดรอป 1-5 (เหมือนระดับฮีโร่)
  
  // โบนัสเสริมที่จะบวกไปกับ HeroStats
  final HeroStats? statBonus; 
  
  // จำนวนที่มี หรือ จำนวนการใช้งาน(Durability สำหรับ warpItem)
  int quantity; 
}
```

## 4. Skill Model
ระบบสกิลที่จะปลดล็อคตามเงื่อนไข

```dart
class SkillModel {
  final String id;
  final String name;
  final String description;
  final String unlockCondition; // เช็คเงื่อนไขจาก Data กลาง
  
  int level; // เลเวลสกิล Max ที่ 10
  bool isUnlocked;
  
  // ค่า Effect (ใช้ในการคำนวณตอน Auto-Battle/Auto-Skill)
  double damageMultiplier;
  double healAmount;
}
```

## 5. Party Model
ระบบจัดทีม/ปาร์ตี้ (Party System) สำหรับการฝึกฝนและตะลุยหอคอย

```dart
class PartyModel {
  String partyId;
  String partyName;
  
  // ตำแหน่งในทีมน่าจะมีผลต่อการต่อสู้ เช่น ฮีโร่ตัวแรกเป็นแทงค์จะโดนตีบ่อยสุด
  // เงื่อนไข: สมาชิกในปาร์ตี้ต้องมีอย่างน้อย 1 คน และสูงสุด 5 คน
  List<HeroModel> members; 
  
  // สถานะว่าปาร์ตี้นี้กำลังทำอะไรอยู่ เช่น 'idle', 'tower_climbing', 'training'
  String status; 
  
  int get partyPower {
    // รวมสเตตัสและอุปกรณ์ของทุกคนในทีม
    return 0;
  }
}
```

## 6. Tower Progression Model
ส่วนควบคุมการตะลุยหอคอยและการส่งฮีโร่ขึ้นไปต่อสู้ (Auto Battle แบบทีม)

```dart
class TowerSession {
  final String sessionId;
  int currentFloor;
  PartyModel activeParty; // ใช้ระบบปาร์ตี้แทนฮีโร่รายตัว
  
  List<ItemModel> collectedLoot; // ของดรอปที่รวบรวมได้ (Rarity 1-5)
  bool isAutoBattleActive;
  
  // ฟังก์ชั่นเช็คความตาย ถอดไอเทมวาร์ปออกถ้าถูกใช้งานเมื่อ HP=0
}
```

## 7. Player Record / Economy
ข้อมูลรวมของผู้เล่น เงินตรา และระดับของฐานภาพรวม

```dart
class PlayerData {
  String playerId;
  String playerName;
  
  int silver; // เงินในเกม
  int gold;   // ค่าเงิน Premium ที่ใช้แลก Silver และเปิดกาชา
  
  int baseBuildingLevel; // ระดับภาพรวมสิ่งก่อสร้าง
  
  List<PartyModel> savedParties; // จัดทีมทิ้งไว้เตรียมลงหอ
  
  // คำนวณ Base Power (ค่าพลังรวม)
  int get basePower {
    // = ระดับสิ่งก่อสร้าง + เลเวลฮีโร่รวม + พลังอุปกรณ์
    return 0; // รอสูตร
  }
}
```
