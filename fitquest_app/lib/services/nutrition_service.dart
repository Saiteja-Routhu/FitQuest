import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

const _kTimeout = Duration(seconds: 20);

class NutritionService {
  static const String baseUrl = ApiService.baseUrl;

  // --- PANTRY (Ingredients) ---
  static Future<List<dynamic>> fetchPantry(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/pantry/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load pantry');
  }

  static Future<void> addFoodItem(String username, String password, Map<String, dynamic> foodData) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/pantry/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(foodData),
    ).timeout(_kTimeout);
    if (response.statusCode != 201) throw Exception('Failed to add food');
  }

  static Future<void> deleteFoodItem(String username, String password, int id) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/pantry/$id/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode != 204) throw Exception('Failed to delete item');
  }

  // --- DIET PLANS ---
  static Future<List<dynamic>> fetchMyPlans(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/plans/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load diet plans');
  }

  static Future<void> createDietPlan(String username, String password, Map<String, dynamic> planData) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/create/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(planData),
    ).timeout(_kTimeout);
    if (response.statusCode != 201) throw Exception('Failed to create plan');
  }

  static Future<void> deletePlan(String username, String password, int planId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/plan/$planId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode != 204) throw Exception('Failed to delete plan');
  }

  static Future<void> assignDietPlan(
    String username,
    String password,
    int planId,
    List<int> recruitIds, {
    int xpReward = 100,
    int coinReward = 10,
  }) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/assign/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({
        "plan_id": planId,
        "recruit_ids": recruitIds,
        "xp_reward": xpReward,
        "coin_reward": coinReward,
        "auto_quest": true,
      }),
    ).timeout(_kTimeout);
    if (response.statusCode != 200) throw Exception('Failed to assign diet');
  }

  // --- NEW: EDIT MEALS & SCHEDULE ---

  static Future<void> updateMeal(String username, String password, int mealId, List<Map<String, dynamic>> items) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/meal/$mealId/update/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"items": items}),
    ).timeout(_kTimeout);
    if (response.statusCode != 200) throw Exception('Failed to update meal');
  }

  static Future<List<dynamic>> fetchSchedule(String username, String password, int recruitId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/schedule/$recruitId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load schedule');
  }

  static Future<void> setScheduleDay(String username, String password, int recruitId, String day, int? planId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/schedule/$recruitId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode({"day": day, "plan_id": planId}),
    ).timeout(_kTimeout);
    if (response.statusCode != 200) throw Exception('Failed to set schedule');
  }

  // --- RECIPES ---
  static Future<List<dynamic>> fetchRecipes(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/recipes/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : data['results'] ?? [];
    }
    throw Exception('Failed to load recipes');
  }

  static Future<void> createRecipe(String username, String password, Map<String, dynamic> data) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$baseUrl/nutrition/recipes/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
      body: jsonEncode(data),
    ).timeout(_kTimeout);
    if (response.statusCode != 201) throw Exception('Failed to create recipe');
  }

  static Future<void> deleteRecipe(String username, String password, int recipeId) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/recipes/$recipeId/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode != 204) throw Exception('Failed to delete recipe');
  }

  // Fetch Assigned Diet Plans (Recruit)
  static Future<List<dynamic>> fetchAssignedDietPlans(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/assigned/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load assigned diet plans');
  }

  // Fetch own schedule (Recruit, Phase 4)
  static Future<List<dynamic>> fetchMySchedule(String username, String password) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/my-schedule/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }
    throw Exception('Failed to load my schedule');
  }

  // --- MEAL COMPLETION (Phase 6) ---

  static Future<Map<String, dynamic>> completeMeal(
    String username,
    String password,
    String mealName, {
    int? dietPlanId,
    File? photo,
  }) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final uri = Uri.parse('$baseUrl/nutrition/complete-meal/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = basicAuth;
    request.fields['meal_name'] = mealName;
    if (dietPlanId != null) request.fields['diet_plan_id'] = dietPlanId.toString();
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to complete meal: ${response.body}');
  }

  static Future<List<dynamic>> fetchMealCompletions(
    String username,
    String password,
    String date,
  ) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.get(
      Uri.parse('$baseUrl/nutrition/meal-completions/?date=$date'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load meal completions');
  }

  static Future<void> deleteMealCompletion(
    String username,
    String password,
    int id,
  ) async {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(
      Uri.parse('$baseUrl/nutrition/meal-completions/$id/'),
      headers: {"Content-Type": "application/json", "Authorization": basicAuth},
    ).timeout(_kTimeout);
    if (response.statusCode != 204) throw Exception('Failed to undo meal completion');
  }
}
