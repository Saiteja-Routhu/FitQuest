import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // To get the baseUrl

class WorkoutService {
  static const String baseUrl = ApiService.baseUrl;

  // 1. Fetch the Global Exercise Library
  static Future<List<dynamic>> fetchExercises(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/exercises/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );

    if (response.statusCode == 200) {
      // Handle pagination if Django sends it, or list if not
      var data = jsonDecode(response.body);
      if (data is Map && data.containsKey('results')) return data['results'];
      if (data is List) return data;
    }
    throw Exception('Failed to load exercises');
  }

  // 2. Create a New Plan
  static Future<void> createPlan(String username, String password, Map<String, dynamic> planData) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/workouts/create/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(planData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create plan: ${response.body}');
    }
  }

  // 3. Fetch My Created Plans
  static Future<List<dynamic>> fetchMyPlans(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/my-plans/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data is Map && data.containsKey('results')) return data['results'];
      if (data is List) return data;
    }
    throw Exception('Failed to load plans');
  }

  // 4. Assign Plan to Recruit
  static Future<void> assignPlan(
    String username,
    String password,
    int planId,
    List<int> recruitIds, {
    int xpReward = 100,
    int coinReward = 10,
  }) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/workouts/assign/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({
        "plan_id": planId,
        "recruit_ids": recruitIds,
        "xp_reward": xpReward,
        "coin_reward": coinReward,
        "auto_quest": true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign: ${response.body}');
    }
  }

  // 5. Update an existing plan (full replace of exercises)
  static Future<void> updatePlan(String username, String password,
      int planId, Map<String, dynamic> data) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/plans/$planId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update plan: ${response.body}');
    }
  }

  // 6. Delete a plan
  static Future<void> deletePlan(String username, String password, int planId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/workouts/plans/$planId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete plan: ${response.body}');
    }
  }

  // 7. Fetch Assigned Plans (Recruit)
  static Future<List<dynamic>> fetchAssignedPlans(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/workouts/assigned/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load assigned plans');
  }

  // 8. Log a workout set
  static Future<Map<String, dynamic>> logSet(
      String username, String password, Map<String, dynamic> data) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/analytics/log-set/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to log set: ${response.body}');
  }
}