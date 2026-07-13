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

  // ---- خريطة الصفحات (صفحة → آياتها) ----
  static Map<int, List<List<int>>>? _pages;

  static Future<Map<int, List<List<int>>>> _loadPages() async {
    if (_pages != null) return _pages!;
    final raw = await rootBundle.loadString('assets/quran/page_ayahs.json');
    final m = jsonDecode(raw) as Map<String, dynamic>;
    _pages = m.map((k, v) => MapEntry(
        int.parse(k),
        (v as List)
            .map((e) => [(e as List)[0] as int, e[1] as int])
            .toList()));
    return _pages!;
  }

  /// آيات صفحة معيّنة كأزواج [رقم السورة، رقم الآية].
  static Future<List<List<int>>> pageAyahs(int page) async {
    final p = await _loadPages();
    return p[page] ?? const [];
  }

  /// أرقام السور التى تبدأ (آية 1) فى هذه الصفحة.
  static Future<List<int>> surahsStartingOn(int page) async {
    final ayahs = await pageAyahs(page);
    return ayahs.where((a) => a[1] == 1).map((a) => a[0]).toList();
  }

  /// صفحة آية معيّنة (بناء عكسى من خريطة الصفحات).
  static Map<String, int>? _ayahPage;
  static Future<int> pageOfAyah(int surah, int ayah) async {
    if (_ayahPage == null) {
      final pages = await _loadPages();
      _ayahPage = {};
      pages.forEach((p, refs) {
        for (final r in refs) {
          _ayahPage!['${r[0]}:${r[1]}'] = p;
        }
      });
    }
    return _ayahPage!['$surah:$ayah'] ?? 1;
  }
}

/// صفحة بداية كل جزء (1..30).
const List<int> kJuzStartPage = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302,
  322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

/// رقم الجزء الذى تقع فيه صفحة معيّنة (1..30).
int pageJuz(int page) {
  var j = 1;
  for (var i = 0; i < kJuzStartPage.length; i++) {
    if (page >= kJuzStartPage[i]) j = i + 1;
  }
  return j;
}

/// جزء بداية كل سورة (1..114).
// ignore: lines_longer_than_80_chars
const List<int> kSurahStartJuz = [1,1,3,4,6,7,8,9,10,11,11,12,13,13,14,14,15,15,16,16,17,17,18,18,18,19,19,20,20,21,21,21,21,22,22,22,23,23,23,24,24,25,25,25,25,26,26,26,26,26,26,27,27,27,27,27,27,28,28,28,28,28,28,28,28,28,29,29,29,29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30];

/// ترتيب نزول كل سورة (1..114).
// ignore: lines_longer_than_80_chars
const List<int> kSurahRevOrder = [5,87,89,92,112,55,39,88,113,51,52,53,96,72,54,70,50,69,44,45,73,103,74,102,42,47,48,49,85,84,57,75,90,58,43,41,56,38,59,60,61,62,63,64,65,66,95,111,106,34,67,76,23,37,97,46,94,105,101,91,109,110,104,108,99,107,77,2,78,79,71,40,3,4,31,98,33,80,81,24,7,82,86,83,27,36,8,68,10,35,26,9,11,12,28,1,25,100,93,14,30,16,13,32,19,29,17,15,18,114,6,22,20,21];

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
