// أسماء لاتينية قصيرة (إنجليزى/إسبانى) — زى ما هتبان تحت الأيقونة
// وفى شريط التطبيق العربى.
//
// ليه بالصورة: اسم لاتينى جوّه واجهة عربية بيتقرا مختلف عن الورق —
// لازم تشوفه جنب «☰» و«🔍» والعربى اللى تحته.
//
//   flutter test tool/nx_names_latin_test.dart
//   → build/design_shots/nx_10_names_latin.png
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

/// (الاسم، النطق بالعربى، اللغة، المعنى/السبب)
const _names = <(String, String, String, String)>[
  ('Mío', 'ميو', 'إسبانى', '«بتاعى» — زى فلوسى وصحتى ومهامى'),
  ('Vida', 'فيدا', 'إسبانى', '«حياة» — بيغطّى حياتك كلها'),
  ('Dia', 'ديا', 'إسبانى', '«يوم» — خط اليوم عمود التطبيق'),
  ('Nido', 'نيدو', 'إسبانى', '«عُش» — حاجاتك كلها متلمّة'),
  ('Tally', 'تالى', 'إنجليزى', 'العدّ — فلوس وعادات وأهداف'),
  ('Daily', 'ديلى', 'إنجليزى', 'يومى'),
  ('Pace', 'بيس', 'إنجليزى', 'إيقاعك — مش سباق'),
  ('Orbit', 'أوربت', 'إنجليزى', 'كل حاجة بتدور حواليك'),
];

Widget _icon(double s) => Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF12B981), Color(0xFF34D399)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(s * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.auto_awesome_mosaic, color: Colors.white, size: s * .48),
    );

/// بلاطة على الشاشة الرئيسية للموبايل.
Widget _tile(String name) => SizedBox(
      width: 108,
      child: Column(children: [
        _icon(62),
        const SizedBox(height: 7),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    );

/// الاسم فى شريط التطبيق العربى.
///
/// 🔴 الاسم اللاتينى معزول بـ`ltr()`: كلمة لاتينية جوّه فقرة عربية
/// بيتقلب ترتيبها لو جنبها رقم أو علامة — نفس اللى حصل مع «O+»
/// ورقم التليفون.
Widget _bar(String name, String say, String lang, String why) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: k.line),
      ),
      child: Row(children: [
        Icon(Icons.menu, size: 19, color: k.mute),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: k.ink)),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: k.tint(k.accent),
                    borderRadius: BorderRadius.circular(99)),
                child: rdT('تتقال $say', k,
                    size: 9.5, w: FontWeight.w800, color: k.accent),
              ),
              const SizedBox(width: 6),
              rdT(lang, k, size: 9.5, color: k.mute),
            ]),
            const SizedBox(height: 2),
            rdT(why, k, size: 10.5, color: k.mute, maxLines: 1),
          ]),
        ),
        Icon(Icons.search, size: 18, color: k.mute),
        const SizedBox(width: 10),
        Icon(Icons.visibility_outlined, size: 18, color: k.mute),
      ]),
    );

void main() {
  testWidgets('أسماء لاتينية', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_10_names_latin',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // من غير `theme` فيه fontFamily، العربى بيطلع مربّعات.
        theme: rdTheme(k),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: const Color(0xFFEEF1F6),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 420,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(children: [
                    const Text('تحت الأيقونة على الموبايل',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [for (final n in _names) _tile(n.$1)],
                    ),
                  ]),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rdT('فى شريط التطبيق العربى', k,
                            size: 14, w: FontWeight.w800),
                        const SizedBox(height: 12),
                        for (final n in _names) _bar(n.$1, n.$2, n.$3, n.$4),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
      size: const Size(1120, 790),
      pixelRatio: 2,
    );
  });
}
