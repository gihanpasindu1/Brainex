import 'dart:convert';
import 'package:frontend/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  // Use 127.0.0.1 for iOS simulator or Web.
  // Only for development. In production, use your server IP.
  final String baseUrl = 'http://10.0.2.2:8000';

  String? _sessionId;

  Future<String> getSessionId() async {
    if (_sessionId != null) return _sessionId!;

    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('chat_session_id');

    if (_sessionId == null) {
      _sessionId = const Uuid().v4();
      await prefs.setString('chat_session_id', _sessionId!);
    }
    return _sessionId!;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_session_id');
    _sessionId = null;
    // Optionally call backend to clear session there too
    // try {
    //   await http.post(Uri.parse('$baseUrl/chat/clear'), ...);
    // } catch (_) {}
  }

  Future<ChatMessage> sendMessage(String text) async {
    final sessionId = await getSessionId();
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? "No answer received.";
        return ChatMessage(text: answer, role: "assistant");
      } else {
        return ChatMessage(
          text: "Error: Server returned ${response.statusCode}",
          role: "assistant",
        );
      }
    } catch (e) {
      return ChatMessage(
        text: "Error connecting to server. Please check your connection.",
        role: "assistant",
      );
    }
  }
}
