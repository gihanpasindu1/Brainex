import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LangService {
  LangService._();
  static final LangService instance = LangService._();

  Map<String, dynamic> _strings = {};
  String _code = 'en';

  String get code => _code;

  Future<void> load(String code) async {
    _code = code;
    final path = 'assets/lang/$code.json';
    final jsonStr = await rootBundle.loadString(path);
    _strings = jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  String t(String key) {
    final val = _strings[key];
    if (val is String && val.isNotEmpty) return val;
    return key; // fallback: show the key if missing
  }
}
