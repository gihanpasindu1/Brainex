import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'backend_config.dart';

class UserProfileService {
  Future<void> syncDailyLoginXp(String userId) async {
    if (userId.isEmpty) return;

    final uri = Uri.parse('${BackendConfig.baseUrl}/users/$userId/login');
    try {
      await http.post(uri);
    } catch (_) {
      // Login should still succeed even if the XP sync fails.
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (userId.isEmpty) return null;
    final uri = Uri.parse('${BackendConfig.baseUrl}/users/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> completeOnboarding(String userId, Map<String, dynamic> data) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/users/$userId/onboarding');
    try {
      debugPrint('Calling API to save profile: $uri');
      debugPrint('Payload: $data');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP Exception Caught: $e');
      return false;
    }
  }

  Future<bool> updateProfile(String userId, String? name, String? base64Image) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/users/$userId/profile');
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (base64Image != null) data['profile_picture_base64'] = base64Image;

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP Exception Caught on Update: $e');
      return false;
    }
  }
}
