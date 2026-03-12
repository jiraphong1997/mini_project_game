import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_data.dart';

class PlayerStorageService {
  static const String _playerDataKey = 'player_data_v1';

  Future<PlayerData?> loadPlayerData() async {
    final preferences = await SharedPreferences.getInstance();
    final rawData = preferences.getString(_playerDataKey);

    if (rawData == null || rawData.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawData) as Map<String, dynamic>;
    return PlayerData.fromMap(decoded);
  }

  Future<void> savePlayerData(PlayerData playerData) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(playerData.toMap());
    await preferences.setString(_playerDataKey, encoded);
  }

  Future<void> clearPlayerData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_playerDataKey);
  }
}
