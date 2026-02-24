import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

const _kTimeout = Duration(seconds: 20);

class ChatService {
  static const _base = ApiService.baseUrl;

  static Map<String, String> _headers(String u, String p) => {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$u:$p'))}',
      };

  static Future<List<dynamic>> fetchDM(
      String u, String p, int athleteId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/chat/dm/$athleteId/'),
          headers: _headers(u, p),
        )
        .timeout(_kTimeout);
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Failed to load DM');
  }

  static Future<List<dynamic>> fetchCommunity(String u, String p) async {
    final resp = await http
        .get(
          Uri.parse('$_base/chat/community/'),
          headers: _headers(u, p),
        )
        .timeout(_kTimeout);
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Failed to load community feed');
  }

  static Future<void> sendMessage(
      String u, String p, String content, int? recipientId) async {
    final resp = await http
        .post(
          Uri.parse('$_base/chat/send/'),
          headers: _headers(u, p),
          body: jsonEncode({'content': content, 'recipient_id': recipientId}),
        )
        .timeout(_kTimeout);
    if (resp.statusCode != 201) {
      throw Exception('Failed to send message: ${resp.body}');
    }
  }

  static Future<void> markRead(String u, String p, int messageId) async {
    await http
        .post(
          Uri.parse('$_base/chat/read/$messageId/'),
          headers: _headers(u, p),
        )
        .timeout(_kTimeout);
  }

  // --- GROUP CHAT METHODS (Phase 4) ---

  static Future<List<dynamic>> fetchGroups(String u, String p) async {
    final resp = await http
        .get(
          Uri.parse('$_base/chat/groups/'),
          headers: _headers(u, p),
        )
        .timeout(_kTimeout);
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Failed to load groups');
  }

  static Future<Map<String, dynamic>> createGroup(
      String u, String p, String name, List<int> memberIds) async {
    final resp = await http
        .post(
          Uri.parse('$_base/chat/groups/create/'),
          headers: _headers(u, p),
          body: jsonEncode({'name': name, 'member_ids': memberIds}),
        )
        .timeout(_kTimeout);
    if (resp.statusCode == 201) return jsonDecode(resp.body);
    throw Exception('Failed to create group: ${resp.body}');
  }

  static Future<List<dynamic>> fetchGroupMessages(
      String u, String p, int groupId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/chat/group/$groupId/'),
          headers: _headers(u, p),
        )
        .timeout(_kTimeout);
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Failed to load group messages');
  }

  static Future<void> sendGroupMessage(
      String u, String p, int groupId, String content) async {
    final resp = await http
        .post(
          Uri.parse('$_base/chat/send/'),
          headers: _headers(u, p),
          body: jsonEncode({'group_id': groupId, 'content': content}),
        )
        .timeout(_kTimeout);
    if (resp.statusCode != 201) {
      throw Exception('Failed to send group message: ${resp.body}');
    }
  }
}
