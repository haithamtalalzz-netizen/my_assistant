// «فلوسى» من الصفر — ٤ أفكار مختلفة فى **نموذج التفكير** نفسه، مش فى
// ترتيب الشاشة. الهدف: أسهل للمبتدئ وشاشات أقل.
//
// البند الحالى فيه ٦ شاشات فى السايدبار (الشهر · الادخار · الديون ·
// الجمعيات · الاشتراكات · الأمنيات) + محافظ + سجل + تحليل — وده أكتر
// حاجة بتتعب اللى لسه بادئ.
//
//   flutter test tool/money_ideas_test.dart
//   → build/design_shots/money_idea_*.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

/// نفس الشكل الودّى بس باللون الأزرق — لون هويّة التطبيق عنده دلوقتى.
const k = RdLook(
  name: 'فلوسى',
  note: '',
  bg: Color(0xFFF6F8FC),
  surface: Colors.white,
  ink: Color(0xFF0F172A),
  mute: Color(0xFF6E7A8C),
  line: Color(0xFFE6EBF3),
  accent: Color(0xFF2E86F5),
  accent2: Color(0xFF5BA4F8),
  onAccent: Colors.white,
  radius: 22,
  tinted: true,
  dark: false,
);

const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFF59E0B);
const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);
const _pink = Color(0xFFEC4899);

Widget _head(String s, {String? trail}) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
      child: Row(children: [
        Expanded(child: rdT(s, k, size: 13, color: k.mute, w: FontWeight.w800)),
        if (trail != null)
          rdT(trail, k, size: 11.5, color: k.mute, w: FontWeight.w700),
      ]),
    );

Widget _move(IconData i, String title, String sub, String amount, Color c,
        {bool last = false}) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(c), borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 19, color: c),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(title, k, size: 13.5, w: FontWeight.w700, maxLines: 1),
              const SizedBox(height: 2),
              rdT(sub, k, size: 11, color: k.mute, maxLines: 1),
            ]),
          ),
          rdT(ltr(amount), k, size: 14, color: c, w: FontWeight.w900),
        ]),
      ),
      if (!last) Divider(color: k.line, height: 1),
    ]);

// ═════════════════ ١ · دفتر واحد ═════════════════

Widget idea1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 8),
      rdPad(Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
            color: k.tint(k.accent),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: k.accent.withValues(alpha: 0.25))),
        child: Column(children: [
          rdT('فاضل معاك', k, size: 12.5, color: k.mute, w: FontWeight.w700),
          const SizedBox(height: 3),
          Text('4,250',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 42,
                  color: k.accent,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          rdT('جنيه · لغاية آخر الشهر', k, size: 11.5, color: k.mute),
        ]),
      )),
      rdPad(rdChips(k, ['الكل', 'صرفت', 'قبضت'])),
      rdPad(Column(children: [
        _head('النهارده'),
        _move(Icons.remove, 'سوبر ماركت', 'كاش', '− 320', _red),
        _move(Icons.remove, 'بنزين', 'كاش', '− 250', _red, last: true),
        _head('امبارح'),
        _move(Icons.add, 'المرتب', 'تحويل بنكى', '+ 11,000', _green),
        _move(Icons.remove, 'فاتورة الكهربا', 'فودافون كاش', '− 420', _red),
        _move(Icons.remove, 'دوا', 'كاش', '− 180', _red, last: true),
        _head('الأحد 27'),
        _move(Icons.remove, 'مواصلات', 'كاش', '− 60', _red, last: true),
      ])),
    ]);

// ═════════════════ ٢ · مظاريف ═════════════════

Widget _env(IconData i, String name, String left, String of, double v, Color c) =>
    Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
          color: k.tint(c),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.withValues(alpha: 0.25))),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 19, color: c),
          ),
          const SizedBox(width: 11),
          Expanded(child: rdT(name, k, size: 14, w: FontWeight.w800)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(left,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    color: c,
                    fontWeight: FontWeight.w900)),
            rdT('فاضل من $of', k, size: 10.5, color: k.mute),
          ]),
        ]),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(c)),
        ),
      ]),
    );

Widget idea2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 4),
      rdPad(Row(children: [
        Icon(Icons.chevron_right, color: k.mute, size: 22),
        Expanded(
            child: rdT('سبتمبر · فاضل 12 يوم', k,
                size: 13, w: FontWeight.w800, align: TextAlign.center)),
        Icon(Icons.chevron_left, color: k.mute, size: 22),
      ])),
      const SizedBox(height: 12),
      rdPad(Column(children: [
        _env(Icons.shopping_cart, 'أكل وشرب', '900', '4,000', 0.22, _amber),
        _env(Icons.directions_car, 'مواصلات', '1,550', '3,000', 0.52, k.accent),
        _env(Icons.home, 'البيت والفواتير', '300', '3,000', 0.10, _violet),
        _env(Icons.self_improvement, 'نفسى', '650', '1,000', 0.65, _pink),
        _env(Icons.savings, 'ادخار', '2,000', '2,000', 1.0, _green),
      ])),
      rdPad(Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: k.line)),
        child: Row(children: [
          Icon(Icons.add_circle_outline, color: k.accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: rdT('ضيف مظروف جديد', k,
                  size: 13, color: k.mute, w: FontWeight.w700)),
        ]),
      )),
    ]);

