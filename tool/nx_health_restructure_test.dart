// إعادة ترتيب «صحتى» — ٣ أشكال + شاشة الأدوية المدمجة.
//
// المشكلة اللى الأشكال دى بتحلّها:
//  · «لوحة الصحة» بقت مكرّرة مع «صحتى» (نفس المياه والنوم والخطوات).
//  · تلات شاشات (الأعراض · التطعيمات · التحاليل) طريقها الوحيد أيقونة
//    فى الشريط ← كارت جوّه اللوحة = دوستين ورا أيقونة مش مفهومة.
//  · «الأدوية» و«صيدلية البيت» اسمين مش بيقولوا الفرق بينهم.
//
//   flutter test tool/nx_health_restructure_test.dart
//   → build/design_shots/nx_11_health.png · nx_12_meds.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _rose = Color(0xFFF43F5E);
const _blue = Color(0xFF3B82F6);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF10B981);
const _violet = Color(0xFF8B5CF6);
const _cyan = Color(0xFF06B6D4);
const _orange = Color(0xFFFF6F00);

Widget _bar(double v, Color c, {bool onTint = false, double h = 8}) => ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: v,
        minHeight: h,
        backgroundColor: onTint ? Colors.white : k.tint(c),
        valueColor: AlwaysStoppedAnimation(c),
      ),
    );

/// صفّ «لازم النهاردة».
Widget _todo(String title, String note, String trail, Color c,
        {bool done = false, bool last = false}) =>
    Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: k.line))),
      child: Row(children: [
        Icon(done ? Icons.check_circle : Icons.circle_outlined,
            size: 21, color: done ? _green : k.mute),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: done ? k.mute : k.ink,
                    decoration: done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            rdT(note, k, size: 9.5, color: k.mute, maxLines: 1),
          ]),
        ),
        rdT(trail, k, size: 10.5, w: FontWeight.w800, color: c),
      ]),
    );

/// مربّع رقم.
Widget _sq(IconData icon, Color c, String value, String label,
        {String? trend, bool up = false}) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
        decoration: BoxDecoration(
            color: k.tint(c),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.22))),
        child: Column(children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(height: 5),
          rdT(value, k, size: 14.5, w: FontWeight.w900, maxLines: 1),
          rdT(label, k, size: 9, color: k.mute, maxLines: 1),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(up ? Icons.north_east : Icons.south_east,
                  size: 9, color: up ? _rose : _green),
              rdT(trend, k,
                  size: 8.5, w: FontWeight.w800, color: up ? _rose : _green),
            ]),
          ],
        ]),
      ),
    );

/// باب: أيقونة · اسم · اللى جوّاه · رقم.
Widget _door(IconData icon, Color c, String title, String sub,
        {String? big, String? bigSub}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: k.line),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(c), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(title, k, size: 13, w: FontWeight.w800, maxLines: 1),
              const SizedBox(height: 2),
              rdT(sub, k, size: 10, color: k.mute, maxLines: 1),
            ]),
          ),
          if (big != null) ...[
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              rdT(big, k, size: 15, w: FontWeight.w900, color: c),
              if (bigSub != null) rdT(bigSub, k, size: 8.5, color: k.mute),
            ]),
          ],
          Icon(Icons.chevron_left, size: 18, color: k.mute),
        ]),
      ),
    );

Widget _today() => rdCard(
      k,
      Column(children: [
        _todo('كونكور 5 — الصبح', 'اتاخدت 8:00 ص', 'اتاخدت', _green,
            done: true),
        _todo('كونكور 5 — بالليل', 'لسه ماجاش وقتها', '9:00 م', k.mute),
        _todo('اشرب 8 أكواب مياه', 'فاضل كوبايتين', '6 من 8', _blue,
            last: true),
      ]),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
    );

