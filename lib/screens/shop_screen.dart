import 'package:flutter/material.dart';
import '../models/player_data.dart';

class ShopScreen extends StatelessWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;

  const ShopScreen({super.key, required this.playerData, required this.onDataChanged});

  void _buyGold(BuildContext context, int amount, double price) {
    // ในระบบจริงขั้นตอนนี้จะเรียก In-App Purchase
    // สำหรับ Mock นี้ เราบวก Gold เข้าไปจำลองการเติมเงินสำเร็จ
    playerData.gold += amount;
    onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เติมเงินสำเร็จ! ได้รับ $amount Gold'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.amber[100],
          child: Column(
            children: [
              const Text('ยอดเงิน Gold ปัจจุบัน', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.orange, size: 40),
                  const SizedBox(width: 8),
                  Text('${playerData.gold}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('เติมเงิน (Top Up)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPackageCard(context, 'ถุงทองเล็ก', 500, 35.0),
              _buildPackageCard(context, 'หีบทอง', 1500, 99.0),
              _buildPackageCard(context, 'กองคาราวานทองคำ', 5000, 299.0),
              _buildPackageCard(context, 'พระคลังมหาสมบัติ (สุดคุ้ม!)', 15000, 799.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, String name, int amount, double price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: Colors.orange, size: 40),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ได้รับ $amount Gold'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          onPressed: () => _buyGold(context, amount, price),
          child: Text('฿$price'),
        ),
      ),
    );
  }
}
