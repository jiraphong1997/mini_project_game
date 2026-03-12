import 'package:flutter/material.dart';
import '../models/hero_model.dart';
import '../models/hero_stats.dart';
import '../logic/game_engine.dart'; // Import GameEngine

class DebugHeroScreen extends StatefulWidget {
  const DebugHeroScreen({super.key});

  @override
  State<DebugHeroScreen> createState() => _DebugHeroScreenState();
}

class _DebugHeroScreenState extends State<DebugHeroScreen> {
  late HeroModel _hero;

  @override
  void initState() {
    super.initState();
    // สร้าง Hero จำลองขึ้นมาเพื่อทดสอบ
    _hero = HeroModel(
      id: 'debug_001',
      name: 'Test Warrior',
      gender: 'ชาย',
      age: 20,
      backgroundStory: 'ตัวละครสำหรับทดสอบระบบ Level และ Rarity',
      level: 1, // เริ่มต้นที่เลเวล 1
      baseStats: HeroStats.initial(),
      aptitudes: {'Novice': 1.0},
    );
    
    // เริ่มต้น GameEngine และดักฟังการเปลี่ยนแปลงเพื่อรีเฟรชหน้าจอ
    GameEngine().startGameLoop();
    GameEngine().addListener(_onGameTimeUpdate);
  }

  @override
  void dispose() {
    // ยกเลิกการดักฟังเมื่อปิดหน้านี้
    GameEngine().removeListener(_onGameTimeUpdate);
    GameEngine().stopGameLoop();
    super.dispose();
  }

  void _onGameTimeUpdate() {
    // รีเฟรชหน้าจอทุกครั้งที่เวลาในเกมเปลี่ยน
    if (mounted) setState(() {});
  }

  void _addLevel(int amount) {
    setState(() {
      _hero.level += amount;
      // ในเกมจริงอาจจะต้องมีการคำนวณ Stat เพิ่มตรงนี้ด้วย
    });
  }

  void _resetLevel() {
    setState(() {
      _hero.level = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = GameEngine(); // อ้างอิง Engine

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Hero Leveling'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          // แสดงเวลาบน AppBar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Y${engine.currentYear + 1}:D${engine.currentDay + 1}', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ส่วนแสดงเวลาอย่างละเอียด
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'In-Game Time: Year ${engine.currentYear + 1}, Day ${engine.currentDay + 1}, Hour ${engine.currentHour}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // ส่วนแสดงผลข้อมูล
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, size: 64, color: Colors.blueGrey),
                    Text(_hero.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text('Level: ${_hero.level}', 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Rarity: ${_hero.rarityTitle} (${_hero.rarity} ดาว)', 
                      style: const TextStyle(fontSize: 20, color: Colors.orange)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Icon(
                        Icons.star, 
                        color: index < _hero.rarity ? Colors.orange : Colors.grey[300],
                        size: 32,
                      )),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ปุ่มควบคุม
            const Text('เพิ่มเลเวลเพื่อทดสอบการเปลี่ยนระดับ'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(onPressed: () => _addLevel(1), child: const Text('+1 Lv')),
                ElevatedButton(onPressed: () => _addLevel(19), child: const Text('+19 (Check Lv 20)')),
                ElevatedButton(onPressed: () => _addLevel(60), child: const Text('+60 (Check Lv 80)')),
                ElevatedButton(onPressed: () => _addLevel(240), child: const Text('+240 (Check Lv 320)')),
                ElevatedButton(onPressed: () => _addLevel(1000), child: const Text('+1000 (Check Max)')),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetLevel, 
              icon: const Icon(Icons.refresh), 
              label: const Text('Reset Level'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
