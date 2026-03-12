# Handoff Status

Last updated: March 12, 2026
Project state: Playable Flutter prototype with persistence, realtime tower loop, recovery cooldown, and class progression

## 1. Current app flow

Entry point:
- `lib/main.dart` opens `MainDashboard`

Main screens:
- `Status`: overview of player resources, roster state, recovery state, inventory snapshot
- `Hero Inventory`: list of all owned heroes, tap to open hero detail
- `Gacha`: summon heroes and send them into the roster immediately
- `Tower`: realtime expedition loop with major decisions, rewards, cooldown, and quick recovery
- `Shop`: existing prototype shop screen

Persistent data:
- Stored with `shared_preferences`
- Save/load service: `lib/services/player_storage_service.dart`

## 2. Systems currently implemented

### Hero and progression
- `HeroModel` now stores:
  - level
  - current EXP
  - total EXP earned
  - bond
  - faith
  - current class
  - unlocked classes
  - recovery cooldown timestamp
- EXP is granted during tower runs and visible in:
  - tower log
  - hero detail
  - inventory card
- Experience stage labels exist:
  - `Recruit`
  - `Seasoned`
  - `Veteran`
  - `Elite`
  - `Mythic`

Main files:
- `lib/models/hero_model.dart`
- `lib/utils/leveling_policy.dart`

### Class progression
- Class logic service: `lib/services/class_progression_service.dart`
- Current supported classes:
  - `novice`
  - `vanguard`
  - `skirmisher`
  - `acolyte`
  - `knight`
  - `ranger`
  - `warden`
  - `oracle`
- Class unlock rules use character stats, level, bond, faith, and aptitude
- Special override path exists via item:
  - `Class Trial Seal`
- Class change is available in hero detail screen

### Tower loop
- Realtime floor processing with timer
- Major decision events only trigger on milestone floors
- Advice charges scale from party bond/faith
- Tower gives:
  - silver
  - gold
  - EXP
  - items
- Tower can also drop:
  - `Field Ration`
  - `Class Trial Seal`
  - ore and relic materials

Main files:
- `lib/screens/tower_screen.dart`
- `lib/services/tower_run_service.dart`
- `lib/models/party_model.dart`

### Recovery system
- After expedition, party enters cooldown-based recovery
- Recovery duration depends on fatigue and cleared floors
- Fast recovery paths:
  - spend silver
  - consume `Field Ration`
- Recovery status updates in UI without requiring a manual refresh

### Save system
- Save/load already supports:
  - heroes
  - parties
  - inventory
  - tower progress
  - class state
  - recovery cooldown state

Main files:
- `lib/models/player_data.dart`
- `lib/services/player_storage_service.dart`

## 3. Important files

Core models:
- `lib/models/hero_model.dart`
- `lib/models/hero_stats.dart`
- `lib/models/player_data.dart`
- `lib/models/party_model.dart`
- `lib/models/item_model.dart`

Core services:
- `lib/services/player_storage_service.dart`
- `lib/services/tower_run_service.dart`
- `lib/services/class_progression_service.dart`

Screens:
- `lib/screens/main_dashboard.dart`
- `lib/screens/gacha_screen.dart`
- `lib/screens/hero_detail_screen.dart`
- `lib/screens/tower_screen.dart`
- `lib/screens/shop_screen.dart`
- `lib/screens/debug_hero_screen.dart`

Legacy/time prototype:
- `lib/logic/game_engine.dart`

## 4. Verified status

Verified on March 12, 2026:
- `flutter analyze` passed
- `flutter test` passed

Relevant tests:
- `test/hero_model_test.dart`
- `test/class_progression_service_test.dart`
- `test/player_data_test.dart`
- `test/tower_run_service_test.dart`
- `test/widget_test.dart`

## 5. Known limitations

These are not broken, but still prototype-grade:

1. Class change has stat requirements and seal override, but there is not yet a true quest chain or mission screen behind it.
2. Inventory items are still mostly used for recovery/material progression; equip/use-item systems are not fully built.
3. Tower battles are still resolved as simulation, not turn-by-turn combat.
4. Event consequence chains across multiple future runs are still shallow.
5. `GameEngine` time system exists but is not yet fully integrated into all base-management systems.
6. `README.md` is still the default Flutter template and does not describe the project yet.

## 6. Best next steps

Recommended order for the next sprint:

1. Build real class quests
- Add quest definitions and quest progress data
- Require quest completion for advanced/special classes instead of item override alone
- Surface quest progress in hero detail and dashboard

2. Expand inventory into real gameplay
- Consumables with direct use on heroes
- Equipment slots and stat application
- Better loot categories from tower and shop

3. Improve tower consequence depth
- Event chains that unlock later branches
- Character-specific reactions
- Longer-term trust/faith effects from major decisions

4. Connect base management to time
- Let in-game time affect recovery, training, and resource generation
- Use `GameEngine` as shared progression clock if the prototype keeps that direction

## 7. Git upload checklist

Before pushing:
- confirm `flutter analyze`
- confirm `flutter test`
- review `README.md` if you want a cleaner public-facing repository page
- commit `HANDOFF_STATUS.md` with the code changes from this round

Suggested commit scope for this round:
- recovery cooldown
- quick recovery by item/silver
- EXP visibility improvements
- class progression system
- updated handoff document

## 8. If continuing in another session

Good prompt to resume:

`Read HANDOFF_STATUS.md first, then continue the next sprint by implementing real class quests and deeper item usage without breaking current save data.`
