import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import '../models/item_model.dart';
import '../models/player_data.dart';

class ItemCatalogEntry {
  final String id;
  final String name;
  final String description;
  final int silverCost;
  final int sellSilverValue;
  final int sellGoldValue;
  final int rarity;
  final ItemType type;
  final HeroStats? statBonus;
  final EquipmentSlot? equipmentSlot;
  final bool usableOnHero;
  final bool buyable;

  const ItemCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.silverCost,
    required this.sellSilverValue,
    this.sellGoldValue = 0,
    required this.rarity,
    required this.type,
    this.statBonus,
    this.equipmentSlot,
    this.usableOnHero = true,
    this.buyable = false,
  });

  bool get isEquippable => equipmentSlot != null;

  ItemModel toItemModel({int quantity = 1}) {
    return ItemModel(
      id: id,
      name: name,
      type: type,
      rarity: rarity,
      statBonus: statBonus?.clone(),
      equipmentSlot: equipmentSlot,
      quantity: quantity,
    );
  }
}

class CraftingRecipe {
  final String id;
  final String name;
  final String description;
  final Map<String, int> materials;
  final int silverCost;
  final ItemModel output;

  const CraftingRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.materials,
    required this.silverCost,
    required this.output,
  });
}

class ItemUseResult {
  final bool success;
  final String message;

  const ItemUseResult({
    required this.success,
    required this.message,
  });
}

class ItemSellResult {
  final bool success;
  final String message;
  final int silverEarned;
  final int goldEarned;

  const ItemSellResult({
    required this.success,
    required this.message,
    this.silverEarned = 0,
    this.goldEarned = 0,
  });
}

class CraftingResult {
  final bool success;
  final String message;

  const CraftingResult({
    required this.success,
    required this.message,
  });
}

