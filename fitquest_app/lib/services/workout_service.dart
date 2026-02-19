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
  static Future<void> assignPlan(String username, String password, int planId, List<int> recruitIds) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/workouts/assign/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({
        "plan_id": planId,
        "recruit_ids": recruitIds
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign: ${response.body}');
    }
  }
}