// التكرار فى «صحتى» — ٣ أشكال للدمج.
//
// اللى الأشكال بتحلّه (كله اتقاس من الكود، مش رأى):
//  · «لوحة الصحة» شاشة تانية على نفس البيانات، ولسه ليها مدخلين:
//    زرار القلب فى الرئيسية (`today_screen.dart:2176`) وكارت الداشبورد
//    (`dash_card.dart:55`). وفيها حاجات مش موجودة فى «صحتى»: الحرارة،
//    وBMR/TDEE، وتقويم الصحة.
//  · «التقدم البدنى» بيكتب وزنه فى `body_progress` و«صحتى» بتقرا من
//    `measurements` — وزنين مابيتقابلوش.
//  · «مكتبة التمارين» و«برامج التمارين» محتوى جاهز مافيهوش بياناتك.
//  · «الأنظمة الغذائية» مالهاش جدول — بتظبط هدف السعرات وبس.
//
//   flutter test tool/nx_health_dup_test.dart → build/design_shots/nx_14_health.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _pink = Color(0xFFEC4899);
const _violet = Color(0xFF8B5CF6);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);
const _rose = Color(0xFFF43F5E);

/// سطر بند عادى.
Widget _row(IconData icon, Color c, String title, String sub,
        {String? big, String? bigSub, bool dim = false}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: k.line),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(dim ? k.mute : c),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: dim ? k.mute : c),
          ),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(title, k,
                  size: 12, w: FontWeight.w800, maxLines: 1,
                  color: dim ? k.mute : null),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 1),
                rdT(sub, k, size: 9, color: k.mute, maxLines: 1),
              ],
            ]),
          ),
          if (big != null) ...[
            const SizedBox(width: 5),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              rdT(big, k, size: 13, w: FontWeight.w900, color: c),
              if (bigSub != null) rdT(bigSub, k, size: 8, color: k.mute),
            ]),
          ],
          Icon(Icons.chevron_left, size: 16, color: k.mute),
        ]),
      ),
    );

/// شريط بيقول إيه اللى اتشال ورايح فين.
Widget _note(String text, Color c) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: k.tint(c),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.call_merge, size: 14, color: c),
          const SizedBox(width: 7),
          Expanded(child: rdT(text, k, size: 9.5, color: c, maxLines: 2)),
        ]),
      ),
    );

/// مربّع رقم صغير (أرقامك).
Widget _sq(String label, String value, Color c) => Expanded(
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: k.tint(c),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          rdT(value, k, size: 14, w: FontWeight.w900, color: c),
          rdT(label, k, size: 8.5, color: k.mute),
        ]),
      ),
    );

// ═══════════ ١ · باب واحد للصحة ═══════════

/// «لوحة الصحة» تتشال خالص واللى فيها ينزل جوّه «صحتى»، و«التقدّم
/// البدنى» يتوحّد مع الوزن.
Widget health1() => rdPhone(k, height: 1120, children: [
      rdTop(k, 'صحتى', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _note('«لوحة الصحة» اتشالت — اللى كان فيها بس مش هنا نزل جوّه: '
            'الحرارة · طاقتك اليومية · تقويم الصحة', _pink),
        rdSection(k, 'لازم النهاردة', trailing: '٢ من ٤'),
        _row(Icons.medication_outlined, _rose, 'كونكور ٥', '٨:٠٠ صباحاً'),
        _row(Icons.water_drop_outlined, _blue, 'اشرب ٨ أكواب', '٥ من ٨'),
        rdSection(k, 'أرقامك'),
        Row(children: [
          _sq('وزن', '95', _violet),
          _sq('ضغط', '12/8', _rose),
          _sq('سكر', '95', _amber),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          _sq('حرارة', '37', _rose),
          _sq('نوم', '7', _blue),
          _sq('خطوات', '6k', _green),
        ]),
        const SizedBox(height: 9),
        _row(Icons.monitor_weight_outlined, _violet, 'كتلة جسمك ٢٨٫٤',
            'وطاقتك اليومية ٢٣٠٠ سعرة', big: 'زيادة'),
        _row(Icons.calendar_month_outlined, _blue, 'تقويم صحتك',
            'يوم بيوم: نوم · مياه · أكل · قياسات', big: '18', bigSub: 'يوم'),
        rdSection(k, 'بنودك'),
        _row(Icons.favorite_outline, _pink, 'الصحة', 'دورة · عادات · مزاج · أدوية'),
        _row(Icons.fitness_center, _violet, 'الرياضة', 'جيم · مشى · تمارين'),
        _row(Icons.restaurant_outlined, _green, 'الأكل', 'وجبات · صيام · وصفات'),
        rdSection(k, 'ورقك الطبى'),
        _row(Icons.biotech_outlined, _amber, 'التحاليل', 'بصورها', big: '6'),
        _row(Icons.vaccines_outlined, _green, 'التطعيمات', '', big: '3'),
        _row(Icons.sick_outlined, _rose, 'الأعراض', '', big: '2'),
      ])),
    ]);

