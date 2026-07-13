import 'dart:convert';

import 'package:flutter/services.dart' show FontLoader;
import 'package:http/http.dart' as http;

/// كلمة فى صفحة المصحف بخط QCF: [code] = رمز الحرف فى خط الصفحة.
class QcfWord {
  final String code;
  final int surah;
  final int ayah;
  final bool isEnd; // علامة نهاية الآية
  const QcfWord(this.code, this.surah, this.ayah, this.isEnd);
}

/// محرّك خط QCF (تجريبى): نص المصحف كخط بيطابق شكل صفحة مصحف المدينة —
/// بيسمح بتعليم الآية بالضبط. البيانات من quran.com (كلمات) + خطوط الصفحات (GitHub).
class Qcf {
  Qcf._();

  static final Map<int, List<List<QcfWord>>> _pageCache = {};
  static final Set<int> _fontsLoaded = {};

  static String fontFamily(int page) => 'QCF_P$page';

  /// أسطر الصفحة (كل سطر قائمة كلمات) — تُجلب مرة وتُخزّن.
  static Future<List<List<QcfWord>>> pageLines(int page) async {
    if (_pageCache[page] != null) return _pageCache[page]!;
    final url = 'https://api.quran.com/api/v4/verses/by_page/$page'
        '?words=true&word_fields=code_v1,line_number&per_page=50';
    final res = await http.get(Uri.parse(url),
        headers: {'User-Agent': 'my_assistant/1.0'});
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    final byLine = <int, List<QcfWord>>{};
    for (final v in (d['verses'] as List)) {
      final key = (v['verse_key'] as String).split(':');
      final s = int.parse(key[0]), a = int.parse(key[1]);
      for (final w in (v['words'] as List)) {
        final line = w['line_number'] as int? ?? 1;
        final code = w['code_v1'] as String? ?? '';
        final isEnd = w['char_type_name'] == 'end';
        byLine.putIfAbsent(line, () => []).add(QcfWord(code, s, a, isEnd));
      }
    }
    final lines = <List<QcfWord>>[];
    for (final l in byLine.keys.toList()..sort()) {
      lines.add(byLine[l]!);
    }
    _pageCache[page] = lines;
    return lines;
  }

  /// يحمّل خط الصفحة (مرة واحدة).
  static Future<void> ensureFont(int page) async {
    if (_fontsLoaded.contains(page)) return;
    final url = 'https://raw.githubusercontent.com/quran/'
        'quran.com-frontend-next/master/public/fonts/quran/hafs/v1/ttf/p$page.ttf';
    final res = await http.get(Uri.parse(url));
    final bytes = res.bodyBytes;
    final loader = FontLoader(fontFamily(page))
      ..addFont(Future.value(bytes.buffer.asByteData()));
    await loader.load();
    _fontsLoaded.add(page);
  }

  /// يجهّز الصفحة (الخط + الكلمات) معًا.
  static Future<List<List<QcfWord>>> preparePage(int page) async {
    await ensureFont(page);
    return pageLines(page);
  }
}
