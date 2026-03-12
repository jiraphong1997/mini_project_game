import 'dart:async';

import 'package:flutter/material.dart';

import '../models/hero_model.dart';
import '../models/item_model.dart';
import '../models/party_model.dart';
import '../models/player_data.dart';
import '../services/class_progression_service.dart';
import '../services/tower_run_service.dart';

class TowerScreen extends StatefulWidget {
  final PlayerData playerData;
  final VoidCallback onDataChanged;
  final VoidCallback onOpenGacha;

  const TowerScreen({
    super.key,
    required this.playerData,
    required this.onDataChanged,
    required this.onOpenGacha,
  });

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  static const String _mainPartyId = 'main_expedition';
  static const List<String> _formations = [
    'balanced',
    'assault',
    'bulwark',
    'swift',
  ];

  late final Set<String> _selectedHeroIds;
  Timer? _runTimer;
  Timer? _recoveryTicker;
  bool _isRunActive = false;
  int _currentFloor = 1;
  int _floorsProcessed = 0;
  int _remainingAdvice = 0;
  int _nextEnemyModifier = 0;
  int _nextRewardModifier = 0;
  int _sessionSilver = 0;
  int _sessionGold = 0;
  int _sessionExp = 0;
  List<ItemModel> _sessionItems = [];
  final List<String> _liveLog = [];
  TowerFloorOutcome? _lastFloorOutcome;
  TowerDecisionEvent? _pendingDecision;
  String? _adviceMessage;

  @override
  void initState() {
    super.initState();
    _selectedHeroIds = {..._currentParty.memberIds};
    _startRecoveryTicker();
  }

  @override
  void dispose() {
    _runTimer?.cancel();
    _recoveryTicker?.cancel();
    super.dispose();
  }

  PartyModel get _currentParty {
    final existing = widget.playerData.savedParties.where(
      (party) => party.partyId == _mainPartyId,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final party = PartyModel(
      partyId: _mainPartyId,
      partyName: 'Main Expedition',
      members: const [],
    );
    widget.playerData.savedParties = [...widget.playerData.savedParties, party];
    return party;
  }

  List<HeroModel> get _availableHeroes =>
      widget.playerData.allHeroes.where((hero) => hero.isAlive).toList();

  bool get _partyNeedsRecovery =>
      _currentParty.members.any((hero) => hero.isRecovering);

  Duration get _partyRecoveryRemaining {
    var remaining = Duration.zero;
    for (final hero in _currentParty.members) {
      if (hero.recoveryCooldownRemaining > remaining) {
        remaining = hero.recoveryCooldownRemaining;
      }
    }
    return remaining;
  }

  int get _rationCount => widget.playerData.itemQuantity(TowerRunService.recoveryItemId);

  void _startRecoveryTicker() {
    _recoveryTicker?.cancel();
    _recoveryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      final party = _currentParty;
      if (party.members.isEmpty || _isRunActive) {
        return;
      }

      final hasCooldown = party.members.any(
        (hero) => hero.recoveryReadyAtEpochMs != null,
      );
      if (!hasCooldown) {
        return;
      }

      final hasFinishedCooldown = party.members.any(
        (hero) => hero.recoveryReadyAtEpochMs != null && !hero.isRecovering,
      );
      if (hasFinishedCooldown) {
        TowerRunService.refreshRecoveryState(party);
        widget.onDataChanged();
        return;
      }

      setState(() {});
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleHero(String heroId, bool selected) {
    setState(() {
      if (selected) {
        if (_selectedHeroIds.length < 5) {
          _selectedHeroIds.add(heroId);
        }
      } else {
        _selectedHeroIds.remove(heroId);
      }
    });
  }

  void _autoFillParty() {
    final strongestHeroes = [..._availableHeroes]
      ..sort((a, b) {
        if (a.isRecovering != b.isRecovering) {
          return a.isRecovering ? 1 : -1;
        }
        final left = a.currentStats.atk + a.currentStats.def + a.currentStats.spd;
        final right = b.currentStats.atk + b.currentStats.def + b.currentStats.spd;
        return right.compareTo(left);
      });

    setState(() {
      _selectedHeroIds
        ..clear()
        ..addAll(strongestHeroes.take(5).map((hero) => hero.id));
    });
  }

  void _saveParty() {
    final selectedMembers = widget.playerData.allHeroes
        .where((hero) => _selectedHeroIds.contains(hero.id))
        .toList();

    setState(() {
      _currentParty.members = selectedMembers;
      TowerRunService.refreshRecoveryState(_currentParty);
      if (selectedMembers.isEmpty) {
        _currentParty.status = 'idle';
      } else if (_currentParty.members.any((hero) => hero.isRecovering)) {
        _currentParty.status = 'recovering';
      } else {
        _currentParty.status = 'ready';
      }
    });
    widget.onDataChanged();

    _showSnackBar('บันทึกปาร์ตี้แล้ว ${selectedMembers.length} คน');
  }

  void _startRealtimeRun() {
    if (_currentParty.members.isEmpty) {
      _showSnackBar('กรุณาบันทึกปาร์ตี้ก่อนเริ่มปีนหอ');
      return;
    }

    if (!TowerRunService.canStartExpedition(_currentParty)) {
      setState(() {});
      _showSnackBar(
        'ทีมยังพักฟื้นอยู่ อีก ${_formatDuration(_partyRecoveryRemaining)} หรือใช้เงิน/Field Ration เพื่อเร่งพัก',
      );
      return;
    }

    _runTimer?.cancel();

    setState(() {
      _isRunActive = true;
      _currentFloor = widget.playerData.highestTowerFloor + 1;
      _floorsProcessed = 0;
      _remainingAdvice = TowerRunService.adviceChargesForParty(_currentParty);
      _nextEnemyModifier = 0;
      _nextRewardModifier = 0;
      _sessionSilver = 0;
      _sessionGold = 0;
      _sessionExp = 0;
      _sessionItems = [];
      _liveLog.clear();
      _lastFloorOutcome = null;
      _pendingDecision = null;
      _adviceMessage = null;
      _currentParty.status = 'tower_climbing';
      _liveLog.add('เริ่มสำรวจหอคอยที่ชั้น $_currentFloor');
    });
    widget.onDataChanged();

    _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _advanceRun();
    });
  }

