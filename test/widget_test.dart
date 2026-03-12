import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_project_game/main.dart';

void main() {
  testWidgets('Main dashboard smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('สถานะฐาน'), findsOneWidget);
    expect(find.text('ผู้เล่นใหม่'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('สุ่มฮีโร่ (Gacha)'), findsOneWidget);
  });
}
