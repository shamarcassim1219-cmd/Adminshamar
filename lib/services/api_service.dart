import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.finbassshamar.online';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> _handle(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final errorMsg = body is Map ? (body['error'] ?? 'Request failed (${res.statusCode})') : 'Request failed (${res.statusCode})';
      throw Exception(errorMsg);
    }
  }

  // ---------- AUTH ----------
  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyLogin(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  // ---------- UPLOAD ----------
  static Future<String> uploadImage(File file) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      final err = jsonDecode(resBody);
      throw Exception(err['error'] ?? 'Upload failed');
    }
    final data = jsonDecode(resBody);
    return data['url'];
  }

  // ---------- ORDERS ----------
  static Future<List<dynamic>> getPendingOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/pending-orders'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
  }

  static Future<Map<String, dynamic>> getOrderVault(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/orders/$orderId/vault'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> updateOrderVault(int orderId, String email, String password, String recoveryCodes) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin-chat/orders/$orderId/vault'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password, 'recoveryCodes': recoveryCodes}),
    );
    await _handle(res);
  }

  static Future<void> shareCredentials(int orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/admin-chat/orders/$orderId/share-credentials'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> releaseEscrow(int orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/admin-chat/orders/$orderId/release-escrow'), headers: await _headers());
    await _handle(res);
  }

  static Future<List<dynamic>> getOrderConversations(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/orders/$orderId/conversations'), headers: await _headers());
    final data = await _handle(res);
    return data['conversations'];
  }

  static Future<List<dynamic>> getConversationMessages(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/conversations/$conversationId/messages'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<void> sendConversationMessage(int conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin-chat/conversations/$conversationId/messages'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- VERIFICATIONS ----------
  static Future<List<dynamic>> getVerifications() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/verifications'), headers: await _headers());
    final data = await _handle(res);
    return data['verifications'];
  }

  static Future<void> decideVerification(int userId, bool approve) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/verifications/$userId/decide'),
      headers: await _headers(),
      body: jsonEncode({'approve': approve}),
    );
    await _handle(res);
  }

  // ---------- TOP-UPS ----------
  static Future<List<dynamic>> getTopups() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/topups'), headers: await _headers());
    final data = await _handle(res);
    return data['topups'];
  }

  static Future<void> decideTopup(int id, bool approve, double? adjustedAmount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/topups/$id/decide'),
      headers: await _headers(),
      body: jsonEncode({'approve': approve, 'adjustedAmount': adjustedAmount}),
    );
    await _handle(res);
  }

  // ---------- WITHDRAWALS ----------
  static Future<List<dynamic>> getWithdrawals() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/withdrawals'), headers: await _headers());
    final data = await _handle(res);
    return data['withdrawals'];
  }

  static Future<void> decideWithdrawal(int id, bool approve) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/withdrawals/$id/decide'),
      headers: await _headers(),
      body: jsonEncode({'approve': approve}),
    );
    await _handle(res);
  }

  // ---------- DISPUTES ----------
  static Future<List<dynamic>> getDisputes() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/disputes'), headers: await _headers());
    final data = await _handle(res);
    return data['disputes'];
  }

  static Future<void> resolveDispute(int id, String resolution) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/disputes/$id/resolve'),
      headers: await _headers(),
      body: jsonEncode({'resolution': resolution}),
    );
    await _handle(res);
  }

  // ---------- USERS ----------
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users'), headers: await _headers());
    final data = await _handle(res);
    return data['users'];
  }

  static Future<void> banUser(int id, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/users/$id/ban'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    await _handle(res);
  }

  static Future<void> unbanUser(int id) async {
    final res = await http.post(Uri.parse('$baseUrl/admin/users/$id/unban'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> adjustWallet(int id, double amount, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/users/$id/adjust-wallet'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'reason': reason}),
    );
    await _handle(res);
  }

  static Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/users/$id'), headers: await _headers());
    await _handle(res);
  }

  // ---------- SUPPORT REQUESTS ----------
  static Future<List<dynamic>> getSupportRequests() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/support-requests'), headers: await _headers());
    final data = await _handle(res);
    return data['requests'];
  }

  static Future<List<dynamic>> getSupportMessages(int requestId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/support-requests/$requestId/messages'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<void> sendSupportReply(int requestId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/support-requests/$requestId/reply'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  static Future<void> closeSupportRequest(int requestId) async {
    final res = await http.post(Uri.parse('$baseUrl/admin/support-requests/$requestId/close'), headers: await _headers());
    await _handle(res);
  }

  // ---------- PROMOTIONS ----------
  static Future<List<dynamic>> getPromotionsAdmin() async {
    final res = await http.get(Uri.parse('$baseUrl/promotions/admin/all'), headers: await _headers());
    final data = await _handle(res);
    return data['promotions'];
  }

  static Future<void> createPromotion(String title, String description, String imageUrl, String? linkUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/promotions'),
      headers: await _headers(),
      body: jsonEncode({'title': title, 'description': description, 'imageUrl': imageUrl, 'linkUrl': linkUrl}),
    );
    await _handle(res);
  }

  static Future<void> togglePromotion(int id) async {
    final res = await http.put(Uri.parse('$baseUrl/promotions/$id/toggle'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> deletePromotion(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/promotions/$id'), headers: await _headers());
    await _handle(res);
  }

  // ---------- SETTINGS ----------
  static Future<double> getCommissionRate() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/settings/commission'), headers: await _headers());
    final data = await _handle(res);
    return (data['commissionRate'] as num).toDouble();
  }

  static Future<void> setCommissionRate(double rate) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/settings/commission'),
      headers: await _headers(),
      body: jsonEncode({'rate': rate}),
    );
    await _handle(res);
  }

  static Future<void> broadcast(String title, String body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/broadcast'),
      headers: await _headers(),
      body: jsonEncode({'title': title, 'body': body}),
    );
    await _handle(res);
  }
}