// ═══════════ ٢ · الباب الواحد + تنضيف جوّه البنود ═══════════

/// نفس شكل ١، وزيادة: الأبواب اللى جوّه «الرياضة» و«الأكل» تتلمّ.
Widget health2() => rdPhone(k, height: 1120, children: [
      rdTop(k, 'الرياضة', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _note('«التقدّم البدنى» كان بيكتب وزنه فى مكان تانى — بقى جوّه '
            'الجيم، والوزن واحد', _violet),
        const SizedBox(height: 2),
        _row(Icons.fitness_center, _violet, 'الجيم',
            'تمرينك · أرقامك القياسية · صور التقدّم',
            big: '12', bigSub: 'تمرينة'),
        _row(Icons.directions_run, _green, 'المشى والجرى', 'آخر مرة من يومين',
            big: '3.2', bigSub: 'كم'),
        _row(Icons.menu_book_outlined, _blue, 'التمارين والبرامج',
            'شرح وبرامج جاهزة — محتوى للقراءة', big: '60', bigSub: 'تمرين'),
        rdSection(k, 'اللى اتلمّ'),
        _row(Icons.monitor_weight_outlined, _violet, 'التقدم البدني',
            'راح جوّه «الجيم»', dim: true),
        _row(Icons.list_alt_outlined, _blue, 'برامج التمارين',
            'راحت جوّه «التمارين»', dim: true),
        rdSection(k, 'والأكل كمان'),
        _row(Icons.restaurant_menu, _green, 'أكلت إيه النهاردة',
            'دليل الأكل + تسجيل الوجبة', big: '1450', bigSub: 'سعرة'),
        _row(Icons.flag_outlined, _amber, 'هدفك',
            'نظامك الغذائى + هدف السعرات والماكروز'),
        _row(Icons.calendar_view_week_outlined, _blue, 'مخطّط الأسبوع',
            'ومنه لقايمة المشتريات'),
        _row(Icons.timer_outlined, _violet, 'الصيام المتقطّع', 'شغّال من ٦ ساعات'),
        _row(Icons.menu_book_outlined, _rose, 'وصفاتك', '', big: '8'),
      ])),
    ]);

// ═══════════ ٣ · أقل تغيير ═══════════

/// نصلّح الحاجات الغلط بس، من غير ما ندمج أى بند.
Widget health3() => rdPhone(k, height: 1120, children: [
      rdTop(k, 'إيه اللى هيتصلّح', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'أعطاب حقيقية'),
        _row(Icons.monitor_weight_outlined, _rose, 'الوزن فى مكانين',
            '«التقدّم البدنى» بيكتب فى مكان مالوش علاقة بالباقى'),
        _row(Icons.link_off, _rose, 'كارت بيقولك سجّل وزنك',
            'وبيفضل فاضى بعد ما تسجّل — بيقرا من مكان تانى'),
        _row(Icons.thermostat, _amber, 'الحرارة',
            'بتتسجّل من «لوحة الصحة» بس، مش من «صحتى»'),
        _row(Icons.swap_horiz, _amber, 'خطّتك فى الجيم',
            '«برامج التمارين» بتمسحها كلها لما تطبّق برنامج'),
        rdSection(k, 'بابين على نفس الحاجة'),
        _row(Icons.dashboard_outlined, _pink, 'لوحة الصحة',
            'لسه بتتفتح من زرار القلب ومن كارت الداشبورد'),
        _row(Icons.height, _blue, 'طولك وسنة ميلادك',
            'بتتكتب من شاشتين مختلفتين'),
        _row(Icons.science_outlined, _amber, 'تحاليلك',
            'فى «الملف الطبى» وفى «مؤشرات التحاليل» — مالهمش علاقة'),
        rdSection(k, 'بنود مافيهاش بياناتك'),
        _row(Icons.menu_book_outlined, _blue, 'مكتبة التمارين',
            'محتوى جاهز — مفيش جدول', dim: true),
        _row(Icons.list_alt_outlined, _blue, 'برامج التمارين',
            'محتوى جاهز + زرار بيكتب خطّتك', dim: true),
        _row(Icons.restaurant_menu, _green, 'الأنظمة الغذائية',
            'بتظبط هدف السعرات وبس', dim: true),
      ])),
    ]);

void main() {
  testWidgets('تكرار صحتى', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_14_health',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('باب واحد للصحة', 'لوحة الصحة تتشال واللى فيها ينزل جوّه صحتى',
                health1()),
            ('وكمان تنضيف جوّه البنود', 'الرياضة ٥ → ٣ · الأكل ٥ → ٥ بأسماء تقول',
                health2()),
            ('أقل تغيير', 'نصلّح الغلط بس من غير دمج', health3()),
          ])),
      size: const Size(1152, 1250),
      pixelRatio: 2,
    );
  });
}
