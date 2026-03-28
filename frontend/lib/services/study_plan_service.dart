import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_config.dart';

class StudyPlanService {
  Future<Map<String, dynamic>?> generateStudyPlan(Map<String, dynamic> request) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/planner/generate-and-save');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error generating plan: ${response.body}');
      }
    } catch (e) {
      print('HTTP error generating plan: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getUserPlans(String userId) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/planner/user/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
