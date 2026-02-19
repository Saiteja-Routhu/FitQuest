import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class NutritionService {
  static const String baseUrl = ApiService.baseUrl;

  // --- PANTRY (Ingredients) ---
  static Future<List<dynamic>> fetchPantry(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/pantry/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load pantry');
  }

  static Future<void> addFoodItem(String username, String password, Map<String, dynamic> foodData) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/pantry/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(foodData),
    );
    if (response.statusCode != 201) throw Exception('Failed to add food');
  }

  static Future<void> deleteFoodItem(String username, String password, int id) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/pantry/$id/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 204) throw Exception('Failed to delete item');
  }

  // --- DIET PLANS ---
  static Future<List<dynamic>> fetchMyPlans(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/plans/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load diet plans');
  }

  static Future<void> createDietPlan(String username, String password, Map<String, dynamic> planData) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/create/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(planData),
    );
    if (response.statusCode != 201) throw Exception('Failed to create plan');
  }

  static Future<void> deletePlan(String username, String password, int planId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/plan/$planId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode != 204) throw Exception('Failed to delete plan');
  }

  static Future<void> assignDietPlan(String username, String password, int planId, List<int> recruitIds) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/assign/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"plan_id": planId, "recruit_ids": recruitIds}),
    );
    if (response.statusCode != 200) throw Exception('Failed to assign diet');
  }

  // --- NEW: EDIT MEALS & SCHEDULE ---

  static Future<void> updateMeal(String username, String password, int mealId, List<Map<String, dynamic>> items) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/meal/$mealId/update/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"items": items}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update meal');
  }

  static Future<List<dynamic>> fetchSchedule(String username, String password, int recruitId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/schedule/$recruitId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load schedule');
  }

  static Future<void> setScheduleDay(String username, String password, int recruitId, String day, int? planId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/schedule/$recruitId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"day": day, "plan_id": planId}),
    );
    if (response.statusCode != 200) throw Exception('Failed to set schedule');
  }
}