// إعادة ترتيب «المتابعة والأدوات» — ٣ أشكال.
//
// اللى الأشكال بتحلّه (اتقاس من الكود):
//  · «التقارير» بند جوّه الهَب وجوّاه «إحصائياتك» و«رؤى المدير» — وهُمّ
//    بنود مستقلة فى **نفس** الهَب. طبقة كاملة زيادة.
//  · «مركز التنبيهات» له مدخلان: البند + الجرس اللى فى الرئيسية.
//  · «تقويم النتيجة» و«آلة الزمن» بيعملوا نفس الحاجة: «شوف يوم فات».
//
//   flutter test tool/nx_tools_test.dart → build/design_shots/nx_13_tools.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _violet = Color(0xFF8B5CF6);
const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _cyan = Color(0xFF06B6D4);
const _rose = Color(0xFFF43F5E);
const _teal = Color(0xFF14B8A6);

/// سطر بند: أيقونة · اسم · وصف · رقمه.
Widget _row(IconData icon, Color c, String title, String sub,
        {String? big, String? bigSub}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: k.line),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(c), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 17, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(title, k, size: 12.5, w: FontWeight.w800, maxLines: 1),
              const SizedBox(height: 1),
              rdT(sub, k, size: 9.5, color: k.mute, maxLines: 1),
            ]),
          ),
          if (big != null) ...[
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              rdT(big, k, size: 14, w: FontWeight.w900, color: c),
              if (bigSub != null) rdT(bigSub, k, size: 8.5, color: k.mute),
            ]),
          ],
          Icon(Icons.chevron_left, size: 17, color: k.mute),
        ]),
      ),
    );

// ═══════════ ١ · مقسوم لمجموعات ═══════════

/// تلات مجموعات بعناوين: شوف نفسك · ارجع لورا · أدواتك.
///
/// «التقارير» اتلغت كبند والتلات PDF نزلوا صفّ لوحدهم، و«آلة الزمن»
/// اتدمجت جوّه التقويم (الاتنين «شوف يوم فات»).
Widget tools1() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'المتابعة والأدوات', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'شوف نفسك'),
        _row(Icons.lightbulb_outline, _amber, 'رؤى المدير',
            'أنماط من بياناتك', big: '4', bigSub: 'رؤية'),
        _row(Icons.bar_chart, _blue, 'إحصائياتك',
            'نوم · خطوات · مياه · وزن · مصاريف'),
        _row(Icons.emoji_events_outlined, _violet, 'المراجعة السنوية',
            'ملخّص سنتك من كل البنود'),
        _row(Icons.picture_as_pdf_outlined, _rose, 'تقارير PDF',
            'مخصّص · الشهر · الدكتور', big: '3', bigSub: 'تقرير'),
        rdSection(k, 'ارجع لورا'),
        _row(Icons.calendar_month_outlined, _teal, 'تقويم النتيجة',
            'شهرك ملوّن · دوس على يوم تشوفه كله'),
        rdSection(k, 'أدواتك'),
        _row(Icons.calculate_outlined, _green, 'حاسبات',
            'زكاة · كتلة جسم · قسط · وحدات', big: '8'),
        _row(Icons.rule, _cyan, 'قواعدى', 'لو حصل كذا نبّهنى',
            big: '1', bigSub: 'بتتحقق'),
        _row(Icons.inbox_outlined, _amber, 'صندوق الوارد',
            'فكرة سريعة تصنّفها بعدين', big: '3'),
        _row(Icons.event_repeat, _violet, 'التخطيط الأسبوعى',
            'طقس 10 دقايق آخر الأسبوع'),
        _row(Icons.folder_outlined, _blue, 'المستندات',
            'بطاقة · رخصة · عقود', big: '4', bigSub: 'ورقة'),
      ])),
    ]);

// ═══════════ ٢ · قايمة واحدة بأرقامها ═══════════

