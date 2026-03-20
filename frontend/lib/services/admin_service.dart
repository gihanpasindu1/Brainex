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
}
