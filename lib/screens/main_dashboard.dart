import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
import '../services/player_storage_service.dart';
import 'debug_hero_screen.dart';
import 'gacha_screen.dart';
import 'hero_detail_screen.dart';
import 'shop_screen.dart';
import 'tower_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final PlayerStorageService _storageService = PlayerStorageService();
  PlayerData? _playerData;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  void _onDataChanged() {
    if (!mounted || _playerData == null) {
      return;
    }
    setState(() {});
    _savePlayerData();
  }

  Future<void> _loadPlayerData() async {
    final savedData = await _storageService.loadPlayerData();
    if (!mounted) {
      return;
    }

    setState(() {
      _playerData = savedData ?? _createDefaultPlayerData();
      _isLoading = false;
    });

    if (savedData == null) {
      _savePlayerData();
    }
  }

  Future<void> _savePlayerData() async {
    final playerData = _playerData;
    if (playerData == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    await _storageService.savePlayerData(playerData);

    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _resetProgress() async {
    await _storageService.clearPlayerData();
    if (!mounted) {
      return;
    }

    setState(() {
      _playerData = _createDefaultPlayerData();
      _currentIndex = 0;
    });

    await _savePlayerData();
  }

  PlayerData _createDefaultPlayerData() {
    return PlayerData(
      playerId: 'P001',
      playerName: 'ผู้เล่นใหม่',
      silver: 2500,
      gold: 500,
    );
  }

  void _openHeroDetail(HeroModel hero) {
    final playerData = _playerData;
    if (playerData == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeroDetailScreen(
          hero: hero,
          playerData: playerData,
          onHeroChanged: _onDataChanged,
        ),
      ),
    );
  }

  String get _pageTitle {
    switch (_currentIndex) {
      case 0:
        return 'สถานะฐาน';
      case 1:
        return 'คลังฮีโร่';
      case 2:
        return 'สุ่มฮีโร่';
      case 3:
        return 'หอคอย';
      case 4:
        return 'ร้านค้า';
      default:
        return 'Mini Project Game';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _playerData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final playerData = _playerData!;
    final pages = <Widget>[
      _buildStatusPage(playerData),
      _buildInventoryPage(playerData),
      GachaScreen(
        playerData: playerData,
        onDataChanged: _onDataChanged,
        onOpenInventory: () => setState(() => _currentIndex = 1),
      ),
      TowerScreen(
        playerData: playerData,
        onDataChanged: _onDataChanged,
        onOpenGacha: () => setState(() => _currentIndex = 2),
      ),
      ShopScreen(playerData: playerData, onDataChanged: _onDataChanged),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _currentIndex == 0
            ? null
            : IconButton(
                tooltip: 'กลับเมนูหลัก',
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(_pageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Debug Level Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugHeroScreen()),
              );
            },
            icon: const Icon(Icons.bug_report_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _resetProgress();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'reset',
                child: Text('ล้างข้อมูลเซฟ'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Status',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'คลังฮีโร่'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'สุ่มฮีโร่ (Gacha)'),
          BottomNavigationBarItem(icon: Icon(Icons.stairs_outlined), label: 'Tower'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'ร้านค้า'),
        ],
      ),
    );
  }

  Widget _buildStatusPage(PlayerData playerData) {
    final heroes = playerData.allHeroes;
    final aliveHeroes = heroes.where((hero) => hero.isAlive).length;
    final recoveringHeroes = heroes.where((hero) => hero.isRecovering).length;
    final averageLevel = heroes.isEmpty
        ? 0
        : heroes.map((hero) => hero.level).reduce((a, b) => a + b) ~/ heroes.length;
    final highestLevel = heroes.isEmpty
        ? 0
        : heroes.map((hero) => hero.level).reduce((a, b) => a > b ? a : b);
    final highestRarity = heroes.isEmpty
        ? 0
        : heroes.map((hero) => hero.rarity).reduce((a, b) => a > b ? a : b);
    final recentHeroes = heroes.reversed.take(3).toList();
    final classTrialSeals = playerData.itemQuantity(
      ClassProgressionService.classTrialSealItemId,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B3474), Color(0xFF4E5BD9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerData.playerName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ศูนย์บัญชาการต้นแบบสำหรับทดสอบระบบหลักของเกม',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildResourceTile(
                      'Silver',
                      '${playerData.silver}',
                      Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResourceTile(
                      'Gold',
                      '${playerData.gold}',
                      Icons.workspace_premium_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isSaving ? 1 : 0.8,
            child: Text(
              _isSaving ? 'กำลังบันทึกข้อมูล...' : 'ข้อมูลถูกบันทึกอัตโนมัติ',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildOverviewCard(
              'Base Power',
              '${playerData.basePower}',
              Icons.shield_outlined,
              Colors.indigo,
            ),
            _buildOverviewCard(
              'Heroes',
              '${heroes.length}',
              Icons.groups_2_outlined,
              Colors.teal,
            ),
            _buildOverviewCard(
              'Alive',
              '$aliveHeroes',
              Icons.favorite_border,
              Colors.redAccent,
            ),
            _buildOverviewCard(
              'Recovering',
              '$recoveringHeroes',
              Icons.hotel_outlined,
              Colors.deepOrange,
            ),
            _buildOverviewCard(
              'Avg Lv.',
              '$averageLevel',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildOverviewCard(
              'Top Lv.',
              '$highestLevel',
              Icons.bolt_outlined,
              Colors.blueGrey,
            ),
            _buildOverviewCard(
              'Best Rarity',
              highestRarity == 0 ? '-' : '$highestRarity ดาว',
              Icons.auto_awesome,
              Colors.deepPurple,
            ),
            _buildOverviewCard(
              'Tower Best',
              '${playerData.highestTowerFloor}',
              Icons.stairs_outlined,
              Colors.brown,
            ),
            _buildOverviewCard(
              'Items',
              '${playerData.inventory.length}',
              Icons.backpack_outlined,
              Colors.cyan,
            ),
            _buildOverviewCard(
              'Class Seals',
              '$classTrialSeals',
              Icons.auto_fix_high,
              Colors.indigo,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ทางลัด',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => setState(() => _currentIndex = 2),
                      icon: const Icon(Icons.star),
                      label: const Text('ไปสุ่มฮีโร่'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _currentIndex = 1),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('เปิดคลังฮีโร่'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _currentIndex = 3),
                      icon: const Icon(Icons.stairs_outlined),
                      label: const Text('ไปหอคอย'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _currentIndex = 4),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('ไปร้านค้า'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (playerData.inventory.isEmpty)
                  const Text('ยังไม่มีไอเทมจากการปีนหอ')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: playerData.inventory.take(8).map((item) {
                      return Chip(
                        avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: Text('${item.name} x${item.quantity}'),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ฮีโร่ล่าสุด',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentHeroes.isEmpty)
                  const Text(
                    'ยังไม่มีฮีโร่ในคลัง ไปที่หน้า Gacha เพื่อสุ่มตัวแรกก่อน',
                  )
                else
                  ...recentHeroes.map(_buildRecentHeroTile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryPage(PlayerData playerData) {
    if (playerData.allHeroes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'คุณยังไม่มีฮีโร่',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ไปที่หน้า "สุ่มฮีโร่" เพื่อรับฮีโร่ตัวแรก แล้วค่อยกลับมาดูรายละเอียดและสถานะ',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.star),
                label: const Text('ไปหน้า Gacha'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.84,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: playerData.allHeroes.length,
      itemBuilder: (context, index) {
        final hero = playerData.allHeroes[index];
        return GestureDetector(
          onTap: () => _openHeroDetail(hero),
          child: Card(
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _rarityColor(hero.rarity).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${hero.rarity} ดาว',
                        style: TextStyle(
                          color: _rarityColor(hero.rarity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Icon(Icons.person, size: 56, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hero.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _heroClassTitle(hero),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lv. ${hero.level} • ${hero.experienceStage}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ATK ${hero.currentStats.atk} | DEF ${hero.currentStats.def}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _heroRecoveryLabel(hero),
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openHeroDetail(hero),
                      child: const Text('ดูสถานะ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResourceTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentHeroTile(HeroModel hero) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _rarityColor(hero.rarity).withValues(alpha: 0.12),
        child: Icon(Icons.person, color: _rarityColor(hero.rarity)),
      ),
      title: Text(hero.name),
      subtitle: Text(
        'Lv. ${hero.level} • ${_heroClassTitle(hero)} • ${_heroRecoveryLabel(hero)}',
      ),
      trailing: TextButton(
        onPressed: () => _openHeroDetail(hero),
        child: const Text('ดู'),
      ),
    );
  }

  String _heroClassTitle(HeroModel hero) {
    return ClassProgressionService.definitionFor(hero.currentClass).title;
  }

  String _heroRecoveryLabel(HeroModel hero) {
    if (!hero.isRecovering) {
      return 'พร้อมลุย';
    }

    final duration = hero.recoveryCooldownRemaining;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return 'Recover ${hours}h ${minutes}m';
    }
    return 'Recover ${duration.inMinutes}m';
  }

  Color _rarityColor(int rarity) {
    switch (rarity) {
      case 5:
        return Colors.orangeAccent;
      case 4:
        return Colors.purpleAccent;
      case 3:
        return Colors.blueAccent;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
