import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_game/models/agent_ai_settings.dart';
import 'package:mini_project_game/models/hero_model.dart';
import 'package:mini_project_game/models/hero_stats.dart';
import 'package:mini_project_game/models/party_model.dart';
import 'package:mini_project_game/models/player_data.dart';
import 'package:mini_project_game/services/agent_ai_service.dart';
import 'package:mini_project_game/services/tower_run_service.dart';

void main() {
  test(
    'Agent AI should fall back to in-game advice when Ollama is disabled',
    () async {
      final hero = HeroModel(
        id: 'hero_1',
        name: 'Aren',
        gender: 'ชาย',
        age: 21,
        backgroundStory: 'Frontliner',
        level: 10,
        baseStats: HeroStats.initial(),
        currentStats: HeroStats.initial(),
        aptitudes: const {'Vanguard': 1.0},
        bond: 55,
        faith: 42,
        currentClass: 'vanguard',
        unlockedClasses: const ['novice', 'vanguard'],
      );
      final party = PartyModel(
        partyId: 'main',
        partyName: 'Main',
        members: [hero],
        formation: 'balanced',
      );
      final player = PlayerData(
        playerId: 'p1',
        playerName: 'Tester',
        aiSettings: const AgentAiSettings(provider: AgentAiProvider.ruleBased),
      );
      const event = TowerDecisionEvent(
        id: 'oath_gate',
        title: 'Oath Gate',
        description: 'A decisive gate event',
        options: [
          TowerDecisionOption(
            id: 'lead_from_front',
            title: 'Lead',
            description: 'Push forward',
          ),
        ],
      );

      final expected = TowerRunService.buildAdvice(party: party, event: event);
      final actual = await AgentAiService.buildTowerAdvice(
        playerData: player,
        party: party,
        event: event,
      );

      expect(actual, expected);
    },
  );
}
