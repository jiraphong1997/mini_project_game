import 'package:flutter/material.dart';
import '../models/player_data.dart';
import 'gacha_screen.dart';
import 'shop_screen.dart';
import 'hero_detail_screen.dart'; // สำหรับตอนคลิกดูฮีโร่ในคลัง

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  
  // จำลองข้อมูลผู้เล่น
  late PlayerData _playerData;

  @override
  void initState() {
    super.initState();
    _playerData = PlayerData(
      playerId: 'P001',
      playerName: 'ผู้เล่นใหม่',
      gold: 500, // แจกให้เริ่มต้น 500 ไว้ลองสุ่มเล่น
    );
  }

  void _onDataChanged() {
    setState(() {}); // ใช้สำหรับรีเฟรชหน้าจอเวลาจำนวนเงินหรือคลังฮีโร่เปลี่ยน
  }

  @override
  Widget build(BuildContext context) {
    // เลือกว่าหน้าไหนกำลังทำงานอยู่
    final List<Widget> pages = [
      _buildInventoryPage(),
      GachaScreen(playerData: _playerData, onDataChanged: _onDataChanged),
      ShopScreen(playerData: _playerData, onDataChanged: _onDataChanged),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Project Game', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'คลังฮีโร่'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'สุ่มฮีโร่ (Gacha)'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'เติมเงิน'),
        ],
      ),
    );
  }

  Widget _buildInventoryPage() {
    if (_playerData.allHeroes.isEmpty) {
      return const Center(child: Text('คุณยังไม่มีฮีโร่ ไปที่หน้า "สุ่มฮีโร่" เพื่อกดรับเลย!'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _playerData.allHeroes.length,
      itemBuilder: (context, index) {
        final hero = _playerData.allHeroes[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HeroDetailScreen(hero: hero)));
          },
          child: Card(
            elevation: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 50, color: Colors.indigo),
                const SizedBox(height: 8),
                Text(hero.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(hero.rarity, (i) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                ),
                const SizedBox(height: 4),
                Text(hero.currentJobRole, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }
}
