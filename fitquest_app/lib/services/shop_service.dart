import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ShopService {
  static const String _base = ApiService.baseUrl;

  static String _auth(String u, String p) =>
      'Basic ${base64Encode(utf8.encode('$u:$p'))}';

  static Map<String, String> _headers(String u, String p) => {
        'Content-Type': 'application/json',
        'Authorization': _auth(u, p),
      };

  static List<dynamic> _unwrap(dynamic data) {
    if (data is Map && data.containsKey('results')) return data['results'];
    if (data is List) return data;
    return [];
  }

  // ── Coach ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchMyShopItems(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/shop/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) return _unwrap(jsonDecode(resp.body));
    throw Exception('Failed to load shop items');
  }

  static Future<void> createShopItem(
      String username, String password, Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/create/'),
      headers: _headers(username, password),
      body: jsonEncode(data),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to create item: ${resp.body}');
    }
  }

  static Future<void> deleteShopItem(
      String username, String password, int itemId) async {
    final resp = await http.delete(
      Uri.parse('$_base/shop/$itemId/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }

  static Future<List<dynamic>> fetchPurchases(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/shop/purchases/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) return _unwrap(jsonDecode(resp.body));
    throw Exception('Failed to load purchases');
  }

  static Future<void> fulfillPurchase(
      String username, String password, int purchaseId) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/purchases/$purchaseId/fulfill/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fulfill');
    }
  }

  // ── Recruit ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchAvailableItems(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/shop/available/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) return _unwrap(jsonDecode(resp.body));
    throw Exception('Failed to load shop');
  }

  static Future<Map<String, dynamic>> purchaseItem(
      String username, String password, int itemId) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/purchase/'),
      headers: _headers(username, password),
      body: jsonEncode({'item_id': itemId}),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception(jsonDecode(resp.body)['error'] ?? 'Purchase failed');
  }

  static Future<List<dynamic>> fetchMyPurchases(
      String username, String password) async {
    final resp = await http.get(
      Uri.parse('$_base/shop/my-purchases/'),
      headers: _headers(username, password),
    );
    if (resp.statusCode == 200) return _unwrap(jsonDecode(resp.body));
    throw Exception('Failed to load purchases');
  }
}
