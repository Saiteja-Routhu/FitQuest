import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class QuestService {
  static const String _base = ApiService.baseUrl;

  static String _auth(String u, String p) =>
      'Basic ${base64Encode(utf8.encode('$u:$p'))}';

  static Map<String, String> _headers(String u, String p) => {
        'Content-Type': 'application/json',
        'Authorization': _auth(u, p),
      };

  // ── Coach ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchMyQuests(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/quests/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('results')) return data['results'];
      if (data is List) return data;
    }
    throw Exception('Failed to load quests');
  }

  static Future<void> createQuest(
      String username, String password, Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_base/quests/create/'),
      headers: _headers(username, password),
      body: jsonEncode(data),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to create quest: ${resp.body}');
    }
  }

  // Returns the created quest map (includes 'id') or null on failure
  static Future<Map<String, dynamic>?> createQuestWithId(
      String username, String password, Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_base/quests/create/'),
      headers: _headers(username, password),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201) return jsonDecode(resp.body);
    throw Exception('Failed to create quest: ${resp.body}');
  }

  static Future<void> assignQuest(String username, String password,
      int questId, List<int> recruitIds, {bool isCommunity = false}) async {
    final resp = await http.post(
      Uri.parse('$_base/quests/assign/'),
      headers: _headers(username, password),
      body: jsonEncode({
        'quest_id': questId,
        'recruit_ids': recruitIds,
        'is_community': isCommunity,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to assign quest: ${resp.body}');
    }
  }

  static Future<void> deleteQuest(
      String username, String password, int questId) async {
    final resp = await http.delete(
      Uri.parse('$_base/quests/$questId/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode != 204) {
      throw Exception('Failed to delete quest');
    }
  }

  // ── Recruit ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchMyAssignedQuests(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/quests/my-quests/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('results')) return data['results'];
      if (data is List) return data;
    }
    throw Exception('Failed to load quests');
  }

  static Future<Map<String, dynamic>> completeQuest(
      String username, String password, int questId) async {
    final resp = await http.post(
      Uri.parse('$_base/quests/complete/'),
      headers: _headers(username, password),
      body: jsonEncode({'quest_id': questId}),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception(jsonDecode(resp.body)['error'] ?? 'Failed to complete quest');
  }

  // ── Daily Quests ────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchTodayQuests(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/quests/today/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load today quests');
  }

  static Future<Map<String, dynamic>> completeTodayQuest(
      String username, String password,
      String sourceType, int sourceId) async {
    final resp = await http.post(
      Uri.parse('$_base/quests/today/complete/'),
      headers: _headers(username, password),
      body: jsonEncode({
        'source_type': sourceType,
        'source_id': sourceId,
      }),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    final body = jsonDecode(resp.body);
    throw Exception(body['error'] ?? 'Failed to complete daily quest');
  }
}
