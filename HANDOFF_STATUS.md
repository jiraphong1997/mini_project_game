# Handoff Status

Last updated: March 14, 2026
Project state: Playable Flutter prototype with save/load, realtime tower expedition, hero progression, class branches, skill display, event chains, economy, and optional Ollama-backed advice

## 1. Current app flow

Entry point:
- `lib/main.dart` opens `MainDashboard`

Main screens:
- `Status`: player overview, resources, AI mode summary, roster snapshot, quick links
- `Hero Inventory`: roster list and access to hero detail
- `Gacha`: summon heroes into the roster immediately
- `Tower`: realtime expedition loop with entry-floor selection, warp-stone entry cost, major decisions, live hero status, rewards, and recovery cooldown
- `Shop`: buy/sell/craft economy screen with consumables, utility items, warp stones, equipment, and separated sell sections
- `AI Settings`: switch between rule-based advice and local Ollama, test connection, persist settings

Persistent data:
- Stored with `shared_preferences`
- Save/load service: `lib/services/player_storage_service.dart`

## 2. Systems currently implemented

### Hero model and progression
- `HeroModel` stores:
  - level
  - current EXP
  - total EXP earned
  - total tower floors cleared
  - total items used
  - bond
  - faith
  - current class
  - unlocked classes
  - mana
  - body condition
  - status effects
  - skill cooldown state
  - current action / current target
  - recovery cooldown timestamp
- EXP is awarded during tower runs and shown in hero detail, tower logs, and status summaries
- Experience stage labels exist:
  - `Recruit`
  - `Seasoned`
  - `Veteran`
  - `Elite`
  - `Mythic`

Main files:
- `lib/models/hero_model.dart`
- `lib/utils/leveling_policy.dart`

### Skills
- Hero detail shows unlocked skills and upcoming unlocks
- Skills are learned from class + level progression
- Runtime state tracks:
  - mana cost
  - cooldowns
  - last used skill
  - per-floor action summary
- Tower UI shows hero-by-hero status including HP, ENG, MP, body condition, statuses, target, skill use, and cooldowns

Main files:
- `lib/models/skill_model.dart`
- `lib/services/skill_progression_service.dart`
- `lib/screens/hero_detail_screen.dart`
- `lib/screens/tower_screen.dart`

### Class progression and class quests
- Class progression service supports branch unlock rules
- Current branch structure:
  - `Novice -> Vanguard -> Knight / Warbringer`
  - `Novice -> Skirmisher -> Ranger / Shadowblade`
  - `Novice -> Acolyte -> Oracle / Saint`
- Unlock rules use stats, level, bond, faith, and quest completion
- `Class Trial Seal` still exists as special override support
- Class quest board screen exists and supports branch filtering

Main files:
- `lib/services/class_progression_service.dart`
- `lib/services/class_quest_service.dart`
- `lib/screens/class_quest_board_screen.dart`

### Tower loop
- Realtime floor processing with timer
- Player can choose entry floor from already-cleared floors plus the next new floor
- Entering the tower requires:
  - `Tower Warp Stone` x1
  - silver entry fee based on floor
- Warp-out is effectively free because entry cost is paid at run start
- Major decisions trigger on milestone floors instead of constantly
- Event chains can branch across multiple stages
- Advice charges scale from party bond/faith
- Tower gives:
  - silver
  - gold
  - EXP
  - items
- Tower battles use simulation, but now include:
  - monster family profiles
  - elite modifiers
  - equipment impact
  - class impact
  - autonomous hero action resolution
  - automatic potion usage for some situations

Main files:
- `lib/screens/tower_screen.dart`
- `lib/services/tower_run_service.dart`
- `lib/models/party_model.dart`

### Recovery system
- After expedition, party enters cooldown-based recovery
- Recovery duration depends on expedition strain and hero state
- Fast recovery paths:
  - spend silver
  - consume `Field Ration`
- Recovery status updates live in the UI without manual refresh

### Economy and items
- Buy/sell/craft flow exists
- Shop now sells:
  - consumables
  - utility / prep items
  - `Tower Warp Stone`
  - equipment
- Shop buyback is separated by:
  - materials
  - consumables
  - utility / warp items
  - equipment
- Dynamic pricing exists based on scarcity, rarity, and market type
- Event merchant / blacksmith inventories can differ from the base shop
- Item use includes:
  - healing potion
  - mana potion
  - antidote potion
  - field ration
  - tonics
  - trust / faith items

Main files:
- `lib/services/item_usage_service.dart`
- `lib/screens/shop_screen.dart`

### Save system
- Save/load supports:
  - heroes
  - parties
  - inventory
  - tower progress
  - recovery state
  - class state
  - event-chain state
  - event market stock
  - AI settings