  void _advanceRun() {
    if (!mounted || !_isRunActive || _pendingDecision != null) {
      return;
    }

    if (_floorsProcessed >= 6) {
      _finishRun('ครบแผนการสำรวจรอบนี้ ทีมถอนกำลังกลับฐาน');
      return;
    }

    final majorEvent = TowerRunService.maybeCreateMajorEvent(
      playerData: widget.playerData,
      floor: _currentFloor,
    );
    if (majorEvent != null) {
      _runTimer?.cancel();
      setState(() {
        _pendingDecision = majorEvent;
        _adviceMessage = null;
        _liveLog.add('พบเหตุการณ์ใหญ่: ${majorEvent.title}');
      });
      widget.playerData.lastTowerSummary = _liveLog.join('\n');
      widget.onDataChanged();
      return;
    }

    final outcome = TowerRunService.resolveFloor(
      playerData: widget.playerData,
      party: _currentParty,
      floor: _currentFloor,
      enemyModifier: _nextEnemyModifier,
      rewardModifier: _nextRewardModifier,
    );

    setState(() {
      _lastFloorOutcome = outcome;
      _floorsProcessed += 1;
      _sessionSilver += outcome.silverReward;
      _sessionGold += outcome.goldReward;
      _sessionExp += outcome.expPerHero;
      _sessionItems = [..._sessionItems, ...outcome.itemRewards];
      _liveLog.addAll(outcome.logLines);
      _nextEnemyModifier = 0;
      _nextRewardModifier = 0;
      if (outcome.succeeded) {
        _currentFloor += 1;
      }
    });
    widget.playerData.lastTowerSummary = _liveLog.join('\n');
    widget.onDataChanged();

    if (!outcome.succeeded) {
      _finishRun('การสำรวจยุติที่ชั้น ${outcome.floor}');
    }
  }

  void _askForAdvice() {
    final event = _pendingDecision;
    if (event == null || _remainingAdvice <= 0) {
      return;
    }

    setState(() {
      _remainingAdvice -= 1;
      _adviceMessage = TowerRunService.buildAdvice(
        party: _currentParty,
        event: event,
      );
    });
  }

