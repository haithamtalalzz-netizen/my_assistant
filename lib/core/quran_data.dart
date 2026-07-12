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

/// عدد صفحات المصحف (مصحف المدينة).
const int kMushafPages = 604;

/// صفحة بداية كل سورة فى مصحف المدينة (بترتيب السور 1..114).
/// المصدر: alquran.cloud (نص Tanzil) — مُتحقَّق (متزايد، 1..604).
const List<int> kSurahStartPage = [
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262, 267,
  282, 293, 305, 312, 322, 332, 342, 350, 359, 367, 377, 385, 396, 404, 411,
  415, 418, 428, 434, 440, 446, 453, 458, 467, 477, 483, 489, 496, 499, 502,
  507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537, 542, 545, 549, 551,
  553, 554, 556, 558, 560, 562, 564, 566, 568, 570, 572, 574, 575, 577, 578,
  580, 582, 583, 585, 586, 587, 587, 589, 590, 591, 591, 592, 593, 594, 595,
  595, 596, 596, 597, 597, 598, 598, 599, 599, 600, 600, 601, 601, 601, 602,
  602, 602, 603, 603, 603, 604, 604, 604,
];

/// صفحة بداية سورة برقمها (1..114).
int surahStartPage(int surahId) =>
    (surahId >= 1 && surahId <= 114) ? kSurahStartPage[surahId - 1] : 1;

/// رابط صورة صفحة المصحف (مصحف المدينة — صور Quran.com، مجانية).
String mushafPageUrl(int page) =>
    'https://android.quran.com/data/width_1024/page'
    '${page.toString().padLeft(3, '0')}.png';
