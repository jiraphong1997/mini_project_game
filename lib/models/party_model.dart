import 'hero_model.dart';

class PartyModel {
  String partyId;
  String partyName;
  
  // สมาชิกในปาร์ตี้ต้องมีอย่างน้อย 1 คน และสูงสุด 5 คน
  List<HeroModel> members; 
  
  // 'idle', 'tower_climbing', 'training'
  String status; 
  String formation;

  PartyModel({
    required this.partyId,
    required this.partyName,
    required this.members,
    this.status = 'idle',
    this.formation = 'balanced',
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

  List<String> get memberIds => members.map((hero) => hero.id).toList();

  int get aliveMembersCount => members.where((hero) => hero.isAlive).length;

  String get formationLabel {
    switch (formation) {
      case 'assault':
        return 'Assault';
      case 'bulwark':
        return 'Bulwark';
      case 'swift':
        return 'Swift';
      default:
        return 'Balanced';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'partyId': partyId,
      'partyName': partyName,
      'memberIds': memberIds,
      'status': status,
      'formation': formation,
    };
  }

  factory PartyModel.fromMap(
    Map<String, dynamic> map,
    List<HeroModel> allHeroes,
  ) {
    final memberIds = (map['memberIds'] as List<dynamic>? ?? const [])
        .map((id) => id.toString())
        .toList();
    final members = allHeroes
        .where((hero) => memberIds.contains(hero.id))
        .toList();

    return PartyModel(
      partyId: map['partyId'] as String,
      partyName: map['partyName'] as String,
      members: members,
      status: map['status'] as String? ?? 'idle',
      formation: map['formation'] as String? ?? 'balanced',
    );
  }
}
