import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/leveling_policy.dart';

class GameEngine extends ChangeNotifier {
  static final GameEngine _instance = GameEngine._internal();

  factory GameEngine() => _instance;

  GameEngine._internal();

  Timer? _gameLoopTimer;
  int _totalInGameSeconds = 0;

  bool get isRunning => _gameLoopTimer != null && _gameLoopTimer!.isActive;
  int get totalInGameSeconds => _totalInGameSeconds;

  int get currentYear =>
      _totalInGameSeconds ~/ (LevelingPolicy.daysPerYear * 24 * 3600);
  int get currentDay =>
      (_totalInGameSeconds % (LevelingPolicy.daysPerYear * 24 * 3600)) ~/
      (24 * 3600);
  int get currentHour => (_totalInGameSeconds % (24 * 3600)) ~/ 3600;

  void startGameLoop() {
    if (isRunning) return;

    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void stopGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
  }

  void _onTick() {
    _totalInGameSeconds += LevelingPolicy.inGameTimeScale.toInt();
    notifyListeners();
  }

  void loadGameTime(int seconds) {
    _totalInGameSeconds = seconds;
    notifyListeners();
  }
}
