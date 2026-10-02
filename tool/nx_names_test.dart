// أسماء مقترحة للتطبيق — معروضة زى ما هتبان **تحت الأيقونة** على
// الشاشة الرئيسية للموبايل، وفى شريط التطبيق.
//
// ليه بالصورة: الاسم بيتقرا فى مكانين بس — تحت الأيقونة (مساحة ضيّقة
// جداً) وفى الشريط العلوى. اسم حلو على الورق ممكن يتقصّ تحت الأيقونة.
//
//   flutter test tool/nx_names_test.dart → build/design_shots/nx_9_names.png
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

/// (الاسم، المعنى/السبب)
const _names = <(String, String)>[
  ('يومى', 'خط اليوم هو عمود التطبيق'),
  ('حاجاتى', 'كل حاجتك فى مكان واحد'),
  ('معايا', 'معاك طول اليوم'),
  ('دفترى', 'دفتر حياتك'),
  ('مساعدى', 'الاسم الحالى على الويب'),
  ('حياتى', 'بيغطّى حياتك كلها'),
  ('سندى', 'اللى بيسندك'),
  ('كله عندى', 'مفيش حاجة برّه'),
];

/// أيقونة التطبيق كما هى على الشاشة الرئيسية.
Widget _icon() => Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF12B981), Color(0xFF34D399)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(17),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome_mosaic,
          color: Colors.white, size: 30),
    );

/// بلاطة زى اللى على شاشة الموبايل: أيقونة + الاسم تحتها.
///
/// الخلفية غامقة لإن ده الوضع الطبيعى لشاشة الموبايل، والاسم بيتقرا
/// عليها مش على ورق أبيض.
Widget _tile(String name) => SizedBox(
      width: 108,
      child: Column(children: [
        _icon(),
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

/// نفس الاسم فى شريط التطبيق.
Widget _bar(String name, String why) => Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
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
            rdT(name, k, size: 18, w: FontWeight.w800, maxLines: 1),
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
  testWidgets('أسماء التطبيق', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_9_names',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // 🔴 من غير `theme` فيه fontFamily، الـ`TextStyle` اللى مش
        // محدّدة خط بتاخد الافتراضى — **ومافيهوش عربى**، فكل الكلام
        // يطلع مربّعات. (البلاطات على اليمين كانت سليمة لإنها بتحدّد
        // 'Cairo' بإيدها، والعمود التانى لأ.)
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
                // العمود الأول: تحت الأيقونة على شاشة الموبايل.
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
                // العمود التانى: فى شريط التطبيق + السبب.
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rdT('فى شريط التطبيق', k,
                            size: 14, w: FontWeight.w800),
                        const SizedBox(height: 12),
                        for (final n in _names) _bar(n.$1, n.$2),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
      size: const Size(1060, 760),
      pixelRatio: 2,
    );
  });
}