Main files:
- `lib/models/player_data.dart`
- `lib/services/player_storage_service.dart`

### Agent AI / Ollama integration
- AI settings are configurable in-app
- Two modes:
  - `Rule-based`
  - `Ollama`
- Settings stored in save data:
  - provider
  - base URL
  - model
  - timeout
  - temperature
  - fallback behavior
- Current integration scope:
  - used for tower decision advice when player presses `ขอคำแนะนำ`
  - falls back to rule-based advice if Ollama is disabled or unavailable and fallback is enabled
- Connection test is available in UI

Main files:
- `lib/models/agent_ai_settings.dart`
- `lib/services/agent_ai_service.dart`
- `lib/screens/ai_settings_screen.dart`

## 3. Important files

Core models:
- `lib/models/hero_model.dart`
- `lib/models/hero_stats.dart`
- `lib/models/player_data.dart`
- `lib/models/party_model.dart`
- `lib/models/item_model.dart`
- `lib/models/skill_model.dart`
- `lib/models/agent_ai_settings.dart`

Core services:
- `lib/services/player_storage_service.dart`
- `lib/services/tower_run_service.dart`
- `lib/services/class_progression_service.dart`
- `lib/services/class_quest_service.dart`
- `lib/services/skill_progression_service.dart`
- `lib/services/item_usage_service.dart`
- `lib/services/agent_ai_service.dart`

Screens:
- `lib/screens/main_dashboard.dart`
- `lib/screens/gacha_screen.dart`
- `lib/screens/hero_detail_screen.dart`
- `lib/screens/tower_screen.dart`
- `lib/screens/shop_screen.dart`
- `lib/screens/class_quest_board_screen.dart`
- `lib/screens/ai_settings_screen.dart`
- `lib/screens/debug_hero_screen.dart`

Legacy/time prototype:
- `lib/logic/game_engine.dart`

## 4. Verified status

Verified on March 14, 2026:
- `flutter analyze` passed
- `flutter test` passed

Relevant tests:
- `test/hero_model_test.dart`
- `test/class_progression_service_test.dart`
- `test/player_data_test.dart`
- `test/tower_run_service_test.dart`
- `test/agent_ai_service_test.dart`
- `test/widget_test.dart`

## 5. What was completed in the latest round

- Added utility shop support so `Tower Warp Stone` is actually purchasable
- Added starter inventory for new save data with initial warp stones and rations
- Added persisted AI settings to player save data
- Added `AI Settings` screen for choosing rule-based vs Ollama
- Added Ollama connection test flow
- Wired tower advice request button to use `AgentAiService`
- Preserved safe fallback to existing rule-based advice
- Updated tests for AI settings serialization and fallback behavior

## 6. Known limitations

These are not broken, but still prototype-grade:

1. Ollama is only used for tower advice text right now, not for full autonomous combat behavior.
2. Tower battle resolution is still simulation-based, not full turn-by-turn combat with actual skill timelines.
3. Safe points, prep purchasing inside the tower, and warp routing are still simplified.
4. Item crafting and equipment depth are useful but not yet full RPG-grade loadout systems.
5. Base management and in-game time systems are still not fully integrated with the tower/economy loop.
6. `README.md` is still the default Flutter template and does not describe the project yet.

## 7. Best next steps

Recommended order for the next sprint:

1. Expand AI beyond advice
- Let Ollama generate party chatter, character intent, and event reactions
- Optionally let Ollama propose pre-run preparation plans
- Keep hard gameplay validation server-side/in-code to avoid unstable outputs affecting save data

2. Deepen tower prep and route logic
- Add safe points and internal floor warp routing
- Lock buying to safe points / merchants only
- Let player choose return-to-cleared-floor flow more explicitly

3. Improve combat readability
- Show per-hero skill timeline, cooldown countdown, and item triggers more clearly
- Add stronger mapping between monster family and counter-skills
- Move closer to turn-by-turn or tick-by-tick resolution if needed

4. Improve equipment and crafting
- Add upgrade tiers, gear progression identity, and stronger set/relic effects
- Make crafting outputs more meaningful for class branches

## 8. Git upload checklist

Before pushing:
- confirm `flutter analyze`
- confirm `flutter test`
- commit `HANDOFF_STATUS.md` together with code changes
- optionally update `README.md` so the repository is understandable from Git alone

Suggested commit scope for the latest round:
- warp stone shop availability
- AI settings persistence
- Ollama integration for advice
- updated handoff document

## 9. If continuing in another session

Good prompt to resume:

`Read HANDOFF_STATUS.md first, then continue by expanding Ollama from advice-only into richer character behavior while keeping rule-based fallback and save compatibility intact.`
