import 'package:flutter/material.dart';
import '../models/hero_model.dart';
import '../models/hero_stats.dart';

class HeroDetailScreen extends StatelessWidget {
  final HeroModel hero;

  const HeroDetailScreen({Key? key, required this.hero}) : super(key: key);

  // ข้อมูล Mock สำหรับให้เปิดมาดูได้เลย (ในกรณีของจริงจะรับค่าผ่าน parameter 'hero' ด้านบน)
  factory HeroDetailScreen.mock() {
    return HeroDetailScreen(
      hero: HeroModel(
        id: 'h001',
        name: 'อาเธอร์ (Arthur)',
        gender: 'ชาย',
        age: 24,
        backgroundStory: 'นักรบหนุ่มผู้ไล่ตามความฝันในการพิชิตหอคอยเพื่อค้นหาไอเทมระดับตำนาน',
        level: 6500, // จะตกอยู่ที่ช่วง Legendary (4 ดาว) ชั่วคราว
        currentExp: 450000000,
        baseStats: HeroStats(
          maxHp: 1000, currentHp: 1000, 
          atk: 120, def: 80, spd: 50, 
          maxEng: 100, currentEng: 80, 
          luk: 15
        ),
        currentStats: HeroStats(
          maxHp: 1200, currentHp: 1200, 
          atk: 150, def: 90, spd: 55, 
          maxEng: 100, currentEng: 80, 
          luk: 20
        ),
        aptitudes: {
          'อัศวิน (Knight)': 0.60,
          'ชาวนา (Farmer)': 0.25,
          'โจร (Thief)': 0.15,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลฮีโร่ - ${hero.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildAptitudesCard(),
            const SizedBox(height: 16),
            _buildBackgroundStoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รูปจำลองฮีโร่
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getRarityColor(hero.rarity), width: 3),
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        // ข้อมูลหลัก
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hero.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(
                  hero.rarity,
                  (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text('Lv. ${hero.level} | อาชีพ: ${hero.currentJobRole}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.indigo)),
              Text('เพศ: ${hero.gender} | อายุ: ${hero.age} ปี'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatsCard() {
    final stats = hero.currentStats;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ค่าสถานะ (Stats)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('HP', '${stats.currentHp} / ${stats.maxHp}', Colors.green),
            _buildStatRow('พลังงาน', '${stats.currentEng} / ${stats.maxEng}', Colors.blue),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatBadge('ATK', stats.atk.toString(), Colors.redAccent)),
                Expanded(child: _buildStatBadge('DEF', stats.def.toString(), Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatBadge('SPD', stats.spd.toString(), Colors.orange)),
                Expanded(child: _buildStatBadge('LUK', stats.luk.toString(), Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAptitudesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ความถนัด (Aptitudes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // วนลูปแสดงหลอดความถนัด
            ...hero.aptitudes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.grey[200],
                      color: Colors.indigoAccent,
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('ประวัติ (Background Story)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const Divider(),
             Text(hero.backgroundStory, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 5: return Colors.orangeAccent;
      case 4: return Colors.purpleAccent;
      case 3: return Colors.blueAccent;
      case 2: return Colors.green;
      default: return Colors.grey;
    }
  }
}
