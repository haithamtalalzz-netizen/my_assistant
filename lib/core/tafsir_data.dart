import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// التفسير الميسّر (مجمع الملك فهد لطباعة المصحف الشريف) — ملف ثابت،
/// مفتاح كل آية "سورة:آية". بيتحمّل مرة واحدة ويتخزّن.
class TafsirData {
  TafsirData._();

  static Map<String, String>? _cache;

  static Future<void> _ensure() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString('assets/quran/tafsir_muyassar.json');
    final m = jsonDecode(raw) as Map<String, dynamic>;
    _cache = m.map((k, v) => MapEntry(k, v as String));
  }

  static Future<String> of(int surah, int ayah) async {
    await _ensure();
    return _cache!['$surah:$ayah'] ?? '';
  }
}
