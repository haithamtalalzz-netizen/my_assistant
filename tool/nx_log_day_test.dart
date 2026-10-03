// «عملت رياضة قد إيه» و«أكلت إيه» — ٣ أشكال للتسجيل.
//
// الوقايع اللى الأشكال مبنية عليها (اتقاست من الكود):
//  · «أكلت إيه» **موجود أصلاً**: مربّع «سعرة» بيفتح `showMealSheet`
//    (خانة أكل + سعرات + ماكروز). المشكلة إن المربّع بيقول رقم السعرات،
//    فمش باين إنه هو ده مكان تسجيل الأكل.
//  · «عملت رياضة قد إيه» **مالوش مكان**: `gym_sessions.duration_min`
//    موجود، بس بيتكتب من فورم الجيم (برنامج + مجموعات + تكرارات)، و
//    `activity_sessions.duration_sec` بيتكتب من متتبّع GPS. مفيش طريقة
//    تقول «مشيت ٣٠ دقيقة» من غير ما تفتح شاشة كاملة.
//  · الخطوات بتيجى لوحدها من Health Connect، فالمدة هى الرقم الوحيد
//    اللى محتاج إيد.
//
//   flutter test tool/nx_log_day_test.dart → build/design_shots/nx_15_logday.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _violet = Color(0xFF8B5CF6);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);
const _rose = Color(0xFFF43F5E);
const _orange = Color(0xFFFF6F00);

/// مربّع رقم من «أرقامك».
Widget _sq(IconData icon, Color c, String? value, String label,
        {String? trail}) =>
    Expanded(
      child: Container(
        height: 86,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
            color: k.tint(c), borderRadius: BorderRadius.circular(15)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: c),
          const SizedBox(height: 3),
          rdT(value ?? '—', k,
              size: value == null ? 14 : 17,
              w: FontWeight.w900,
              color: value == null ? k.mute : k.ink),
          rdT(label, k, size: 9, color: k.mute),
          if (trail != null) rdT(trail, k, size: 8, color: c),
        ]),
      ),
    );

/// سطر عريض بيقول اللى اتسجّل النهاردة بالكلام.
Widget _dayRow(IconData icon, Color c, String title, String sub,
        {String? big, List<String> chips = const []}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: k.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rdT(title, k, size: 12.5, w: FontWeight.w800, maxLines: 1),
                    const SizedBox(height: 1),
                    rdT(sub, k, size: 9.5, color: k.mute, maxLines: 1),
                  ]),
            ),
            if (big != null)
              rdT(big, k, size: 15, w: FontWeight.w900, color: c),
            const SizedBox(width: 4),
            Icon(Icons.add_circle_outline, size: 19, color: c),
          ]),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final ch in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: k.tint(c),
                      borderRadius: BorderRadius.circular(999)),
                  child: rdT(ch, k, size: 9.5, w: FontWeight.w700, color: c),
                ),
            ]),
          ],
        ]),
      ),
    );

Widget _head(String t, {String? trail}) => rdSection(k, t, trailing: trail);

// ═══════════ ١ · مربّعين زيادة فى «أرقامك» ═══════════

/// أقل تغيير: «رياضة» يبقى مربّع تامن جنب الخطوات والنوم، و«سعرة»
/// يتسمّى «أكلت» عشان يبان إنه مكان تسجيل مش عرض رقم.
Widget shape1() => rdPhone(k, height: 880, children: [
      rdTop(k, 'صحتى', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _head('لازم النهاردة', trail: '٢ من ٤'),
        _dayRow(Icons.medication_outlined, _rose, 'كونكور ٥', '٨:٠٠ صباحاً'),
        _head('أرقامك'),
        Row(children: [
          _sq(Icons.monitor_weight_outlined, _blue, '84', 'كيلو'),
          _sq(Icons.favorite_outline, _rose, '12/8', 'ضغط'),
          _sq(Icons.bloodtype_outlined, _amber, null, 'سكر'),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          _sq(Icons.directions_walk, _green, '2,400', 'خطوة'),
          _sq(Icons.bedtime_outlined, _violet, '6 س', 'نوم'),
          _sq(Icons.local_fire_department_outlined, _orange, '1,450', 'أكلت'),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          _sq(Icons.fitness_center, _violet, '40 د', 'رياضة', trail: 'مشى'),
          _sq(Icons.water_drop_outlined, _blue, '6/8', 'مياه'),
          const Expanded(child: SizedBox()),
        ]),
        const SizedBox(height: 10),
        rdT('دوسة على «رياضة» بتفتح ورقة صغيرة: نوع + مدة. وعلى «أكلت» '
            'بتفتح ورقة الوجبة اللى موجودة أصلاً.', k,
            size: 10, color: k.mute, maxLines: 3),
      ])),
    ]);

