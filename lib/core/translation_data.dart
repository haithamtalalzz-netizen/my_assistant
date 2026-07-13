import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// ترجمة معانى القرآن (Saheeh International) — ملف ثابت، مفتاح "سورة:آية".
class TranslationData {
  TranslationData._();

  static Map<String, String>? _cache;

  static Future<void> _ensure() async {
    if (_cache != null) return;
    final raw =
        await rootBundle.loadString('assets/quran/translation_en.json');
    final m = jsonDecode(raw) as Map<String, dynamic>;
    _cache = m.map((k, v) => MapEntry(k, v as String));
  }

  static Future<String> of(int surah, int ayah) async {
    await _ensure();
    return _cache!['$surah:$ayah'] ?? '';
  }
}
