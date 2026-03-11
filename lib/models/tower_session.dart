import 'party_model.dart';
import 'item_model.dart';

class TowerSession {
  final String sessionId;
  int currentFloor;
  
  PartyModel activeParty; 
  
  List<ItemModel> collectedLoot; 
  bool isAutoBattleActive;

  TowerSession({
    required this.sessionId,
    this.currentFloor = 1,
    required this.activeParty,
    this.collectedLoot = const [],
    this.isAutoBattleActive = true, // หอคอยใช้ Auto-skill/Auto-battle เป็นหลัก
  });
}