Widget _numbers({bool withBmi = false}) => Column(children: [
      Row(children: [
        _sq(Icons.monitor_weight_outlined, _blue, '84', 'كيلو',
            trend: '1.2', up: true),
        const SizedBox(width: 8),
        _sq(Icons.favorite_outline, _rose, '12/8', 'ضغط'),
        const SizedBox(width: 8),
        _sq(Icons.bloodtype_outlined, _amber, '95', 'سكر'),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _sq(Icons.directions_walk, _green, '2,400', 'خطوة'),
        const SizedBox(width: 8),
        _sq(Icons.bedtime_outlined, _violet, '6 س', 'نوم'),
        const SizedBox(width: 8),
        _sq(Icons.local_fire_department_outlined, _orange, '1,420', 'سعرة'),
      ]),
      if (withBmi) ...[
        const SizedBox(height: 9),
        rdCard(
            k,
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      rdT('كتلة الجسم 27.4 — زيادة بسيطة', k,
                          size: 11.5, w: FontWeight.w800, maxLines: 1),
                      const SizedBox(height: 7),
                      _bar(0.62, _amber, h: 7),
                    ]),
              ),
              const SizedBox(width: 10),
              Icon(Icons.show_chart, size: 19, color: k.accent),
              const SizedBox(width: 4),
              rdT('الرسوم', k, size: 10, color: k.accent, w: FontWeight.w800),
            ]),
            padding: const EdgeInsets.all(11)),
      ],
    ]);

// ═══════════ ١ · أربع أبواب (لوحة الصحة اتلغت) ═══════════

Widget health1() => rdPhone(k, height: 1090, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'لازم النهاردة', trailing: '1 من 3'),
        _today(),
        rdSection(k, 'أرقامك'),
        _numbers(withBmi: true),
        rdSection(k, 'بنودك'),
        _door(Icons.favorite_outline, _rose, 'الصحة',
            'دورة · عادات · مزاج · أدوية', big: '1', bigSub: 'جرعة فاضلة'),
        _door(Icons.fitness_center, _violet, 'الرياضة',
            'جيم · مشى · تقدّم · تمارين', big: '3', bigSub: 'هذا الأسبوع'),
        _door(Icons.restaurant_outlined, _green, 'أكلك',
            'وجبات · صيام · وصفات', big: '1,420', bigSub: 'سعرة'),
        // 🔴 الباب الرابع هو بيت التلات شاشات اللى كانت مدفونة ورا
        // أيقونة فى الشريط.
        _door(Icons.folder_shared_outlined, _cyan, 'ملفك الطبى',
            'تحاليل · تطعيمات · أعراض · ملف', big: '6', bigSub: 'ورقة'),
      ])),
    ]);

// ═══════════ ٢ · أربع أبواب + «لوحة الصحة» باقية ═══════════

Widget health2() => rdPhone(k, height: 1090, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'لازم النهاردة', trailing: '1 من 3'),
        _today(),
        rdSection(k, 'أرقامك'),
        _numbers(),
        rdSection(k, 'بنودك'),
        _door(Icons.favorite_outline, _rose, 'الصحة',
            'دورة · عادات · مزاج · أدوية', big: '1', bigSub: 'جرعة فاضلة'),
        _door(Icons.fitness_center, _violet, 'الرياضة',
            'جيم · مشى · تقدّم · تمارين', big: '3'),
        _door(Icons.restaurant_outlined, _green, 'أكلك',
            'وجبات · صيام · وصفات', big: '1,420'),
        _door(Icons.folder_shared_outlined, _cyan, 'ملفك الطبى',
            'تحاليل · تطعيمات · أعراض', big: '6'),
        _door(Icons.dashboard_outlined, _blue, 'لوحة الصحة',
            'رسوم · كتلة الجسم · سجل كامل'),
      ])),
    ]);

// ═══════════ ٣ · أقل تغيير: التلاتة زى ما هُمّ + صفّ للمدفونين ═══════════