// ═════════════════ ٣ · سؤال وجواب ═════════════════

Widget _qCard(String q, String a, String sub, Color c, IconData i,
        {bool open = false, List<Widget> body = const []}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
          color: open ? k.tint(c) : k.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: open ? c.withValues(alpha: 0.28) : k.line)),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: open ? Colors.white : k.tint(c),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 19, color: c),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(q, k, size: 13.5, w: FontWeight.w800, maxLines: 1),
              const SizedBox(height: 2),
              rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
            ]),
          ),
          rdT(a, k, size: 16, color: c, w: FontWeight.w900),
          const SizedBox(width: 6),
          Icon(open ? Icons.expand_less : Icons.expand_more,
              size: 20, color: k.mute),
        ]),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(color: c.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 4),
          ...body,
        ],
      ]),
    );

Widget idea3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 10),
      rdPad(Column(children: [
        _qCard('فاضل معايا كام؟', '4,250', 'لغاية آخر الشهر', k.accent,
            Icons.account_balance_wallet),
        _qCard('راحت فين؟', '8,150', 'الشهر ده', _red, Icons.pie_chart,
            open: true,
            body: [
              _move(Icons.shopping_cart, 'أكل وشرب', 'من 4,000', '3,100',
                  _amber),
              _move(Icons.directions_car, 'مواصلات', 'من 3,000', '1,450',
                  k.accent),
              _move(Icons.medical_services, 'صحة', 'من 1,000', '900', _pink,
                  last: true),
            ]),
        _qCard('عليّا إيه؟', '720', '2 فواتير', _amber, Icons.receipt_long),
        _qCard('هيجيلى كام؟', '11,000', 'يوم 1 فى الشهر', _green,
            Icons.payments),
        _qCard('بوفّر كام؟', '2,000', 'الشهر ده', _teal, Icons.savings),
      ])),
    ]);

// ═════════════════ ٤ · مصروف اليوم ═════════════════

Widget idea4() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 14),
      rdPad(Column(children: [
        rdT('تقدر تصرف النهارده', k, size: 13, color: k.mute, w: FontWeight.w700),
        const SizedBox(height: 4),
        Text('354',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 62,
                color: k.accent,
                fontWeight: FontWeight.w900,
                height: 1.05)),
        rdT('جنيه', k, size: 14, color: k.mute),
        const SizedBox(height: 14),
        rdPad(rdBar(k, 0.38, 'صرفت النهارده 135 من 354')),
      ])),
      const SizedBox(height: 18),
      rdPad(Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: k.tint(_green),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _green.withValues(alpha: 0.28))),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, color: _green, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: rdT('ماشى كويس — فاضل 219 لباقى اليوم', k,
                  size: 12.5, w: FontWeight.w800, maxLines: 1)),
        ]),
      )),
      rdPad(Column(children: [
        _head('صرفت النهارده', trail: '135'),
        _move(Icons.local_cafe, 'قهوة', '', '− 45', _red),
        _move(Icons.directions_bus, 'مواصلات', '', '− 30', _red),
        _move(Icons.shopping_basket, 'عيش وجبنة', '', '− 60', _red, last: true),
        _head('اللى ثابت كل شهر'),
        _move(Icons.payments, 'دخلك', 'يوم 1', '11,000', _green),
        _move(Icons.receipt_long, 'فواتير ثابتة', 'كهربا · نت · مدرسة', '2,100',
            _amber),
        _move(Icons.savings, 'بتدخّر', 'أول الشهر', '2,000', _teal, last: true),
      ])),
    ]);

// ═════════════════ الرسم ═════════════════

void main() {
  testWidgets('money ideas', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'money_ideas',
      shotApp(
        rdTheme(k),
        rdTriptych([
          ('دفتر واحد', 'شاشة واحدة · كل حركة ورا التانية', idea1()),
          ('مظاريف', 'فلوسك مقسومة · تشوف الفاضل فى كل مظروف', idea2()),
          ('سؤال وجواب', 'كل كارت سؤال · يفتح مكانه من غير تنقّل', idea3()),
          ('مصروف اليوم', 'رقم واحد: تقدر تصرف النهارده كام', idea4()),
        ]),
      ),
      size: const Size(1530, 890),
      pixelRatio: 2,
    );
  });
}