class ItemUsageService {
  static final List<ItemCatalogEntry> _definitions = [
    const ItemCatalogEntry(
      id: 'ration_pack',
      name: 'เสบียงสนาม',
      description: 'ของกินพร้อมใช้ ฟื้น HP/ENG และเร่งพักฟื้น',
      silverCost: 80,
      sellSilverValue: 30,
      rarity: 1,
      type: ItemType.consumable,
      buyable: true,
    ),
    const ItemCatalogEntry(
      id: 'battle_tonic',
      name: 'ยาบำรุงกำลัง',
      description: 'ของใช้สำหรับเพิ่ม ATK ถาวรเล็กน้อย',
      silverCost: 180,
      sellSilverValue: 70,
      rarity: 2,
      type: ItemType.consumable,
      buyable: true,
    ),
    const ItemCatalogEntry(
      id: 'guard_tonic',
      name: 'ยาบำรุงป้องกัน',
      description: 'ของใช้สำหรับเพิ่ม DEF ถาวรเล็กน้อย',
      silverCost: 180,
      sellSilverValue: 70,
      rarity: 2,
      type: ItemType.consumable,
      buyable: true,
    ),
    const ItemCatalogEntry(
      id: 'swift_tonic',
      name: 'ยาบำรุงความคล่องตัว',
      description: 'ของใช้สำหรับเพิ่ม SPD ถาวรเล็กน้อย',
      silverCost: 180,
      sellSilverValue: 70,
      rarity: 2,
      type: ItemType.consumable,
      buyable: true,
    ),
    const ItemCatalogEntry(
      id: 'trust_token',
      name: 'เครื่องรางใจ',
      description: 'ของใช้เพิ่ม Bond',
      silverCost: 140,
      sellSilverValue: 55,
      rarity: 2,
      type: ItemType.consumable,
      buyable: true,
    ),
    const ItemCatalogEntry(
      id: 'prayer_candle',
      name: 'เทียนอธิษฐาน',
      description: 'ของใช้เพิ่ม Faith',
      silverCost: 140,
      sellSilverValue: 55,
      rarity: 2,
      type: ItemType.consumable,
      buyable: true,
    ),
    ItemCatalogEntry(
      id: 'beast_meat',
      name: 'เนื้อสัตว์ดิบ',
      description: 'ของกินดิบจากมอนสเตอร์ ใช้ย่างเป็นเสบียงหรือกินด่วนเพื่อฟื้นแรงเล็กน้อย',
      silverCost: 0,
      sellSilverValue: 14,
      rarity: 1,
      type: ItemType.consumable,
    ),
    const ItemCatalogEntry(
      id: 'cloth_scrap',
      name: 'เศษผ้า',
      description: 'ส่วนประกอบชุดเกราะและของใช้',
      silverCost: 0,
      sellSilverValue: 12,
      rarity: 1,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'iron_shard',
      name: 'เศษเหล็ก',
      description: 'ส่วนประกอบอาวุธและชุดเกราะ',
      silverCost: 0,
      sellSilverValue: 18,
      rarity: 1,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'monster_bone',
      name: 'กระดูกมอนสเตอร์',
      description: 'ส่วนประกอบอาวุธเบาและของใช้เสริม',
      silverCost: 0,
      sellSilverValue: 20,
      rarity: 1,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'tower_ore_1',
      name: 'หินแร่หอคอย',
      description: 'วัตถุดิบพื้นฐานสำหรับยาและอุปกรณ์',
      silverCost: 0,
      sellSilverValue: 18,
      rarity: 1,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'tower_ore_2',
      name: 'แร่หอคอยชั้นดี',
      description: 'วัตถุดิบระดับกลางสำหรับชุดเกราะและอาวุธ',
      silverCost: 0,
      sellSilverValue: 34,
      rarity: 2,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'tower_ore_3',
      name: 'แร่เวทหอคอย',
      description: 'วัตถุดิบหายากสำหรับของศรัทธาและอุปกรณ์ชั้นสูง',
      silverCost: 0,
      sellSilverValue: 60,
      sellGoldValue: 1,
      rarity: 3,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'tower_ore_4',
      name: 'แร่โบราณหอคอย',
      description: 'วัตถุดิบระดับสูงมาก มักใช้กับของพิเศษ',
      silverCost: 0,
      sellSilverValue: 90,
      sellGoldValue: 2,
      rarity: 4,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'class_trial_seal',
      name: 'ตราทดสอบคลาส',
      description: 'ของใช้พิเศษสำหรับปลดล็อกคลาสแบบข้ามเงื่อนไข',
      silverCost: 0,
      sellSilverValue: 120,
      sellGoldValue: 1,
      rarity: 3,
      type: ItemType.consumable,
    ),
    const ItemCatalogEntry(
      id: 'shrine_relic',
      name: 'เศษศาสตราวัตถุ',
      description: 'ชิ้นส่วนศักดิ์สิทธิ์ ใช้สร้างของศรัทธาและขายได้ราคาดี',
      silverCost: 0,
      sellSilverValue: 140,
      sellGoldValue: 1,
      rarity: 3,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'relic_shard',
      name: 'ชิ้นสะเก็ดเรลิก',
      description: 'วัตถุดิบพิเศษสำหรับสร้างเครื่องรางหรือแลกเงิน',
      silverCost: 0,
      sellSilverValue: 90,
      sellGoldValue: 1,
      rarity: 3,
      type: ItemType.material,
      usableOnHero: false,
    ),
    const ItemCatalogEntry(
      id: 'survivor_cache',
      name: 'หีบเสบียงผู้รอดชีวิต',
      description: 'ลังของใช้ฉุกเฉิน ใช้เปิดเสริมเสบียงให้ฮีโร่',
      silverCost: 0,
      sellSilverValue: 55,
      rarity: 2,
      type: ItemType.consumable,
    ),
    ItemCatalogEntry(
      id: 'steel_blade',
      name: 'ดาบเหล็ก',
      description: 'อาวุธพื้นฐานของสายบุก ATK +8',
      silverCost: 260,
      sellSilverValue: 110,
      rarity: 2,
      type: ItemType.weapon,
      equipmentSlot: EquipmentSlot.weapon,
      statBonus: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 8,
        def: 0,
        spd: 0,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
      buyable: true,
    ),
    ItemCatalogEntry(
      id: 'ranger_bow',
      name: 'ธนูพราน',
      description: 'อาวุธเบา ATK +5, SPD +4',
      silverCost: 260,
      sellSilverValue: 110,
      rarity: 2,
      type: ItemType.weapon,
      equipmentSlot: EquipmentSlot.weapon,
      statBonus: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 5,
        def: 0,
        spd: 4,
        maxEng: 0,
        currentEng: 0,
        luk: 1,
      ),
      buyable: true,
    ),
    ItemCatalogEntry(
      id: 'tower_mail',
      name: 'เกราะหอคอย',
      description: 'ชุดเกราะพื้นฐาน HP +30, DEF +6',
      silverCost: 240,
      sellSilverValue: 100,
      rarity: 2,
      type: ItemType.armor,
      equipmentSlot: EquipmentSlot.armor,
      statBonus: HeroStats(
        maxHp: 30,
        currentHp: 0,
        atk: 0,
        def: 6,
        spd: 0,
        maxEng: 0,
        currentEng: 0,
        luk: 0,
      ),
      buyable: true,
    ),
    ItemCatalogEntry(
      id: 'saints_emblem',
      name: 'ตราศรัทธา',
      description: 'เครื่องรางสายศรัทธา DEF +2, SPD +3, ENG +10, LUK +4',
      silverCost: 320,
      sellSilverValue: 150,
      sellGoldValue: 1,
      rarity: 3,
      type: ItemType.armor,
      equipmentSlot: EquipmentSlot.relic,
      statBonus: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 0,
        def: 2,
        spd: 3,
        maxEng: 10,
        currentEng: 0,
        luk: 4,
      ),
      buyable: true,
    ),
    ItemCatalogEntry(
      id: 'wayfinder_compass',
      name: 'เข็มทิศผู้บุกเบิก',
      description: 'รีลิกเฉพาะทางที่ช่วยมองเส้นทางลับและเปิด chain สายพ่อค้า',
      silverCost: 0,
      sellSilverValue: 220,
      sellGoldValue: 2,
      rarity: 4,
      type: ItemType.armor,
      equipmentSlot: EquipmentSlot.relic,
      statBonus: HeroStats(
        maxHp: 0,
        currentHp: 0,
        atk: 0,
        def: 0,
        spd: 6,
        maxEng: 15,
        currentEng: 0,
        luk: 8,
      ),
    ),
    ItemCatalogEntry(
      id: 'forge_heart',
      name: 'หัวใจเตาหลอม',
      description: 'รีลิกเฉพาะทางที่ปลุกเตาหลอมโบราณและเปิด chain สายช่างตีเหล็ก',
      silverCost: 0,
      sellSilverValue: 240,
      sellGoldValue: 2,
      rarity: 4,
      type: ItemType.armor,
      equipmentSlot: EquipmentSlot.relic,
      statBonus: HeroStats(
        maxHp: 20,
        currentHp: 0,
        atk: 5,
        def: 5,
        spd: 0,
        maxEng: 15,
        currentEng: 0,
        luk: 2,
      ),
    ),
    ItemCatalogEntry(
      id: 'sanctum_lantern',
      name: 'ตะเกียงศักดิ์สิทธิ์',
      description: 'รีลิกเฉพาะทางที่ทำให้เส้นทางศรัทธาเปิดเป็น chain ลึกขึ้น',
      silverCost: 0,
      sellSilverValue: 240,
      sellGoldValue: 2,
      rarity: 4,
      type: ItemType.armor,
      equipmentSlot: EquipmentSlot.relic,
      statBonus: HeroStats(
        maxHp: 10,
        currentHp: 0,
        atk: 0,
        def: 4,
        spd: 2,
        maxEng: 20,
        currentEng: 0,
        luk: 6,
      ),
    ),
  ];

  static final List<CraftingRecipe> _recipes = [
    CraftingRecipe(
      id: 'cook_ration',
      name: 'ย่างเสบียงสนาม',
      description: 'เปลี่ยนของกินกับเศษผ้าเป็นเสบียงพร้อมใช้',
      materials: const {'beast_meat': 2, 'cloth_scrap': 1},
      silverCost: 10,
      output: definitionFor('ration_pack')!.toItemModel(),
    ),
    CraftingRecipe(
      id: 'brew_tonic',
      name: 'กลั่นยาบำรุงกำลัง',
      description: 'ใช้แร่และของกินทำยาบำรุง ATK',
      materials: const {'tower_ore_1': 2, 'beast_meat': 1},
      silverCost: 25,
      output: definitionFor('battle_tonic')!.toItemModel(),
    ),
    CraftingRecipe(
      id: 'forge_blade',
      name: 'ตีดาบเหล็ก',
      description: 'ใช้เศษเหล็กและกระดูกขึ้นรูปเป็นอาวุธ',
      materials: const {'iron_shard': 3, 'monster_bone': 1, 'tower_ore_1': 1},
      silverCost: 45,
      output: definitionFor('steel_blade')!.toItemModel(),
    ),
    CraftingRecipe(
      id: 'forge_mail',
      name: 'เย็บเกราะหอคอย',
      description: 'ใช้เศษผ้าและเหล็กขึ้นรูปเป็นชุดเกราะ',
      materials: const {'cloth_scrap': 3, 'iron_shard': 2, 'tower_ore_2': 1},
      silverCost: 40,
      output: definitionFor('tower_mail')!.toItemModel(),
    ),
    CraftingRecipe(
      id: 'craft_emblem',
      name: 'ประกอบตราศรัทธา',
      description: 'ใช้ชิ้นส่วนเรลิกและแร่เวทสร้างเครื่องราง',
      materials: const {'relic_shard': 1, 'shrine_relic': 1, 'tower_ore_3': 1},
      silverCost: 75,
      output: definitionFor('saints_emblem')!.toItemModel(),
    ),
  ];

  static List<ItemCatalogEntry> get catalog =>
      List.unmodifiable(_definitions.where((entry) => entry.buyable));

  static List<CraftingRecipe> get recipes => List.unmodifiable(_recipes);

  static ItemCatalogEntry? definitionFor(String itemId) {
    for (final item in _definitions) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  static String categoryLabel(ItemModel item) {
    switch (item.type) {
      case ItemType.weapon:
        return 'อาวุธ';
      case ItemType.armor:
        return item.equipmentSlot == EquipmentSlot.relic ? 'เครื่องราง' : 'ชุดเกราะ';
      case ItemType.consumable:
        return 'ของใช้/ของกิน';
      case ItemType.material:
        return 'วัตถุดิบ';
      default:
        return 'ไอเทมพิเศษ';
    }
  }

  static bool buyItem(PlayerData playerData, String itemId) {
    final definition = definitionFor(itemId);
    if (definition == null ||
        !definition.buyable ||
        playerData.silver < definition.silverCost) {
      return false;
    }

    playerData.silver -= definition.silverCost;
    playerData.addItemRewards([definition.toItemModel()]);
    return true;
  }

  static ItemSellResult sellItem(
    PlayerData playerData,
    String itemId, {
    int quantity = 1,
  }) {
    final definition = definitionFor(itemId);
    final owned = playerData.itemQuantity(itemId);
    if (owned < quantity || quantity <= 0) {
      return const ItemSellResult(
        success: false,
        message: 'ไอเทมในคลังไม่พอสำหรับขาย',
      );
    }

    if (!playerData.consumeItem(itemId, quantity: quantity)) {
      return const ItemSellResult(
        success: false,
        message: 'ไม่สามารถหักไอเทมจากคลังได้',
      );
    }

    final item = definition;
    final silver = (item?.sellSilverValue ?? 10) * quantity;
    final gold = (item?.sellGoldValue ?? 0) * quantity;
    playerData.silver += silver;
    playerData.gold += gold;
    final name = item?.name ?? itemId;

    return ItemSellResult(
      success: true,
      message: gold > 0
          ? 'ขาย $name x$quantity ได้ $silver Silver และ $gold Gold'
          : 'ขาย $name x$quantity ได้ $silver Silver',
      silverEarned: silver,
      goldEarned: gold,
    );
  }

  static bool canCraft(PlayerData playerData, CraftingRecipe recipe) {
    if (playerData.silver < recipe.silverCost) {
      return false;
    }
    for (final entry in recipe.materials.entries) {
      if (playerData.itemQuantity(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }

  static CraftingResult craftItem(PlayerData playerData, String recipeId) {
    final recipe = _recipes.where((entry) => entry.id == recipeId);
    if (recipe.isEmpty) {
      return const CraftingResult(success: false, message: 'ไม่พบสูตรคราฟต์');
    }
    final selected = recipe.first;
    if (!canCraft(playerData, selected)) {
      return const CraftingResult(
        success: false,
        message: 'วัตถุดิบหรือ Silver ไม่พอสำหรับคราฟต์',
      );
    }

    for (final entry in selected.materials.entries) {
      playerData.consumeItem(entry.key, quantity: entry.value);
    }
    playerData.silver -= selected.silverCost;
    playerData.addItemRewards([selected.output]);
    return CraftingResult(
      success: true,
      message: 'คราฟต์ ${selected.output.name} สำเร็จ',
    );
  }

  static ItemUseResult equipItem(
    PlayerData playerData,
    HeroModel hero,
    String itemId,
  ) {
    final definition = definitionFor(itemId);
    if (definition == null || !definition.isEquippable) {
      return const ItemUseResult(success: false, message: 'ไอเทมนี้สวมใส่ไม่ได้');
    }
    if (!playerData.consumeItem(itemId)) {
      return ItemUseResult(
        success: false,
        message: 'ไม่มี ${definition.name} ในคลัง',
      );
    }

    final slot = definition.equipmentSlot!;
    final previousItemId = hero.equippedItemIdForSlot(slot);
    if (previousItemId != null) {
      final previousDefinition = definitionFor(previousItemId);
      if (previousDefinition != null) {
        playerData.addItemRewards([previousDefinition.toItemModel()]);
      }
    }

    hero.equipItem(definition.toItemModel());
    hero.totalItemsUsed += 1;
    return ItemUseResult(
      success: true,
      message: 'สวม ${definition.name} เรียบร้อย',
    );
  }

  static ItemUseResult unequipItem(
    PlayerData playerData,
    HeroModel hero,
    EquipmentSlot slot,
  ) {
    final itemId = hero.equippedItemIdForSlot(slot);
    if (itemId == null) {
      return const ItemUseResult(success: false, message: 'ช่องนี้ยังไม่มีอุปกรณ์');
    }

    final definition = definitionFor(itemId);
    hero.unequipSlot(slot);
    if (definition != null) {
      playerData.addItemRewards([definition.toItemModel()]);
    }
    return const ItemUseResult(
      success: true,
      message: 'ถอดอุปกรณ์กลับเข้าคลังแล้ว',
    );
  }

  static ItemUseResult useItem(
    PlayerData playerData,
    HeroModel hero,
    String itemId,
  ) {
    final definition = definitionFor(itemId);
    if (definition == null) {
      return const ItemUseResult(success: false, message: 'ไม่พบข้อมูลไอเทม');
    }
    if (definition.isEquippable) {
      return equipItem(playerData, hero, itemId);
    }
    if (!playerData.consumeItem(itemId)) {
      return ItemUseResult(
        success: false,
        message: 'ไม่มี ${definition.name} ในคลัง',
      );
    }

    hero.totalItemsUsed += 1;

    switch (itemId) {
      case 'ration_pack':
        hero.currentStats.currentHp =
            (hero.currentStats.currentHp + 30).clamp(0, hero.currentStats.maxHp);
        hero.currentStats.currentEng =
            (hero.currentStats.currentEng + 40).clamp(0, hero.currentStats.maxEng);
        hero.reduceRecoveryCooldown(const Duration(minutes: 20));
        return const ItemUseResult(
          success: true,
          message: 'ใช้เสบียงสนามแล้ว ฟื้น HP/ENG และเร่งพักฟื้น',
        );
      case 'beast_meat':
        hero.currentStats.currentHp =
            (hero.currentStats.currentHp + 12).clamp(0, hero.currentStats.maxHp);
        hero.currentStats.currentEng =
            (hero.currentStats.currentEng + 15).clamp(0, hero.currentStats.maxEng);
        return const ItemUseResult(
          success: true,
          message: 'กินเนื้อสัตว์ดิบ ฟื้นแรงเล็กน้อย',
        );
      case 'battle_tonic':
        hero.baseStats.atk += 3;
        hero.currentStats.atk += 3;
        return const ItemUseResult(
          success: true,
          message: 'ใช้ยาบำรุงกำลังแล้ว ATK +3 ถาวร',
        );
      case 'guard_tonic':
        hero.baseStats.def += 3;
        hero.currentStats.def += 3;
        return const ItemUseResult(
          success: true,
          message: 'ใช้ยาบำรุงป้องกันแล้ว DEF +3 ถาวร',
        );
      case 'swift_tonic':
        hero.baseStats.spd += 3;
        hero.currentStats.spd += 3;
        return const ItemUseResult(
          success: true,
          message: 'ใช้ยาบำรุงความคล่องตัวแล้ว SPD +3 ถาวร',
        );
      case 'trust_token':
        hero.adjustBond(12);
        return const ItemUseResult(
          success: true,
          message: 'ใช้เครื่องรางใจแล้ว Bond เพิ่มขึ้น',
        );
      case 'prayer_candle':
        hero.adjustFaith(12);
        return const ItemUseResult(
          success: true,
          message: 'ใช้เทียนอธิษฐานแล้ว Faith เพิ่มขึ้น',
        );
      case 'survivor_cache':
        playerData.addItemRewards([
          definitionFor('ration_pack')!.toItemModel(quantity: 1),
          definitionFor('trust_token')!.toItemModel(quantity: 1),
        ]);
        return const ItemUseResult(
          success: true,
          message: 'เปิดหีบเสบียง ได้เสบียงสนามและเครื่องรางใจ',
        );
      default:
        return const ItemUseResult(success: false, message: 'ไอเทมนี้ยังใช้ตรง ๆ ไม่ได้');
    }
  }
}
