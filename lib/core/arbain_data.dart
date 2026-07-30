import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// حديث من الأربعين النووية.
class ArbainHadith {
  final int n;
  final String text;
  const ArbainHadith(this.n, this.text);
}

/// الأربعون النووية للإمام النووى (٤٢ حديثًا) — نصّها من ملف ثابت.
/// المصدر: Sunnah.com (عبر مجموعة AhmedBaset/hadith-json) — نصوص متّفق على
/// اعتمادها. يُحمَّل مرة واحدة ويُخزَّن.
class ArbainData {
  ArbainData._();

  static List<ArbainHadith>? _cache;

  static Future<List<ArbainHadith>> all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/hadith/nawawi40.json');
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((e) => ArbainHadith(
            (e['n'] as num).toInt(), (e['text'] as String?)?.trim() ?? ''))
        .toList();
    return _cache!;
  }
}