  void _applyDecision(String optionId) {
    final event = _pendingDecision;
    if (event == null) {
      return;
    }

    final outcome = TowerRunService.applyDecision(
      playerData: widget.playerData,
      party: _currentParty,
      floor: _currentFloor,
      event: event,
      optionId: optionId,
    );

    setState(() {
      _nextEnemyModifier += outcome.enemyModifierDelta;
      _nextRewardModifier += outcome.rewardModifierDelta;
      _sessionSilver += outcome.silverDelta;
      _sessionGold += outcome.goldDelta;
      _sessionItems = [..._sessionItems, ...outcome.immediateItems];
      _liveLog.addAll(outcome.logLines);
      _pendingDecision = null;
      _adviceMessage = null;
    });
    widget.playerData.lastTowerSummary = _liveLog.join('\n');
    widget.onDataChanged();

    _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _advanceRun();
    });
  }

  void _finishRun(String summary) {
    _runTimer?.cancel();
    final needsRecovery = _currentParty.members.isNotEmpty;
    final recoveryDuration = needsRecovery
        ? TowerRunService.scheduleRecoveryCooldown(
            _currentParty,
            clearedFloors: _floorsProcessed <= 0 ? 1 : _floorsProcessed,
          )
        : Duration.zero;

    setState(() {
      _isRunActive = false;
      _liveLog.add(summary);
      if (recoveryDuration > Duration.zero) {
        _liveLog.add(
          'ทีมต้องพักฟื้น ${_formatDuration(recoveryDuration)} หรือเร่งพักด้วยเงิน/Field Ration',
        );
      }
    });
    widget.playerData.lastTowerSummary = _liveLog.join('\n');
    widget.onDataChanged();
  }

  void _stopRunEarly() {
    if (!_isRunActive) {
      return;
    }
    _finishRun('ผู้เล่นสั่งถอนกำลังกลับเมนูหลัก');
  }

  void _quickRecoverWithSilver() {
    if (_currentParty.members.isEmpty) {
      return;
    }

    final cost = TowerRunService.quickRecoverySilverCost(_currentParty);
    final recovered =
        TowerRunService.quickRecoverWithSilver(widget.playerData, _currentParty);
    if (!recovered) {
      _showSnackBar('Silver ไม่พอ ต้องใช้ $cost');
      return;
    }

    setState(() {});
    widget.onDataChanged();
    _showSnackBar('ใช้ $cost Silver เพื่อเร่งพักฟื้นทีมเรียบร้อย');
  }

  void _quickRecoverWithItem() {
    if (_currentParty.members.isEmpty) {
      return;
    }

    final recovered =
        TowerRunService.quickRecoverWithItem(widget.playerData, _currentParty);
    if (!recovered) {
      _showSnackBar('ไม่มี Field Ration ในคลัง');
      return;
    }

    setState(() {});
    widget.onDataChanged();
    _showSnackBar('ใช้ Field Ration เร่งพักฟื้นทีมเรียบร้อย');
  }

  @override
  Widget build(BuildContext context) {
    final currentParty = _currentParty;
    final availableHeroes = _availableHeroes;
    TowerRunService.refreshRecoveryState(currentParty);

    if (widget.playerData.allHeroes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stairs_outlined, size: 72, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'ยังไม่มีฮีโร่สำหรับจัดปาร์ตี้',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'สุ่มฮีโร่ก่อน แล้วค่อยกลับมาจัดทีมเพื่อทดสอบปีนหอ',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.onOpenGacha,
                icon: const Icon(Icons.star),
                label: const Text('ไปหน้า Gacha'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressHeader(),
        const SizedBox(height: 16),
        _buildPartyCard(currentParty),
        const SizedBox(height: 16),
        _buildRecoveryCard(),
        const SizedBox(height: 16),
        _buildActionsCard(),
        if (_pendingDecision != null) ...[
          const SizedBox(height: 16),
          _buildDecisionCard(_pendingDecision!),
        ],
        const SizedBox(height: 16),
        _buildSelectionCard(availableHeroes),
        const SizedBox(height: 16),
        _buildLatestResultCard(),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tower Expedition',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ชั้นสูงสุดที่เคยผ่าน: ${widget.playerData.highestTowerFloor}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _isRunActive
                ? 'กำลังดำเนินการที่ชั้น $_currentFloor'
                : 'ชั้นถัดไปที่แนะนำ: ${widget.playerData.highestTowerFloor + 1}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _partyNeedsRecovery
                ? 'ทีมพร้อมอีก ${_formatDuration(_partyRecoveryRemaining)}'
                : 'ทีมพร้อมลุย',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Advice ที่เหลือ: $_remainingAdvice',
            style: const TextStyle(color: Colors.white70),
          ),
          if (_isRunActive) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPartyCard(PartyModel party) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ปาร์ตี้หลัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('ชื่อทีม: ${party.partyName}'),
            Text('สถานะ: ${party.status}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: party.formation,
              decoration: const InputDecoration(
                labelText: 'Formation',
                border: OutlineInputBorder(),
              ),
              items: _formations
                  .map(
                    (formation) => DropdownMenuItem<String>(
                      value: formation,
                      child: Text(_formationLabel(formation)),
                    ),
                  )
                  .toList(),
              onChanged: _isRunActive
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        party.formation = value;
                      });
                      widget.onDataChanged();
                    },
            ),
            const SizedBox(height: 12),
            Text('จำนวนสมาชิก: ${party.members.length}/5'),
            Text('พลังรวมทีม: ${party.partyPower}'),
            const SizedBox(height: 12),
            if (party.members.isEmpty)
              const Text('ยังไม่ได้บันทึกปาร์ตี้')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: party.members.map((hero) {
                  final classTitle =
                      ClassProgressionService.definitionFor(hero.currentClass).title;
                  final trailing = hero.isRecovering
                      ? ' • Recover ${_formatDuration(hero.recoveryCooldownRemaining)}'
                      : '';
                  return Chip(
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(
                      '${hero.name} Lv.${hero.level} • $classTitle$trailing',
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryCard() {
    final party = _currentParty;
    final silverCost = TowerRunService.quickRecoverySilverCost(party);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recovery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (party.members.isEmpty)
              const Text('เลือกและบันทึกปาร์ตี้ก่อนเพื่อดูสถานะพักฟื้น')
            else if (!_partyNeedsRecovery)
              const Text('ทีมนี้พร้อมลุย ไม่มีคูลดาวน์ค้างอยู่')
            else ...[
              Text('พักตามเวลา: ${_formatDuration(_partyRecoveryRemaining)}'),
              Text('เร่งพักด้วย Silver: $silverCost'),
              Text('Field Ration ในคลัง: $_rationCount'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isRunActive ? null : _quickRecoverWithSilver,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('เร่งพักด้วยเงิน'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed:
                        _isRunActive || _rationCount <= 0 ? null : _quickRecoverWithItem,
                    icon: const Icon(Icons.restaurant_outlined),
                    label: const Text('ใช้ Field Ration'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _isRunActive ? null : _saveParty,
              icon: const Icon(Icons.save_outlined),
              label: const Text('บันทึกปาร์ตี้'),
            ),
            FilledButton.tonalIcon(
              onPressed: _isRunActive ? null : _autoFillParty,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: const Text('จัดทีมอัตโนมัติ'),
            ),
            FilledButton.icon(
              key: const Key('tower_start_button'),
              onPressed: _isRunActive || _partyNeedsRecovery ? null : _startRealtimeRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('เริ่มสำรวจแบบเรียลไทม์'),
            ),
            FilledButton.tonalIcon(
              onPressed: _isRunActive ? _stopRunEarly : null,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('ถอนกำลัง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(TowerDecisionEvent event) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 12),
            if (_adviceMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_adviceMessage!),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in event.options)
                  FilledButton.tonal(
                    onPressed: () => _applyDecision(option.id),
                    child: Text(option.title),
                  ),
                OutlinedButton.icon(
                  onPressed: _remainingAdvice > 0 ? _askForAdvice : null,
                  icon: const Icon(Icons.record_voice_over_outlined),
                  label: const Text('ขอคำแนะนำ'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...event.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${option.title}: ${option.description}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(List<HeroModel> availableHeroes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกฮีโร่เข้าทีม',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('เลือกได้สูงสุด 5 คน และต้องกดบันทึกปาร์ตี้ก่อนเริ่มปีนหอ'),
            const SizedBox(height: 12),
            ...availableHeroes.map((hero) {
              final selected = _selectedHeroIds.contains(hero.id);
              final classTitle =
                  ClassProgressionService.definitionFor(hero.currentClass).title;
              return CheckboxListTile(
                value: selected,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: _isRunActive
                    ? null
                    : (value) {
                        _toggleHero(hero.id, value ?? false);
                      },
                secondary: Text(
                  'HP ${hero.currentStats.currentHp}/${hero.currentStats.maxHp}\n'
                  'ENG ${hero.currentStats.currentEng}/${hero.currentStats.maxEng}\n'
                  '${hero.isRecovering ? 'Recover ${_formatDuration(hero.recoveryCooldownRemaining)}' : 'พร้อมลุย'}',
                ),
                title: Text(hero.name),
                subtitle: Text(
                  'Lv.${hero.level} • ${hero.experienceStage} • $classTitle • Power ${hero.currentStats.atk + hero.currentStats.def + hero.currentStats.spd}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestResultCard() {
    final summary = widget.playerData.lastTowerSummary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expedition Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_lastFloorOutcome != null) ...[
              Text('ชั้นล่าสุด: ${_lastFloorOutcome!.floor}'),
              Text('Silver สะสม $_sessionSilver / Gold สะสม $_sessionGold'),
              Text('EXP ที่ทีมได้รอบนี้ +$_sessionExp ต่อคน'),
              if (_sessionItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sessionItems.take(6).map((item) {
                    return Chip(
                      avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: Text('${item.name} x${item.quantity}'),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
            ],
            if (_liveLog.isEmpty && (summary == null || summary.isEmpty))
              const Text('ยังไม่มีบันทึกการปีนหอล่าสุด')
            else
              Text(
                (_liveLog.isNotEmpty ? _liveLog : summary!.split('\n'))
                    .take(14)
                    .join('\n'),
              ),
          ],
        ),
      ),
    );
  }

  String _formationLabel(String formation) {
    switch (formation) {
      case 'assault':
        return 'Assault: เน้นโจมตี';
      case 'bulwark':
        return 'Bulwark: เน้นป้องกัน';
      case 'swift':
        return 'Swift: เน้นความเร็ว';
      default:
        return 'Balanced: สมดุล';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return 'พร้อมใช้งาน';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
