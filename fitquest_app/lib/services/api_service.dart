import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const bool _useProd = true; // flip to false for local dev
  static const String baseUrl = _useProd
      ? 'https://fitquest-api.onrender.com/api'
      : 'http://192.168.1.6:8000/api'; // update IP as needed

  // --- AUTH ---
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw Exception('Server unreachable — check your network and try again');
    });
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to register: ${response.body}');
  }

  static Future<Map<String, dynamic>> loginUser(String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password, "role": role}),
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw Exception('Server unreachable — check your network and try again');
    });
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

  // --- SESSION (Remember Me) ---
  static Future<void> saveSession(
      String username, String password, int roleIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fq_username',   username);
    await prefs.setString('fq_password',   password);
    await prefs.setInt('fq_role_index',    roleIndex);
  }

  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs     = await SharedPreferences.getInstance();
    final username  = prefs.getString('fq_username');
    final password  = prefs.getString('fq_password');
    final roleIndex = prefs.getInt('fq_role_index');
    if (username != null && password != null && roleIndex != null) {
      return {'username': username, 'password': password, 'roleIndex': roleIndex};
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fq_username');
    await prefs.remove('fq_password');
    await prefs.remove('fq_role_index');
  }

  static Future<void> acknowledgeRecruit(String username, String password, int recruitId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(
      Uri.parse('$baseUrl/users/acknowledge-recruit/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"recruit_id": recruitId}),
    );
  }

  static Future<Map<String, dynamic>> fetchCoachSummary(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/coach-summary/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load coach summary');
  }

  static Future<Map<String, dynamic>> fetchAthleteAnalytics(
      String username, String password, int recruitId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/athletes/$recruitId/analytics/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load analytics');
  }

  static Future<List<dynamic>> fetchLeaderboard(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/leaderboard/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load leaderboard');
  }

  static Future<Map<String, dynamic>> fetchMyCoach(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/my-coach/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('No coach assigned');
  }

  // Generic authenticated POST helper used by assessment wizard
  static Future<Map<String, dynamic>> postWithBasicAuth(
      String path, String username, String password,
      Map<String, dynamic> body) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed: ${response.body}');
  }

  // --- PHASE 4 NEW METHODS ---

  static Future<Map<String, dynamic>> patchProfile(
      String username, String password, Map<String, dynamic> data) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.patch(
      Uri.parse('$baseUrl/users/profile/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update profile: ${response.body}');
  }

  static Future<List<dynamic>> fetchManagedCoaches(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/my-coaches/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['results'] ?? []);
    }
    throw Exception('Failed to load managed coaches');
  }

  static Future<List<dynamic>> fetchCoachAthletes(
      String username, String password, int coachId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/coach/$coachId/athletes/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['results'] ?? []);
    }
    throw Exception('Failed to load coach athletes');
  }

  static Future<void> deleteUser(
      String adminUser, String adminPass, int userId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$adminUser:$adminPass'));
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/delete/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> generateKeyForRole(
      String username, String password, String keyType) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/users/generate-key/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({'key_type': keyType}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to generate key');
  }

  // --- Phase 7: Super Coach "All" endpoints ---

  static Future<List<dynamic>> fetchAllAthletesSC(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/sc-all-athletes/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['results'] ?? []);
    }
    throw Exception('Failed to load all athletes');
  }

  static Future<List<dynamic>> fetchAllCoachesSC(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/users/sc-all-coaches/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['results'] ?? []);
    }
    throw Exception('Failed to load all coaches');
  }

  static Future<void> scClaimCoach(String username, String password, int coachId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/users/sc-claim-coach/$coachId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 200) throw Exception('Failed to claim coach: ${response.body}');
  }

  static Future<void> scClaimAthlete(String username, String password, int athlId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/users/sc-claim-athlete/$athlId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 200) throw Exception('Failed to claim athlete: ${response.body}');
  }
}