import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// آية واحدة.
class QuranAyah {
  final int id;
  final String text;
  const QuranAyah(this.id, this.text);
}

/// سورة كاملة.
class QuranSurah {
  final int id;
  final String name;
  final String tr; // النطق اللاتينى (للعرض الاختيارى)
  final String type; // meccan / medinan
  final List<QuranAyah> verses;
  const QuranSurah(this.id, this.name, this.tr, this.type, this.verses);

  bool get isMeccan => type == 'meccan';
}

/// محمّل نص المصحف من ملف ثابت متحقَّق منه (مصدر Tanzil — مصحف المدينة).
/// النص بيتحمّل مرة واحدة ويتخزّن فى الذاكرة.
class QuranData {
  QuranData._();

  static List<QuranSurah>? _cache;

  static Future<List<QuranSurah>> surahs() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final list = jsonDecode(raw) as List;
    _cache = list.map((s) {
      final m = s as Map<String, dynamic>;
      final verses = (m['verses'] as List)
          .map((v) => QuranAyah(v['id'] as int, v['text'] as String))
          .toList();
      return QuranSurah(m['id'] as int, m['name'] as String,
          m['tr'] as String? ?? '', m['type'] as String? ?? '', verses);
    }).toList();
    return _cache!;
  }

  static Future<QuranSurah> surah(int id) async {
    final all = await surahs();
    return all.firstWhere((s) => s.id == id);
  }
}
