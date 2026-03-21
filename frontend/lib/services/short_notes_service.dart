import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/short_note_model.dart';
import 'dart:io';

class ShortNotesService {
  // Using localhost IP suitable for Android emulator (10.0.2.2) or real device.
  // Update this to your local IP address if testing on a real device.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  static Future<Map<String, String>> generateNoteWithGemini(String ocrText) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/short_notes/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ocr_text': ocrText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'title': data['title']?.toString() ?? 'Generated Note',
          'desc': data['desc']?.toString() ?? '',
          'content': data['content']?.toString() ?? '',
        };
      } else {
        throw Exception('Failed to generate note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating note: $e');
    }
  }

  static Future<ShortNoteModel> saveShortNote(String userUid, String title, String desc, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/short_notes/$userUid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'desc': desc,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShortNoteModel.fromJson(data);
      } else {
        throw Exception('Failed to save note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving note: $e');
    }
  }

  static Future<List<Map<String, String>>> getPredefinedNotes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/short_notes/predefined/all'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return {
            "title": json["title"]?.toString() ?? "Untitled Note",
            "desc": json["desc"]?.toString() ?? "",
            "date": json["date"]?.toString() ?? "",
            "content": json["content"]?.toString() ?? "",
          };
        }).toList();
      } else {
        throw Exception('Failed to load predefined notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading predefined notes: $e');
    }
  }

  static Future<List<ShortNoteModel>> getShortNotes(String userUid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/short_notes/$userUid'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ShortNoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading notes: $e');
    }
  }
}
