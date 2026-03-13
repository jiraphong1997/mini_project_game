import 'dart:convert';
import 'dart:io';

import '../models/agent_ai_settings.dart';
import '../models/hero_model.dart';
import '../models/party_model.dart';
import '../models/player_data.dart';
import 'tower_run_service.dart';

class AgentAiConnectionResult {
  final bool success;
  final String message;
  final List<String> availableModels;

  const AgentAiConnectionResult({
    required this.success,
    required this.message,
    this.availableModels = const [],
  });
}

class AgentAiService {
  static Future<String> buildTowerAdvice({
    required PlayerData playerData,
    required PartyModel party,
    required TowerDecisionEvent event,
  }) async {
    final fallbackAdvice = TowerRunService.buildAdvice(
      party: party,
      event: event,
    );
    final settings = playerData.aiSettings;
    if (!settings.usesOllama) {
      return fallbackAdvice;
    }

    try {
      final response = await _generateWithOllama(
        settings: settings,
        prompt: _buildAdvicePrompt(
          playerData: playerData,
          party: party,
          event: event,
          fallbackAdvice: fallbackAdvice,
        ),
      );
      if (response.isEmpty) {
        return fallbackAdvice;
      }
      return response;
    } catch (_) {
      if (settings.fallbackToRuleBased) {
        return '$fallbackAdvice\n\n[สลับมาใช้คำแนะนำสำรอง เพราะ Ollama ไม่ตอบสนอง]';
      }
      rethrow;
    }
  }

  static Future<AgentAiConnectionResult> testConnection(
    AgentAiSettings settings,
  ) async {
    if (!settings.usesOllama) {
      return const AgentAiConnectionResult(
        success: true,
        message: 'ตอนนี้ใช้ระบบตัดสินใจในเกมอยู่ ยังไม่เปิด Ollama',
      );
    }

    try {
      final baseUri = _normalizeBaseUri(settings.ollamaBaseUrl);
      final client = HttpClient()..connectionTimeout = _timeout(settings);
      try {
        final request = await client.getUrl(baseUri.resolve('/api/tags'));
        final response = await request.close().timeout(_timeout(settings));
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return AgentAiConnectionResult(
            success: false,
            message:
                'เชื่อมต่อ Ollama ไม่สำเร็จ (${response.statusCode}) ที่ ${settings.ollamaBaseUrl}',
          );
        }

        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final models = (decoded['models'] as List<dynamic>? ?? const []).map((
          entry,
        ) {
          final map = entry as Map<String, dynamic>;
          return (map['model'] as String?) ??
              (map['name'] as String?) ??
              'unknown';
        }).toList();

        final hasModel = models.any((model) => model == settings.ollamaModel);
        final message = hasModel
            ? 'เชื่อมต่อ Ollama สำเร็จและพบโมเดล ${settings.ollamaModel}'
            : 'เชื่อมต่อ Ollama สำเร็จ แต่ยังไม่พบโมเดล ${settings.ollamaModel}';
        return AgentAiConnectionResult(
          success: hasModel,
          message: message,
          availableModels: models,
        );
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      return AgentAiConnectionResult(
        success: false,
        message: 'เชื่อมต่อ Ollama ไม่ได้: $error',
      );
    }
  }

  static String _buildAdvicePrompt({
    required PlayerData playerData,
    required PartyModel party,
    required TowerDecisionEvent event,
    required String fallbackAdvice,
  }) {
    final partySummary = party.members.isEmpty
        ? 'ไม่มีสมาชิกในปาร์ตี้'
        : party.members.map(_heroSummary).join('\n');
    final options = event.options
        .map((option) => '- ${option.title}: ${option.description}')
        .join('\n');

    return '''
คุณคือผู้ช่วยตัดสินใจเชิงแท็คติกของเกมปีนหอแฟนตาซี
ตอบเป็นภาษาไทยเท่านั้น แบบกระชับ 2-4 ประโยค
โทนเป็นคำแนะนำที่หัวหน้าทีมจะใช้ตัดสินใจได้ทันที
ถ้าข้อมูลไม่พอ ให้ยึดตามคำแนะนำสำรองที่ให้ไว้

ข้อมูลผู้เล่น:
- Silver: ${playerData.silver}
- Gold: ${playerData.gold}
- ชั้นสูงสุดที่เคยผ่าน: ${playerData.highestTowerFloor}

ปาร์ตี้ปัจจุบัน:
$partySummary

เหตุการณ์:
- ชื่อ: ${event.title}
- รายละเอียด: ${event.description}
- ทางเลือก:
$options

คำแนะนำสำรองจากระบบ:
$fallbackAdvice

สรุปคำแนะนำที่ควรเลือก พร้อมเหตุผลสั้นๆ และถ้าควรระวังอะไรให้บอกเพิ่มท้ายประโยคเดียว
''';
  }

  static String _heroSummary(HeroModel hero) {
    final statuses = hero.statusEffects.isEmpty
        ? 'ไม่มี'
        : hero.statusEffects.join(', ');
    return [
      '${hero.name} (${hero.currentClass})',
      'Lv.${hero.level}',
      'HP ${hero.currentStats.currentHp}/${hero.currentStats.maxHp}',
      'ENG ${hero.currentStats.currentEng}/${hero.currentStats.maxEng}',
      'MP ${hero.currentMana}/${hero.maxMana}',
      'Bond ${hero.bond}',
      'Faith ${hero.faith}',
      'สภาพ ${hero.bodyCondition}',
      'สถานะ $statuses',
    ].join(' | ');
  }

  static Future<String> _generateWithOllama({
    required AgentAiSettings settings,
    required String prompt,
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout(settings);
    try {
      final uri = _normalizeBaseUri(
        settings.ollamaBaseUrl,
      ).resolve('/api/generate');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': settings.ollamaModel,
          'prompt': prompt,
          'stream': false,
          'options': {'temperature': settings.temperature},
        }),
      );
      final response = await request.close().timeout(_timeout(settings));
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Ollama ตอบกลับด้วยสถานะ ${response.statusCode}',
          uri: uri,
        );
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final text = (decoded['response'] as String? ?? '').trim();
      return _sanitizeResponse(text);
    } finally {
      client.close(force: true);
    }
  }

  static Uri _normalizeBaseUri(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return Uri.parse('http://127.0.0.1:11434');
    }
    final normalized = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return Uri.parse(normalized);
  }

  static Duration _timeout(AgentAiSettings settings) {
    return Duration(seconds: settings.requestTimeoutSeconds.clamp(5, 120));
  }

  static String _sanitizeResponse(String response) {
    if (response.isEmpty) {
      return response;
    }

    final compact = response
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    final lines = compact.split('\n');
    if (lines.length <= 4) {
      return compact;
    }
    return lines.take(4).join('\n').trim();
  }
}