Widget health3() => rdPhone(k, height: 1090, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'لازم النهاردة', trailing: '1 من 3'),
        _today(),
        rdSection(k, 'أرقامك'),
        _numbers(),
        rdSection(k, 'بنودك'),
        _door(Icons.favorite_outline, _rose, 'الصحة',
            'دورة · عادات · مزاج · أدوية', big: '1'),
        _door(Icons.fitness_center, _violet, 'الرياضة',
            'جيم · مشى · تقدّم', big: '3'),
        _door(Icons.restaurant_outlined, _green, 'أكلك',
            'وجبات · صيام · وصفات', big: '1,420'),
        rdSection(k, 'ورقك الطبى'),
        // بدل باب رابع: التلاتة المدفونين بيطلعوا **مربعات** على طول.
        Row(children: [
          for (final t in const [
            ('تحاليل', _cyan, Icons.science_outlined, '4'),
            ('تطعيمات', _green, Icons.vaccines_outlined, '2'),
            ('أعراض', _amber, Icons.sick_outlined, '—'),
          ]) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: k.tint(t.$2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.$2.withValues(alpha: 0.25))),
                child: Column(children: [
                  Icon(t.$3, size: 17, color: t.$2),
                  const SizedBox(height: 5),
                  rdT(t.$4, k, size: 16, w: FontWeight.w900, color: t.$2),
                  rdT(t.$1, k, size: 9.5, color: k.mute),
                ]),
              ),
            ),
          ],
        ]),
      ])),
    ]);

// ═══════════ أدويتى المدمجة ═══════════

/// «الأدوية» + «صيدلية البيت» فى شاشة واحدة بتبويبين.
///
/// الاسمين الحاليين مش بيقولوا الفرق: الأول للجرعات والتانى للمخزون
/// والصلاحية — فالناس بتفتح الاتنين وتلاقيهم شبه بعض.
Widget meds() => rdPhone(k, height: 760, children: [
      rdTop(k, 'أدويتى', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdChips(k, const ['جرعاتك', 'مخزونك']),
        const SizedBox(height: 14),
        rdCard(
            k,
            Column(children: [
              _todo('كونكور 5', 'اتاخدت 8:00 ص', 'اتاخدت', _green, done: true),
              _todo('كونكور 5', 'لسه ماجاش وقتها', '9:00 م', k.mute),
              _todo('xarelto 20mg', 'كان المفروض 12:00 م', 'فاتت', _rose,
                  last: true),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3)),
        rdSection(k, 'ينفد قريب', trailing: '2'),
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_amber),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 16, color: _amber),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('كونكور 5', k, size: 12.5, w: FontWeight.w800),
                      rdT('فاضل 6 أقراص · تكفى 3 أيام', k,
                          size: 9.5, color: k.mute),
                    ])),
                rdT('3 أيام', k, size: 11, w: FontWeight.w800, color: _amber),
              ]),
              const Divider(height: 20),
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_rose),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.event_busy_outlined,
                      size: 16, color: _rose),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('أوجمنتين', k, size: 12.5, w: FontWeight.w800),
                      rdT('صلاحيته خلصت من شهر', k,
                          size: 9.5, color: k.mute),
                    ])),
                rdT('منتهى', k, size: 11, w: FontWeight.w800, color: _rose),
              ]),
            ])),
      ])),
    ], fab: rdFab(k));

// ═══════════ الرسم ═══════════

void main() {
  testWidgets('إعادة ترتيب صحتى', (tester) async {
    await loadShotFonts();

    await shot(
      tester,
      'nx_11_health',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('٤ أبواب · اللوحة اتلغت', 'الرسوم وكتلة الجسم جوّه «أرقامك»',
                health1()),
            ('٤ أبواب · اللوحة باقية', 'باب خامس لكل التفاصيل', health2()),
            ('أقل تغيير', 'التلاتة المدفونين بقوا مربعات', health3()),
          ])),
      size: const Size(1152, 1220),
      pixelRatio: 2,
    );

    await shot(
      tester,
      'nx_12_meds',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('أدويتى — واحدة بتبويبين', '«الأدوية» + «صيدلية البيت» مدموجين',
                meds()),
          ])),
      size: const Size(420, 890),
      pixelRatio: 2,
    );
  });
}
