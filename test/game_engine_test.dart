import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/logic/game_engine.dart';
import 'package:mini_project_game/utils/leveling_policy.dart';

void main() {
  group('GameEngine Tests', () {
    test('loadGameTime should update derived time getters correctly', () {
      final engine = GameEngine();
      final seconds = (LevelingPolicy.daysPerYear * 24 * 3600) + (3 * 24 * 3600) + (5 * 3600);

      engine.stopGameLoop();
      engine.loadGameTime(seconds);

      expect(engine.currentYear, 1);
      expect(engine.currentDay, 3);
      expect(engine.currentHour, 5);
    });

    test('startGameLoop should only create one active timer', () async {
      final engine = GameEngine();

      engine.stopGameLoop();
      engine.loadGameTime(0);
      engine.startGameLoop();
      engine.startGameLoop();

      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(engine.totalInGameSeconds, LevelingPolicy.inGameTimeScale.toInt());

      engine.stopGameLoop();
    });
  });
}
