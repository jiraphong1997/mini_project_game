import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../models/player_data.dart';
import '../services/item_usage_service.dart';

class ShopScreen extends StatelessWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;

  const ShopScreen({
    super.key,
    required this.playerData,
    required this.onDataChanged,
  });

  void _buyGold(BuildContext context, int amount, double price) {
    playerData.gold += amount;
    onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เติมเงินสำเร็จ ได้รับ $amount Gold'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _buyItem(BuildContext context, ItemCatalogEntry item) {
    final price = ItemUsageService.buyPriceFor(playerData, item.id);
    final bought = ItemUsageService.buyItem(playerData, item.id);
    if (!bought) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silver ไม่พอสำหรับซื้อ ${item.name} ต้องใช้ $price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ซื้อ ${item.name} สำเร็จ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sellItem(BuildContext context, ItemModel item, {bool sellAll = false}) {
    final result = ItemUsageService.sellItem(
      playerData,
      item.id,
      quantity: sellAll ? item.quantity : 1,
    );
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }

    onDataChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), backgroundColor: Colors.green),
    );
  }

  void _craftItem(BuildContext context, CraftingRecipe recipe) {
    final result = ItemUsageService.craftItem(playerData, recipe.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
    if (result.success) {
      onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = [...playerData.inventory]
      ..sort((a, b) => b.rarity.compareTo(a.rarity));
    final consumableCatalog = ItemUsageService.catalog
        .where((item) => item.type == ItemType.consumable)
        .toList();
    final utilityCatalog = ItemUsageService.catalog
        .where((item) => item.type == ItemType.warpItem)
        .toList();
    final equipmentCatalog = ItemUsageService.catalog
        .where(
          (item) => item.type == ItemType.weapon || item.type == ItemType.armor,
        )
        .toList();
    final materialInventory = inventory
        .where((item) => item.type == ItemType.material)
        .toList();
    final consumableInventory = inventory
        .where((item) => item.type == ItemType.consumable)
        .toList();
    final utilityInventory = inventory
        .where((item) => item.type == ItemType.warpItem)
        .toList();
    final equipmentInventory = inventory
        .where(
          (item) => item.type == ItemType.weapon || item.type == ItemType.armor,
        )
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.amber[100],
          child: Column(
            children: [
              const Text('ทรัพยากรปัจจุบัน', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _resourceBadge(
                    Icons.monetization_on,
                    'Gold',
                    '${playerData.gold}',
                  ),
                  _resourceBadge(
                    Icons.payments_outlined,
                    'Silver',
                    '${playerData.silver}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'เติมเงิน',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPackageCard(context, 'ถุงทองเล็ก', 500, 35.0),
              _buildPackageCard(context, 'หีบทอง', 1500, 99.0),
              _buildPackageCard(context, 'กองคาราวานทองคำ', 5000, 299.0),
              _buildPackageCard(context, 'พระคลังมหาสมบัติ', 15000, 799.0),
              const SizedBox(height: 24),
              const Text(
                'ตลาดซื้อของ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'แยกตลาดของใช้และอุปกรณ์เพื่อให้จัดการ economy ได้ชัดขึ้น',
              ),
              const SizedBox(height: 16),
              _buildCatalogSection(
                context,
                title: 'ตลาดของใช้และเสบียง',
                icon: Icons.local_drink_outlined,
                entries: consumableCatalog,
              ),
              const SizedBox(height: 16),
              _buildCatalogSection(
                context,
                title: 'ตลาดของเตรียมลุยและหินวาป',
                icon: Icons.hexagon_outlined,
                entries: utilityCatalog,
              ),
              const SizedBox(height: 16),
              _buildCatalogSection(
                context,
                title: 'ตลาดอาวุธและอุปกรณ์',
                icon: Icons.construction_outlined,
                entries: equipmentCatalog,
              ),
              const SizedBox(height: 24),
              const Text(
                'เวิร์กช็อปคราฟต์',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ใช้วัตถุดิบจากหอคอยมาทำของใช้ อาวุธ ชุดเกราะ และของช่วยลุย',
              ),
              const SizedBox(height: 16),
              ...ItemUsageService.recipes.map(
                (recipe) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.handyman_outlined),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${recipe.description}\n'
                      'ใช้ ${_recipeMaterialsText(recipe)}'
                      '\nค่าคราฟต์ ${recipe.silverCost} Silver',
                    ),
                    trailing: ElevatedButton(
                      onPressed: ItemUsageService.canCraft(playerData, recipe)
                          ? () => _craftItem(context, recipe)
                          : null,
                      child: const Text('คราฟต์'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ตลาดรับซื้อ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ขายวัสดุ ของใช้ และอุปกรณ์แยกตลาดเพื่อดูมูลค่าของคลังได้ง่ายขึ้น',
              ),
              const SizedBox(height: 16),
              if (inventory.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('ยังไม่มีไอเทมในคลังสำหรับขาย'),
                  ),
                )
              else ...[
                _buildSellSection(
                  context,
                  title: 'ตลาดวัสดุ',
                  icon: Icons.scatter_plot_outlined,
                  items: materialInventory,
                ),
                _buildSellSection(
                  context,
                  title: 'ตลาดของใช้',
                  icon: Icons.fastfood_outlined,
                  items: consumableInventory,
                ),
                _buildSellSection(
                  context,
                  title: 'ตลาดของเตรียมลุย/หินวาป',
                  icon: Icons.travel_explore_outlined,
                  items: utilityInventory,
                ),
                _buildSellSection(
                  context,
                  title: 'ตลาดอุปกรณ์',
                  icon: Icons.shield_outlined,
                  items: equipmentInventory,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    String name,
    int amount,
    double price,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: Colors.orange, size: 40),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ได้รับ $amount Gold'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _buyGold(context, amount, price),
          child: Text('฿$price'),
        ),
      ),
    );
  }

  Widget _resourceBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _recipeMaterialsText(CraftingRecipe recipe) {
    return recipe.materials.entries
        .map((entry) {
          final definition = ItemUsageService.definitionFor(entry.key);
          final label = definition?.name ?? entry.key;
          return '$label x${entry.value}';
        })
        .join(', ');
  }

  Widget _buildCatalogSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<ItemCatalogEntry> entries,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...entries.map((item) {
          final price = ItemUsageService.buyPriceFor(playerData, item.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${item.description}\nราคาตลาดตอนนี้ $price Silver',
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _buyItem(context, item),
                child: const Text('ซื้อ'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSellSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<ItemModel> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _buildSellCard(context, item)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSellCard(BuildContext context, ItemModel item) {
    final definition = ItemUsageService.definitionFor(item.id);
    final quote = ItemUsageService.sellQuoteFor(
      playerData,
      item.id,
      quantity: 1,
      marketType: 'shop',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.name} x${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(label: Text(ItemUsageService.categoryLabel(item))),
              ],
            ),
            const SizedBox(height: 6),
            Text(definition?.description ?? 'ไอเทมที่ได้มาจากการสำรวจ'),
            const SizedBox(height: 6),
            Text(
              quote.gold > 0
                  ? 'ราคารับซื้อต่อชิ้น: ${quote.silver} Silver + ${quote.gold} Gold'
                  : 'ราคารับซื้อต่อชิ้น: ${quote.silver} Silver',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _sellItem(context, item),
                  child: const Text('ขาย 1'),
                ),
                OutlinedButton(
                  onPressed: () => _sellItem(context, item, sellAll: true),
                  child: const Text('ขายทั้งหมด'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
