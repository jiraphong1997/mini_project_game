import 'package:flutter/material.dart';
import 'screens/main_dashboard.dart';
import 'screens/debug_hero_screen.dart'; // Import หน้า Debug

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Project Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/debug': (_) => const DebugHeroScreen(),
      },
      home: const MainDashboard(),
    );
  }
}
