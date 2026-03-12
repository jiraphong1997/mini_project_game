import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
import '../utils/gacha_manager.dart';
import 'hero_detail_screen.dart';

class GachaScreen extends StatefulWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;
  final VoidCallback onOpenInventory;

  const GachaScreen({
    super.key,
    required this.playerData,
    required this.onDataChanged,
    required this.onOpenInventory,
  });

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  HeroModel? _recentHero;

  void _summon({required bool isSpecial}) {
    final cost = isSpecial ? GachaManager.specialCost : GachaManager.commonCost;

    if (widget.playerData.gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ทองไม่พอ กรุณาเติมเงิน',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      widget.playerData.gold -= cost;
      _recentHero = GachaManager.rollGacha(
        isSpecial: isSpecial,
        existingNames: widget.playerData.allHeroes
            .map((hero) => hero.name)
            .toSet(),
      );
      widget.playerData.allHeroes = List.from(widget.playerData.allHeroes)
        ..add(_recentHero!);
    });

    widget.onDataChanged();
  }

  void _openHeroDetail(HeroModel hero) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeroDetailScreen(
          hero: hero,
          playerData: widget.playerData,
          onHeroChanged: widget.onDataChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentHero = _recentHero;
    final recentClass = recentHero == null
        ? null
        : ClassProgressionService.definitionFor(recentHero.currentClass).title;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange, size: 30),
              const SizedBox(width: 8),
              Text(
                'Gold ที่มี: ${widget.playerData.gold}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (recentHero != null) ...[
                    const Text(
                      'ได้รับฮีโร่ใหม่!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _openHeroDetail(recentHero),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.amber, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_pin,
                              size: 80,
                              color: Colors.indigo,
                            ),
                            Text(
                              recentHero.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                recentHero.rarity,
                                (index) =>
                                    const Icon(Icons.star, color: Colors.amber),
                              ),
                            ),
                            Text('สายถนัด: ${recentHero.currentJobRole}'),
                            Text('คลาสเริ่มต้น: $recentClass'),
                            Text('EXP Stage: ${recentHero.experienceStage}'),
                            const SizedBox(height: 8),
                            const Text(
                              'แตะเพื่อดูรายละเอียด >',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: widget.onOpenInventory,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('ไปคลังฮีโร่'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openHeroDetail(recentHero),
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('ดูสถานะ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummonButton(
                        'สุ่มทั่วไป',
                        GachaManager.commonCost,
                        Colors.blue,
                        () => _summon(isSpecial: false),
                      ),
                      _buildSummonButton(
                        'สุ่มพิเศษ',
                        GachaManager.specialCost,
                        Colors.purple,
                        () => _summon(isSpecial: true),
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

  Widget _buildSummonButton(
    String title,
    int cost,
    Color color,
    VoidCallback onPressed,
  ) {
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
