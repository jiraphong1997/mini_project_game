import 'party_model.dart';
import 'hero_model.dart';
import 'item_model.dart';

class PlayerData {
  String playerId;
  String playerName;
  
  int silver; // เงินในเกม ใช้จ่ายในร้านค้าและอัปเกรด
  int gold;   // ค่าเงินพรีเมียม ใช้แลก Silver และตั๋วสุ่มฮีโร่
  
  int baseBuildingLevel; 
  int highestTowerFloor;
  String? lastTowerSummary;
  List<int> resolvedMajorEventFloors;
  List<String> recentMajorEventIds;
  String? pendingMajorChainEventId;
  List<String> pendingMajorChainEventIds;
  List<String> resolvedMajorChainEventIds;
  
  List<PartyModel> savedParties; 
  List<HeroModel> allHeroes;
  List<ItemModel> inventory;

  PlayerData({
    required this.playerId,
    required this.playerName,
    this.silver = 0,
    this.gold = 0,
    this.baseBuildingLevel = 1,
    this.highestTowerFloor = 0,
    this.lastTowerSummary,
    this.resolvedMajorEventFloors = const [],
    this.recentMajorEventIds = const [],
    this.pendingMajorChainEventId,
    this.pendingMajorChainEventIds = const [],
    this.resolvedMajorChainEventIds = const [],
    this.savedParties = const [],
    this.allHeroes = const [],
    this.inventory = const [],
  }) {
    if (pendingMajorChainEventIds.isEmpty && pendingMajorChainEventId != null) {
      pendingMajorChainEventIds = [pendingMajorChainEventId!];
    } else if (pendingMajorChainEventIds.isNotEmpty) {
      pendingMajorChainEventId = pendingMajorChainEventIds.first;
    }
  }

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

  int itemQuantity(String itemId) {
    final item = inventory.where((entry) => entry.id == itemId);
    if (item.isEmpty) {
      return 0;
    }
    return item.first.quantity;
  }

  bool consumeItem(String itemId, {int quantity = 1}) {
    if (quantity <= 0) {
      return true;
    }

    final updatedInventory = [...inventory];
    final index = updatedInventory.indexWhere((item) => item.id == itemId);
    if (index < 0 || updatedInventory[index].quantity < quantity) {
      return false;
    }

    updatedInventory[index].quantity -= quantity;
    if (updatedInventory[index].quantity <= 0) {
      updatedInventory.removeAt(index);
    }
    inventory = updatedInventory;
    return true;
  }

  void addItemRewards(List<ItemModel> rewards) {
    final merged = [...inventory];

    for (final reward in rewards) {
      final existingIndex = merged.indexWhere((item) => item.id == reward.id);
      if (existingIndex >= 0) {
        merged[existingIndex].quantity += reward.quantity;
      } else {
        merged.add(
          ItemModel(
            id: reward.id,
            name: reward.name,
            type: reward.type,
            rarity: reward.rarity,
            statBonus: reward.statBonus?.clone(),
            equipmentSlot: reward.equipmentSlot,
            quantity: reward.quantity,
          ),
        );
      }
    }

    inventory = merged;
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'silver': silver,
      'gold': gold,
      'baseBuildingLevel': baseBuildingLevel,
      'highestTowerFloor': highestTowerFloor,
      'lastTowerSummary': lastTowerSummary,
      'resolvedMajorEventFloors': resolvedMajorEventFloors,
      'recentMajorEventIds': recentMajorEventIds,
      'pendingMajorChainEventId': pendingMajorChainEventIds.isEmpty
          ? pendingMajorChainEventId
          : pendingMajorChainEventIds.first,
      'pendingMajorChainEventIds': pendingMajorChainEventIds,
      'resolvedMajorChainEventIds': resolvedMajorChainEventIds,
      'savedParties': savedParties.map((party) => party.toMap()).toList(),
      'allHeroes': allHeroes.map((hero) => hero.toMap()).toList(),
      'inventory': inventory.map((item) => item.toMap()).toList(),
    };
  }

  factory PlayerData.fromMap(Map<String, dynamic> map) {
    final heroList = (map['allHeroes'] as List<dynamic>? ?? const [])
        .map((hero) => HeroModel.fromMap(Map<String, dynamic>.from(hero as Map)))
        .toList();
    final partyList = (map['savedParties'] as List<dynamic>? ?? const [])
        .map((party) => PartyModel.fromMap(Map<String, dynamic>.from(party as Map), heroList))
        .toList();
    final inventory = (map['inventory'] as List<dynamic>? ?? const [])
        .map((item) => ItemModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return PlayerData(
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String,
      silver: map['silver'] as int? ?? 0,
      gold: map['gold'] as int? ?? 0,
      baseBuildingLevel: map['baseBuildingLevel'] as int? ?? 1,
      highestTowerFloor: map['highestTowerFloor'] as int? ?? 0,
      lastTowerSummary: map['lastTowerSummary'] as String?,
      resolvedMajorEventFloors: (map['resolvedMajorEventFloors'] as List<dynamic>? ?? const [])
          .map((floor) => floor as int)
          .toList(),
      recentMajorEventIds: (map['recentMajorEventIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
      pendingMajorChainEventId: map['pendingMajorChainEventId'] as String?,
      pendingMajorChainEventIds:
          (map['pendingMajorChainEventIds'] as List<dynamic>? ?? const [])
              .map((id) => id.toString())
              .toList(),
      resolvedMajorChainEventIds:
          (map['resolvedMajorChainEventIds'] as List<dynamic>? ?? const [])
              .map((id) => id.toString())
              .toList(),
      savedParties: partyList,
      allHeroes: heroList,
      inventory: inventory,
    );
  }
}