// ═══════════ ٢ · سطرين «اليوم» بيقولوا بالكلام ═══════════

/// المربّع بيقول رقم؛ السطر بيقول **إيه**. «٤٠ د» مابتقولش مشيت ولا
/// لعبت حديد، و«١٤٥٠ سعرة» مابتقولش أكلت إيه.
Widget shape2() => rdPhone(k, height: 880, children: [
      rdTop(k, 'صحتى', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _head('لازم النهاردة', trail: '٢ من ٤'),
        _dayRow(Icons.medication_outlined, _rose, 'كونكور ٥', '٨:٠٠ صباحاً'),
        _head('عملت إيه النهاردة'),
        _dayRow(Icons.fitness_center, _violet, 'رياضة',
            'مشى ٣٠ د · جيم ١٠ د', big: '٤٠ د'),
        _dayRow(Icons.restaurant_outlined, _green, 'أكلت',
            'فطار · غدا · سناك', big: '١٤٥٠'),
        _head('أرقامك'),
        Row(children: [
          _sq(Icons.monitor_weight_outlined, _blue, '84', 'كيلو'),
          _sq(Icons.favorite_outline, _rose, '12/8', 'ضغط'),
          _sq(Icons.bloodtype_outlined, _amber, null, 'سكر'),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          _sq(Icons.directions_walk, _green, '2,400', 'خطوة'),
          _sq(Icons.bedtime_outlined, _violet, '6 س', 'نوم'),
          _sq(Icons.water_drop_outlined, _blue, '6/8', 'مياه'),
        ]),
      ])),
    ]);

// ═══════════ ٣ · نفس السطرين + أزرار جاهزة (دوسة واحدة) ═══════════

/// اللى بيخلّى التسجيل يستمر هو إنه **مايتكلّفش فورم**. الأزرار الجاهزة
/// بتتعلّم من اللى بتعمله: أكتر ٣ حاجات سجّلتها بتفضل قدامك، ودوسة
/// واحدة بتسجّلها بمدتها.
Widget shape3() => rdPhone(k, height: 880, children: [
      rdTop(k, 'صحتى', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _head('لازم النهاردة', trail: '٢ من ٤'),
        _dayRow(Icons.medication_outlined, _rose, 'كونكور ٥', '٨:٠٠ صباحاً'),
        _head('عملت إيه النهاردة'),
        _dayRow(Icons.fitness_center, _violet, 'رياضة', 'مشى ٣٠ د',
            big: '٣٠ د',
            chips: ['مشى ٣٠ د', 'جيم ٤٥ د', 'جرى ٢٠ د', 'غير كده…']),
        _dayRow(Icons.restaurant_outlined, _green, 'أكلت', 'فطار · غدا',
            big: '٩٨٠', chips: ['فطار', 'غدا', 'عشا', 'سناك', 'غير كده…']),
        _head('أرقامك'),
        Row(children: [
          _sq(Icons.monitor_weight_outlined, _blue, '84', 'كيلو'),
          _sq(Icons.favorite_outline, _rose, '12/8', 'ضغط'),
          _sq(Icons.bloodtype_outlined, _amber, null, 'سكر'),
        ]),
        const SizedBox(height: 10),
        rdT('الزرار الجاهز بيسجّل على طول من غير ما يفتح حاجة. '
            '«غير كده» بيفتح الورقة الكاملة.', k,
            size: 10, color: k.mute, maxLines: 2),
      ])),
    ]);

void main() {
  testWidgets('تسجيل الرياضة والأكل', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_15_logday',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('مربّعين زيادة', 'أقل تغيير — رياضة جنب الخطوات', shape1()),
            ('سطرين بيقولوا إيه', 'الرقم مابيقولش عملت إيه ولا أكلت إيه',
                shape2()),
            ('وأزرار جاهزة', 'دوسة واحدة تسجّل — من غير فورم', shape3()),
          ])),
      size: const Size(1152, 1010),
      pixelRatio: 2,
    );
  });
}
