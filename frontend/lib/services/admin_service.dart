import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class AdminService {
  Future<Map<String, dynamic>?> getAdminStats() async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/admin/stats');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getAllShortNotes() async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/admin/short_notes');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getAllUsers() async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/admin/users');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<bool> updateUserStatus(String userId, bool isBlocked) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/admin/users/$userId/status');
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_blocked': isBlocked}),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> getAllPapers() async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/modelpapers');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }
}
