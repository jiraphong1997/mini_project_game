import 'package:flutter/material.dart';
import '../models/player_data.dart';
import '../models/hero_model.dart';
import '../utils/gacha_manager.dart';
import 'hero_detail_screen.dart';

class GachaScreen extends StatefulWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;

  const GachaScreen({Key? key, required this.playerData, required this.onDataChanged}) : super(key: key);

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  HeroModel? _recentHero;

  void _summon({required bool isSpecial}) {
    int cost = isSpecial ? GachaManager.specialCost : GachaManager.commonCost;
    
    if (widget.playerData.gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ทองไม่พอ! กรุณาเติมเงิน', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      widget.playerData.gold -= cost;
      _recentHero = GachaManager.rollGacha(isSpecial: isSpecial);
      // เพิ่มฮีโร่ลงในคลังผู้เล่น
      List<HeroModel> updatedHeroes = List.from(widget.playerData.allHeroes)..add(_recentHero!);
      widget.playerData.allHeroes = updatedHeroes;
    });

    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // แสดงเงิน
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange, size: 30),
              const SizedBox(width: 8),
              Text('Gold ที่มี: ${widget.playerData.gold}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_recentHero != null) ...[
                    const Text('ได้รับฮีโร่ใหม่!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => HeroDetailScreen(hero: _recentHero!)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.amber, width: 3),
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.person_pin, size: 80, color: Colors.indigo),
                            Text(_recentHero!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_recentHero!.rarity, (index) => const Icon(Icons.star, color: Colors.amber)),
                            ),
                            Text('อาชีพหลัก: ${_recentHero!.currentJobRole}'),
                            const SizedBox(height: 8),
                            const Text('แตะเพื่อดูรายละเอียด >', style: TextStyle(color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ปุ่มสุ่มหลัก
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummonButton(
                        'สุ่มทั่วไป', 
                        GachaManager.commonCost, 
                        Colors.blue, 
                        () => _summon(isSpecial: false)
                      ),
                      _buildSummonButton(
                        'สุ่มพิเศษ', 
                        GachaManager.specialCost, 
                        Colors.purple, 
                        () => _summon(isSpecial: true)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummonButton(String title, int cost, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
          Text('ใช้ $cost Gold', style: const TextStyle(color: Colors.yellowAccent)),
        ],
      ),
    );
  }
}
