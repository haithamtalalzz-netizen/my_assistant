import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// حديث داخل كتاب.
class BookHadith {
  final int n; // رقمه فى الكتاب
  final int chapterId;
  final String text;
  const BookHadith(this.n, this.chapterId, this.text);
}

/// باب/كتاب داخل المجموعة.
class BookChapter {
  final int id;
  final String name;
  const BookChapter(this.id, this.name);
}

/// كتاب حديث كامل (عنوان + مؤلّف + أبواب + أحاديث).
class HadithBook {
  final String title;
  final String author;
  final List<BookChapter> chapters;
  final List<BookHadith> hadiths;
  const HadithBook(this.title, this.author, this.chapters, this.hadiths);

  List<BookHadith> inChapter(int chapterId) =>
      hadiths.where((h) => h.chapterId == chapterId).toList();

  /// بحث نصّى بسيط (يتجاهل التشكيل عشان البحث بالعربى العادى يشتغل).
  List<BookHadith> search(String q) {
    final needle = _strip(q);
    if (needle.isEmpty) return const [];
    return hadiths.where((h) => _strip(h.text).contains(needle)).toList();
  }
}

/// يشيل التشكيل والتطويل ويوحّد الألف/الياء/التاء المربوطة — عشان البحث
/// بنص غير مشكّل يلاقى نصًّا مشكّلًا.
String _strip(String s) => s
    .replaceAll(RegExp(r'[ً-ْٰـ]'), '')
    .replaceAll(RegExp('[إأآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .trim();

/// كتب الحديث المدمجة — النصوص من **Sunnah.com** (عبر مجموعة
/// AhmedBaset/hadith-json). تُحمَّل عند الطلب وتُخزَّن.
class HadithBooks {
  HadithBooks._();

  /// المفاتيح المتاحة → (اسم الملف، عنوان معروض).
  static const Map<String, String> assets = {
    'riyad': 'assets/hadith/riyad.json',
    'nawawi40': 'assets/hadith/nawawi40.json',
    'qudsi40': 'assets/hadith/qudsi40.json',
    'shamail': 'assets/hadith/shamail.json',
  };

  static final Map<String, HadithBook> _cache = {};

  static Future<HadithBook> load(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final path = assets[key];
    if (path == null) throw ArgumentError('كتاب غير معروف: $key');
    final raw = await rootBundle.loadString(path);
    final m = jsonDecode(raw);

    // nawawi40 اتخزّن بشكل مبسّط (قائمة {n,text}) قبل ما نعمّم الشكل ده.
    if (m is List) {
      final hs = [
        for (final e in m)
          BookHadith((e['n'] as num).toInt(), 0,
              (e['text'] as String?)?.trim() ?? ''),
      ];
      final b = HadithBook('الأربعون النووية', 'الإمام النووى',
          const [BookChapter(0, 'الأربعون النووية')], hs);
      _cache[key] = b;
      return b;
    }

    final map = m as Map<String, dynamic>;
    final b = HadithBook(
      map['title'] as String? ?? '',
      map['author'] as String? ?? '',
      [
        for (final c in (map['chapters'] as List? ?? const []))
          BookChapter((c['id'] as num).toInt(), (c['name'] as String?) ?? ''),
      ],
      [
        for (final h in (map['hadiths'] as List? ?? const []))
          BookHadith((h['n'] as num).toInt(), (h['c'] as num?)?.toInt() ?? 0,
              (h['t'] as String?)?.trim() ?? ''),
      ],
    );
    _cache[key] = b;
    return b;
  }
}
