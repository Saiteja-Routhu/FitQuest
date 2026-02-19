import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 CHANGE THIS TO YOUR LAPTOP IP
  static const String baseUrl = 'http://192.168.1.4:8000/api';

  // --- AUTH ---
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to register: ${response.body}');
  }

  static Future<Map<String, dynamic>> loginUser(String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password, "role": role}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Login failed: ${response.statusCode}');
  }

  // --- ADMIN TOOLS ---
  static Future<String> generateCoachKey(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/users/generate-key/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 201) return jsonDecode(response.body)['key'];
    throw Exception('Failed to generate key');
  }

  // ✅ FIXED: Handles Pagination (Map vs List)
  static Future<List<dynamic>> fetchAllUsers(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/all/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if Django sent a Paginated Map (with 'results') or a direct List
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      } else if (data is List) {
        return data;
      }
    }
    throw Exception('Failed to load users');
  }

  static Future<void> assignCoach(String adminUser, String adminPass, int recruitId, int coachId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$adminUser:$adminPass'));
    final response = await http.post(
      Uri.parse('$baseUrl/users/assign-coach/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"recruit_id": recruitId, "coach_id": coachId}),
    );
    if (response.statusCode != 200) throw Exception('Failed to assign coach: ${response.body}');
  }

  // --- COACH TOOLS ---

  // ✅ FIXED: Handles Pagination (Map vs List)
  static Future<List<dynamic>> fetchMyRoster(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/my-roster/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if Django sent a Paginated Map (with 'results') or a direct List
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'];
      } else if (data is List) {
        return data;
      }
    }
    throw Exception('Failed to load roster');
  }

  static Future<void> acknowledgeRecruit(String username, String password, int recruitId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(
      Uri.parse('$baseUrl/users/acknowledge-recruit/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"recruit_id": recruitId}),
    );
  }
}