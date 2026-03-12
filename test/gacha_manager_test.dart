import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/utils/gacha_manager.dart';

void main() {
  test('Gacha should avoid duplicate names from existing roster', () {
    final existingNames = <String>{};

    for (var i = 0; i < 25; i++) {
      final hero = GachaManager.rollGacha(
        isSpecial: i.isEven,
        existingNames: existingNames,
      );

      expect(existingNames.contains(hero.name), isFalse);
      existingNames.add(hero.name);
    }

    expect(existingNames.length, 25);
  });
}