/// نفس الدمج، بس من غير عناوين مجموعات — كل بند بيقول رقمه زى «تطوّرى».
Widget tools2() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'المتابعة والأدوات', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 6),
        _row(Icons.lightbulb_outline, _amber, 'رؤى المدير',
            'أنماط من بياناتك', big: '4', bigSub: 'رؤية'),
        _row(Icons.bar_chart, _blue, 'إحصائياتك',
            'نوم · خطوات · مياه · وزن', big: '6', bigSub: 'رسم'),
        _row(Icons.picture_as_pdf_outlined, _rose, 'تقارير PDF',
            'مخصّص · الشهر · الدكتور', big: '3'),
        _row(Icons.calendar_month_outlined, _teal, 'تقويم النتيجة',
            'دوس على يوم تشوفه كله', big: '18', bigSub: 'يوم فيه نشاط'),
        _row(Icons.emoji_events_outlined, _violet, 'المراجعة السنوية',
            'ملخّص سنتك'),
        _row(Icons.rule, _cyan, 'قواعدى', 'لو حصل كذا نبّهنى',
            big: '1', bigSub: 'بتتحقق'),
        _row(Icons.inbox_outlined, _amber, 'صندوق الوارد',
            'فكرة سريعة تصنّفها بعدين', big: '3'),
        _row(Icons.event_repeat, _violet, 'التخطيط الأسبوعى',
            'آخر مرة من أسبوعين'),
        _row(Icons.calculate_outlined, _green, 'حاسبات',
            'زكاة · كتلة جسم · قسط', big: '8'),
        _row(Icons.folder_outlined, _blue, 'المستندات',
            'واحدة قربت تنتهى', big: '4', bigSub: 'ورقة'),
      ])),
    ]);

// ═══════════ ٣ · أقل تغيير ═══════════

/// نشيل «التقارير» (الطبقة الزيادة) و«مركز التنبيهات» (الجرس بيعمله)
/// بس — والباقى زى ما هو، من غير دمج ولا مجموعات.
Widget tools3() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'المتابعة والأدوات', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 6),
        _row(Icons.lightbulb_outline, _amber, 'رؤى المدير', 'أنماط من بياناتك'),
        _row(Icons.emoji_events_outlined, _violet, 'المراجعة السنوية',
            'ملخّص سنتك'),
        _row(Icons.bar_chart, _blue, 'إحصائياتك', 'نوم · خطوات · مياه · وزن'),
        _row(Icons.picture_as_pdf_outlined, _rose, 'تقارير PDF',
            'مخصّص · الشهر · الدكتور'),
        _row(Icons.calculate_outlined, _green, 'حاسبات', 'زكاة · قسط · وحدات'),
        _row(Icons.calendar_month_outlined, _teal, 'تقويم النتيجة',
            'شهرك ملوّن'),
        _row(Icons.history_toggle_off, _cyan, 'آلة الزمن', 'افتح أى يوم فات'),
        _row(Icons.rule, _cyan, 'قواعدى', 'لو حصل كذا نبّهنى'),
        _row(Icons.inbox_outlined, _amber, 'صندوق الوارد', 'فكرة سريعة'),
        _row(Icons.event_repeat, _violet, 'التخطيط الأسبوعى', 'طقس 10 دقايق'),
        _row(Icons.folder_outlined, _blue, 'المستندات', 'بطاقة · رخصة · عقود'),
      ])),
    ]);

void main() {
  testWidgets('المتابعة والأدوات', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_13_tools',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('مجموعات · ١٠ بنود', 'شوف نفسك · ارجع لورا · أدواتك', tools1()),
            ('قايمة بأرقامها · ١٠', 'زى تطوّرى — كل بند بيقول رقمه', tools2()),
            ('أقل تغيير · ١١', 'شِلنا الطبقة الزيادة والتنبيهات بس', tools3()),
          ])),
      size: const Size(1152, 1130),
      pixelRatio: 2,
    );
  });
}
