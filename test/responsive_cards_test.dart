// كروت وأزرار على كل المقاسات — **مفيش حاجة بتتشرح**.
//
// ليه ملف لوحده بدل الاعتماد على `tool/sizes_test`: الأداة دى بترسم
// الشاشات ببيانات **مزروعة**، والزرع قصير — فسطر بيلفّ لسطرين عمره ما
// بيتولد فيها. العطب الحقيقى (نُص سطر متقطع فى كروت الرئيسية) اتشاف فى
// صورة موبايل ببيانات حقيقية والأداة خضرا.
//
// هنا بنغذّى النصوص **بأطوال واقعية** وبنقيس: الارتفاع اللى النصّ
// محتاجه جوّه عرضه الفعلى مقابل صندوقه. أكبر = الكلام بيتقطع نُصّين.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/dashboard_stats.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/widgets/dash_card.dart';

/// مقاسات حقيقية: من أصغر موبايل بيتباع لحد تابلت كبير.
const _widths = <String, double>{
  'موبايل صغير 320': 320,
  'موبايل عادى 360': 360,
  'موبايل 390': 390,
  'موبايل كبير 412': 412,
  'فولد مفتوح 673': 673,
  'تابلت 800': 800,
  'تابلت كبير 1024': 1024,
};

/// نصوص بالطول اللى بيحصل فعلاً فى التطبيق — مش «أكل» و«٣».
const _subs = [
  'مصروف الشهر · 0 حركة',
  'مفيش مستحق · 3 فاتت',
  'مل مياه · آخر وزن 84 كجم',
  'سلسلة 4',
  'شهادات البنك الأهلى · كاش · ذهب · فضة',
];

/// بيرجّع كل نصّ صندوقه أقصر من اللى محتاجه (يعنى بيتقطع نُصّين).
List<String> slicedTexts(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1 || ro.size.height < 1) continue;
    final txt = ro.text.toPlainText().trim();
    if (txt.isEmpty) continue;
    // الأيقونة بترسم كنصّ بحرف من منطقة الاستعمال الخاص — مش كلام.
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    final tp = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: ro.maxLines,
      textScaler: ro.textScaler,
    )..layout(maxWidth: ro.size.width);
    if (tp.height <= ro.size.height + 1) continue;
    out.add('«$txt» صندوق ${ro.size.height.round()} / محتاج '
        '${tp.height.round()}');
  }
  return out.toList();
}

void main() {
  testWidgets('كارت الرئيسية مابيتشرحش على أى مقاس', (tester) async {
    final bad = <String>[];

    for (final e in _widths.entries) {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = Size(e.value, 900) * 2;
      // نفس شبكة الرئيسية: ٣ أعمدة · مسافة ٨ · هامش ١٦ من كل ناحية.
      final cardW = (e.value - 32 - 16) / 3;

      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(children: [
              for (final s in _subs)
                SizedBox(
                  width: cardW,
                  height: 124,
                  child: DashCardTile(
                      stat: DashStat(
                          key: 'money',
                          title: 'الفلوس',
                          value: '1,945,435',
                          sub: s)),
                ),
            ]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      for (final m in slicedTexts(tester)) {
        bad.add('[${e.key}] $m');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    expect(bad, isEmpty, reason: 'نصّ بيتقطع نُصّين:\n${bad.join("\n")}');
  });
}
