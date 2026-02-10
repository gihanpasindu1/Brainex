import 'package:frontend/models/chat_message.dart';

class ChatService {
  // Mock function to simulate sending a message to a backend
  Future<ChatMessage> sendMessage(String text) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple mock logic for responses
    String responseText;
    final lowerText = text.toLowerCase();

    if (lowerText.contains('hello') || lowerText.contains('hi')) {
      responseText = 'Hello! How can I help you today?';
    } else if (lowerText.contains('help')) {
      responseText =
          'I can assist you with navigating the app or answering common questions.';
    } else if (lowerText.contains('time')) {
      responseText = 'The current time is ${DateTime.now().toLocal()}';
    } else {
      responseText = 'I am a simple bot. I did not understand "$text".';
    }

    return ChatMessage(text: responseText, role: "assistant");
  }
}
