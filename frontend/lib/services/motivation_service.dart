import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class MotivationService {
  // Try using 127.0.0.1 for Windows/Web, 10.0.2.2 for Android Emulator
  final String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> fetchMotivation({int? lastQuoteId}) async {
    try {
      String urlStr = '$baseUrl/motivation';
      if (lastQuoteId != null) {
        urlStr += '?last_quote_id=$lastQuoteId';
      }
      final url = Uri.parse(urlStr);
      final response = await http.get(url).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching motivation: $e');
      // Fallback in case the backend is unreachable or times out
    }
    return {
      "id": 0,
      "quote": "Focused Learner" // Fallback quote
    };
  }
}
