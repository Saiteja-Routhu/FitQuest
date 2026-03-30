import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GuildService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<Map<String, dynamic>> fetchGuildHub(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/quests/guild-quests/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load guild data');
  }
}
