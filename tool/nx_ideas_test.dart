// الدفعة الجاية من الريديزاين — «باقى البنود».
//
// الفرق عن دفعات قبل كده: الاختيار هنا مش «ترتيب» — ده **فكرة البند**
// نفسها. «فلوسى» اتبنت على قاعدة طلعت شغّالة: مربّع فوق بيقول الخلاصة،
// وتحته أزرار **كل زرار بيقول رقمه** قبل ما تدوس. الأشكال هنا بتجرّب
// نفس القاعدة على بنود تانية، وبتجرّب بدايل ليها.
//
//   flutter test tool/nx_ideas_test.dart
//   → build/design_shots/nx_<البند>.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _blue = Color(0xFF3B82F6);
const _rose = Color(0xFFF43F5E);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF10B981);
const _violet = Color(0xFF8B5CF6);
const _cyan = Color(0xFF06B6D4);
const _teal = Color(0xFF14B8A6);
const _orange = Color(0xFFFF6F00);

// ═══════════════════════ قطع مشتركة ═══════════════════════

/// زرار على طريقة «فلوسى»: أيقونة · اسم · **رقمه** · سهم.
/// القاعدة: مايبقاش فيه زرار بيفتح صفحة من غير ما يقول اللى جوّاها.
Widget _btn(IconData icon, Color tint, String title, String sub,
        {String? big, String? bigSub, Color? bigColor}) =>
    Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: k.line),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: k.tint(tint), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, size: 19, color: tint),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            rdT(title, k, size: 13.5, w: FontWeight.w800, maxLines: 1),
            const SizedBox(height: 2),
            rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
          ]),
        ),
        if (big != null) ...[
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            rdT(big, k,
                size: 17, w: FontWeight.w900, color: bigColor ?? tint),
            if (bigSub != null)
              rdT(bigSub, k, size: 9.5, color: k.mute, maxLines: 1),
          ]),
        ],
        Icon(Icons.chevron_left, size: 19, color: k.mute),
      ]),
    );

Widget _gap([double h = 10]) => SizedBox(height: h);

/// مربّع رقم صغير — للأرقام اللى بتتقرا بسرعة (وزن · ضغط · خطوات).
Widget _sq(IconData icon, Color tint, String value, String label,
        {String? trend, bool up = true}) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 9),
        decoration: BoxDecoration(
            color: k.tint(tint),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tint.withValues(alpha: 0.22))),
        child: Column(children: [
          Icon(icon, size: 17, color: tint),
          const SizedBox(height: 6),
          rdT(value, k, size: 16, w: FontWeight.w900),
          const SizedBox(height: 1),
          rdT(label, k, size: 9.5, color: k.mute, maxLines: 1),
          if (trend != null) ...[
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(up ? Icons.north_east : Icons.south_east,
                  size: 10, color: up ? _rose : _green),
              const SizedBox(width: 2),
              rdT(trend, k,
                  size: 9, w: FontWeight.w800, color: up ? _rose : _green),
            ]),
          ],
        ]),
      ),
    );

/// شريط تقدّم.
///
/// 🔴 مصيدة: المسار (اللى لسه مااتملاش) لونه `k.tint(c)` — وده **نفس لون
/// الكارت الملوّن**، فالمسار بيختفى والشريط يبان **مليان** وهو مش مليان.
/// جوّه كارت ملوّن المسار لازم يبقى أبيض. نفس عيلة العطب بتاع
/// `AppHeroBar` الأبيض اللى اختفى على كارت أبيض.
Widget _bar(double v, Color c, {double h = 8, bool onTint = false}) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: v,
        minHeight: h,
        backgroundColor: onTint ? Colors.white : k.tint(c),
        valueColor: AlwaysStoppedAnimation(c),
      ),
    );

/// صف «لازم النهاردة» — دايرة + كلام + وقت.
Widget _todo(String title, String when, Color c,
        {bool done = false, String? note}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Icon(done ? Icons.check_circle : Icons.circle_outlined,
            size: 22, color: done ? _green : k.mute),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: done ? k.mute : k.ink,
                    decoration: done ? TextDecoration.lineThrough : null)),
            if (note != null) ...[
              const SizedBox(height: 2),
              rdT(note, k, size: 10, color: k.mute, maxLines: 1),
            ],
          ]),
        ),
        rdT(when, k, size: 11, color: c, w: FontWeight.w800),
      ]),
    );

/// زرّين جنب بعض — «＋» بالأيقونة مش بالرمز (خط Cairo مافيهوش «＋»).
Widget _twoBtns(String a, String b, Color ca, Color cb) => Row(children: [
      Expanded(
          child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: ca, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add, size: 17, color: Colors.white),
          const SizedBox(width: 5),
          Text(a,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w800)),
        ]),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: cb, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add, size: 17, color: Colors.white),
          const SizedBox(width: 5),
          Text(b,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w800)),
        ]),
      )),
    ]);

// ═══════════════════════ ١ · صحتى ═══════════════════════

/// **صحتك النهاردة** — نفس قاعدة فلوسى بالظبط.
Widget health1() => rdPhone(k, height: 950, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(children: [
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_rose),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.favorite, size: 22, color: _rose),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('صحتك النهاردة', k, size: 12, color: k.mute),
                      const SizedBox(height: 3),
                      rdT('4 من 6 اتعملوا', k, size: 21, w: FontWeight.w900),
                    ])),
              ]),
              const SizedBox(height: 12),
              _bar(4 / 6, _rose, onTint: true),
              const SizedBox(height: 12),
              Row(children: [
                _sq(Icons.water_drop_outlined, _blue, '6', 'أكواب مياه'),
                const SizedBox(width: 8),
                _sq(Icons.directions_walk, _green, '2,400', 'خطوة'),
                const SizedBox(width: 8),
                _sq(Icons.bedtime_outlined, _violet, '6 س', 'نوم'),
              ]),
            ]),
            tint: _rose),
        _gap(14),
        _btn(Icons.medication_outlined, _rose, 'أدويتك',
            'كونكور 5 بالليل · 9:00 م',
            big: '1', bigSub: 'جرعة فاضلة'),
        _gap(),
        _btn(Icons.monitor_heart_outlined, _blue, 'قياساتك',
            'وزن 84 · ضغط 12/8 · من 3 أيام',
            big: '84', bigSub: 'كيلو'),
        _gap(),
        _btn(Icons.fitness_center, _violet, 'رياضتك',
            'آخر تمرين من يومين',
            big: '3', bigSub: 'هذا الأسبوع'),
        _gap(),
        _btn(Icons.restaurant_outlined, _green, 'أكلك',
            'فاضلك 580 سعرة النهاردة',
            big: '1,420', bigSub: 'سعرة'),
        _gap(),
        _btn(Icons.mood, _amber, 'مزاجك', 'مسجّلتش النهاردة'),
        _gap(),
        _btn(Icons.folder_shared_outlined, _cyan, 'ملفك الطبى',
            'تحاليل · تطعيمات · أعراض',
            big: '6', bigSub: 'ورقة'),
        _gap(14),
        _twoBtns('قياس', 'أكل', _blue, _green),
      ])),
    ]);

/// **درجة صحتك** — رقم واحد بيلخّص، وتحته اللى رفعه واللى نزّله.
Widget health2() => rdPhone(k, height: 950, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(children: [
        rdCard(
            k,
            Column(children: [
              rdT('درجة صحتك', k, size: 12, color: k.mute),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                rdT('78', k, size: 52, w: FontWeight.w900, color: _green),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: rdT('من 100', k, size: 13, color: k.mute),
                ),
              ]),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: k.tint(_green),
                    borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.north_east, size: 13, color: _green),
                  const SizedBox(width: 4),
                  rdT('زادت 6 عن الأسبوع اللى فات', k,
                      size: 11, w: FontWeight.w800, color: _green),
                ]),
              ),
            ]),
            tint: _green),
        _gap(12),
        rdCard(
            k,
            Column(children: [
              Row(children: [
                const Icon(Icons.trending_up, size: 16, color: _green),
                const SizedBox(width: 7),
                Expanded(
                    child: rdT('بتشرب مياه كل يوم · نمت كويس 5 أيام', k,
                        size: 11.5, color: k.mute, maxLines: 2)),
              ]),
              const Divider(height: 18),
              Row(children: [
                const Icon(Icons.trending_down, size: 16, color: _rose),
                const SizedBox(width: 7),
                Expanded(
                    child: rdT('نسيت جرعتين · مامشيتش من 4 أيام', k,
                        size: 11.5, color: k.mute, maxLines: 2)),
              ]),
            ])),
        _gap(14),
        _btn(Icons.medication_outlined, _rose, 'أدويتك', 'جرعة فاضلة',
            big: '3/4'),
        _gap(),
        _btn(Icons.monitor_heart_outlined, _blue, 'قياساتك', 'آخر وزن 84',
            big: '5'),
        _gap(),
        _btn(Icons.fitness_center, _violet, 'رياضتك', 'آخر تمرين من يومين',
            big: '3'),
        _gap(),
        _btn(Icons.restaurant_outlined, _green, 'أكلك', 'سعرات اليوم',
            big: '1,420'),
        _gap(),
        _btn(Icons.folder_shared_outlined, _cyan, 'ملفك الطبى', 'تحاليل وتطعيمات',
            big: '6'),
      ])),
    ]);

/// **لازم النهاردة · أرقامك** — الشاشة مقسومة لقسمين واضحين.
Widget health3() => rdPhone(k, height: 950, children: [
      rdTop(k, 'صحتى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'لازم النهاردة', trailing: '4 من 6'),
        rdCard(
            k,
            Column(children: [
              _todo('كونكور 5 — الصبح', '8:00 ص', _rose, done: true),
              const Divider(height: 1),
              _todo('كونكور 5 — بالليل', '9:00 م', _rose),
              const Divider(height: 1),
              _todo('اشرب 8 أكواب مياه', '6 من 8', _blue, note: 'فاضل كوبايتين'),
              const Divider(height: 1),
              _todo('امشى 30 دقيقة', 'ماتعملش', _rose),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
        rdSection(k, 'أرقامك'),
        Row(children: [
          _sq(Icons.monitor_weight_outlined, _blue, '84', 'كيلو',
              trend: '1.2', up: true),
          const SizedBox(width: 9),
          _sq(Icons.favorite_outline, _rose, '12/8', 'ضغط'),
          const SizedBox(width: 9),
          _sq(Icons.bloodtype_outlined, _amber, '95', 'سكر',
              trend: '4', up: false),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          _sq(Icons.directions_walk, _green, '2,400', 'خطوة'),
          const SizedBox(width: 9),
          _sq(Icons.bedtime_outlined, _violet, '6 س', 'نوم'),
          const SizedBox(width: 9),
          _sq(Icons.local_fire_department_outlined, _orange, '1,420', 'سعرة'),
        ]),
        rdSection(k, 'بنودك'),
        _btn(Icons.fitness_center, _violet, 'رياضتك', 'جيم · مشى · تقدّم',
            big: '3'),
        _gap(),
        _btn(Icons.restaurant_outlined, _green, 'أكلك', 'وجبات · صيام · وصفات'),
        _gap(),
        _btn(Icons.folder_shared_outlined, _cyan, 'ملفك الطبى',
            'تحاليل · تطعيمات · أعراض'),
      ])),
    ]);

// ═══════════════════════ ٢ · مهامى ═══════════════════════

Widget _task(String title, String when, Color c,
        {bool done = false, String? project}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(done ? Icons.check_circle : Icons.circle_outlined,
            size: 23, color: done ? _green : k.mute),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: done ? k.mute : k.ink,
                    decoration: done ? TextDecoration.lineThrough : null)),
            if (project != null) ...[
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: k.tint(c), borderRadius: BorderRadius.circular(7)),
                child: rdT(project, k,
                    size: 9.5, color: c, w: FontWeight.w800),
              ),
            ],
          ]),
        ),
        rdT(when, k, size: 11, color: k.mute, w: FontWeight.w700),
      ]),
    );

/// **النهاردة بس** — الشاشة تفتح على مهام النهاردة، والباقى ورا زرارين.
Widget tasks1() => rdPhone(k, children: [
      rdTop(k, 'مهامى', badge: 0),
      rdPad(Column(children: [
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('مهام النهاردة', k, size: 12, color: k.mute),
                      const SizedBox(height: 3),
                      rdT('خلّصت 2 من 5', k, size: 21, w: FontWeight.w900),
                    ])),
                rdT('40%', k, size: 22, w: FontWeight.w900, color: _green),
              ]),
              const SizedBox(height: 11),
              _bar(2 / 5, _green, onTint: true),
            ]),
            tint: _green),
        _gap(12),
        rdCard(
            k,
            Column(children: [
              _task('دهان الأوضة', '11:00 م', _amber, project: 'تجهيز الشقة'),
              const Divider(height: 1),
              _task('اتصل بشركة النت', 'أى وقت', _blue),
              const Divider(height: 1),
              _task('راجع الميزانية', '4:00 م', _violet),
              const Divider(height: 1),
              _task('تجديد الباقة', 'خلصت', _blue, done: true),
              const Divider(height: 1),
              _task('اشترى لمبات', 'خلصت', _amber,
                  done: true, project: 'تجهيز الشقة'),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
        _gap(12),
        Row(children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
                color: k.tint(_rose),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _rose.withValues(alpha: 0.25))),
            child: Column(children: [
              rdT('1', k, size: 20, w: FontWeight.w900, color: _rose),
              rdT('فاتت', k, size: 11, color: k.mute),
            ]),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: k.line)),
            child: Column(children: [
              rdT('7', k, size: 20, w: FontWeight.w900),
              rdT('بعدين', k, size: 11, color: k.mute),
            ]),
          )),
        ]),
      ])),
    ], fab: rdFab(k));

/// **ركّز فى 3** — التطبيق بيختارلك تلاتة بس، والباقى مخفى.
Widget tasks2() => rdPhone(k, children: [
      rdTop(k, 'مهامى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdT('لو خلّصت التلاتة دول النهاردة يبقى يوم كويس', k,
            size: 12.5, color: k.mute, maxLines: 2, height: 1.6),
        const SizedBox(height: 14),
        for (final t in const [
          ('دهان الأوضة', 'تجهيز الشقة', '11:00 م', _amber, Icons.format_paint),
          ('راجع الميزانية', 'فلوسى', '4:00 م', _green, Icons.savings_outlined),
          ('اتصل بشركة النت', 'بدون مشروع', 'أى وقت', _blue, Icons.phone_outlined),
        ]) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: k.tint(t.$4),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.$4.withValues(alpha: 0.25))),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(t.$5, size: 21, color: t.$4),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    rdT(t.$1, k, size: 15, w: FontWeight.w800, maxLines: 1),
                    const SizedBox(height: 3),
                    rdT('${t.$2}  ·  ${t.$3}', k,
                        size: 11, color: k.mute, maxLines: 1),
                  ])),
              const Icon(Icons.circle_outlined, size: 25, color: Color(0xFF9AA6B5)),
            ]),
          ),
          const SizedBox(height: 11),
        ],
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: k.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: k.line)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            rdT('باقى المهام', k, size: 13, w: FontWeight.w800),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: k.tint(_blue),
                  borderRadius: BorderRadius.circular(99)),
              child: rdT('8', k, size: 11, color: _blue, w: FontWeight.w900),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_left, size: 18, color: k.mute),
          ]),
        ),
        const SizedBox(height: 18),
        rdSection(k, 'خلّصتها النهاردة', trailing: '2'),
        rdCard(
            k,
            Column(children: [
              _task('تجديد الباقة', '', _blue, done: true),
              const Divider(height: 1),
              _task('اشترى لمبات', '', _amber, done: true),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2)),
      ])),
    ], fab: rdFab(k));

/// **بالمشروع** — المشاريع فوق، وتحتها مهام المشروع المفتوح.
Widget tasks3() => rdPhone(k, children: [
      rdTop(k, 'مهامى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdT('مشاريعك', k, size: 14, w: FontWeight.w800),
        const SizedBox(height: 10),
        Row(children: [
          for (final p in const [
            ('تجهيز الشقة', 3, 7, _amber, Icons.home_outlined),
            ('الشغل', 1, 4, _blue, Icons.work_outline),
          ]) ...[
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(13),
              margin: EdgeInsets.only(left: p.$1 == 'تجهيز الشقة' ? 9 : 0),
              decoration: BoxDecoration(
                  color: k.tint(p.$4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.$4.withValues(alpha: 0.25))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(p.$5, size: 17, color: p.$4),
                    ),
                    const SizedBox(height: 10),
                    rdT(p.$1, k, size: 12.5, w: FontWeight.w800, maxLines: 1),
                    const SizedBox(height: 5),
                    rdT('${p.$2} من ${p.$3}', k, size: 10.5, color: k.mute),
                    const SizedBox(height: 7),
                    _bar(p.$2 / p.$3, p.$4, h: 6, onTint: true),
                  ]),
            )),
          ],
        ]),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: k.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: k.line)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined, size: 17, color: k.mute),
            const SizedBox(width: 7),
            rdT('من غير مشروع', k, size: 12, w: FontWeight.w700),
            const SizedBox(width: 7),
            rdT('2', k, size: 12, color: k.mute, w: FontWeight.w900),
          ]),
        ),
        rdSection(k, 'تجهيز الشقة', trailing: '3 من 7'),
        rdCard(
            k,
            Column(children: [
              _task('دهان الأوضة', '11:00 م', _amber),
              const Divider(height: 1),
              _task('تركيب الستائر', 'الجمعة', _amber),
              const Divider(height: 1),
              _task('شراء سخّان', 'بعدين', _amber),
              const Divider(height: 1),
              _task('اشترى لمبات', '', _amber, done: true),
              const Divider(height: 1),
              _task('قياس الشبابيك', '', _amber, done: true),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      ])),
    ], fab: rdFab(k));

// ═══════════════════════ ٣ · مواعيدى ═══════════════════════

Widget _appt(IconData icon, Color c, String title, String sub, String when,
        {bool faded = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: k.tint(c), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            rdT(title, k,
                size: 13, w: FontWeight.w800, maxLines: 1,
                color: faded ? k.mute : k.ink),
            const SizedBox(height: 2),
            rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
          ]),
        ),
        rdT(when, k, size: 11, color: c, w: FontWeight.w800),
      ]),
    );

/// **اللى جاى** — أقرب موعد كبير قدّامك، والباقى تحته.
Widget appt1() => rdPhone(k, children: [
      rdTop(k, 'مواعيدى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdHero(k,
            icon: Icons.medical_services_outlined,
            kicker: 'أقرب موعد',
            title: 'د. أحمد — أسنان',
            sub: 'عيادة المهندسين',
            big: 'بكرة',
            bigSub: '10:30 ص  ·  فاضل 12 ساعة',
            primary: 'ذكّرنى قبلها',
            primaryIcon: Icons.notifications_active_outlined,
            secondary: 'الطريق',
            colors: const [_blue, _cyan]),
        rdSection(k, 'فات من غير ما تتعمل', trailing: '1'),
        rdCard(
            k,
            _appt(Icons.build_outlined, _rose, 'صيانة العربية', 'عربية',
                'أمس', faded: true),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2)),
        rdSection(k, 'الأسبوع ده', trailing: '3'),
        rdCard(
            k,
            Column(children: [
              _appt(Icons.work_outline, _violet, 'اجتماع الشغل', 'أونلاين',
                  'الجمعة'),
              const Divider(height: 1),
              _appt(Icons.school_outlined, _amber, 'حصة ابنى', 'المدرسة',
                  'السبت'),
              const Divider(height: 1),
              _appt(Icons.cake_outlined, _rose, 'عيد ميلاد ماما', 'البيت',
                  'الأحد'),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      ])),
    ], fab: rdFab(k));

/// **شهر على طول** — تقويم فوق بنقط على الأيام المشغولة.
Widget appt2() => rdPhone(k, children: [
      rdTop(k, 'مواعيدى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Icon(Icons.chevron_right, size: 20, color: k.mute),
                Expanded(
                    child: rdT('أكتوبر 2026', k,
                        size: 14, w: FontWeight.w800, align: TextAlign.center)),
                Icon(Icons.chevron_left, size: 20, color: k.mute),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (final d in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
                  Expanded(
                      child: rdT(d, k,
                          size: 10.5,
                          color: k.mute,
                          w: FontWeight.w800,
                          align: TextAlign.center)),
              ]),
              const SizedBox(height: 6),
              for (var w = 0; w < 5; w++) ...[
                Row(children: [
                  for (var d = 1; d <= 7; d++)
                    Builder(builder: (_) {
                      // 1 أكتوبر 2026 يوم خميس، والصف بيبدأ بالسبت —
                      // فأول 5 خانات فاضية. من غير الإزاحة دى الصورة
                      // بتقول إن أول الشهر سبت وهى كذبة صغيرة بس واضحة.
                      final day = w * 7 + d - 5;
                      final sel = day == 1;
                      final dots = {1: 1, 2: 1, 6: 2, 9: 1, 14: 3, 21: 1};
                      return Expanded(
                        child: Column(children: [
                          Container(
                            height: 30,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: sel
                                ? BoxDecoration(
                                    color: k.accent,
                                    borderRadius: BorderRadius.circular(11))
                                : null,
                            child: rdT(day < 1 || day > 31 ? '' : '$day', k,
                                size: 12,
                                w: FontWeight.w700,
                                color: sel ? Colors.white : k.ink),
                          ),
                          SizedBox(
                            height: 6,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0;
                                      i < (dots[day] ?? 0);
                                      i++) ...[
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                          color: sel ? Colors.white : _blue,
                                          shape: BoxShape.circle),
                                    ),
                                  ]
                                ]),
                          ),
                        ]),
                      );
                    }),
                ]),
              ],
            ])),
        rdSection(k, 'الخميس 1 أكتوبر', trailing: 'موعد واحد'),
        rdCard(
            k,
            _appt(Icons.medical_services_outlined, _blue, 'د. أحمد — أسنان',
                'عيادة المهندسين', '10:30 ص'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2)),
        rdSection(k, 'الجاى بعده'),
        rdCard(
            k,
            Column(children: [
              _appt(Icons.work_outline, _violet, 'اجتماع الشغل', 'أونلاين',
                  '2 أكتوبر'),
              const Divider(height: 1),
              _appt(Icons.cake_outlined, _rose, 'عيد ميلاد ماما', 'البيت',
                  '6 أكتوبر'),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      ])),
    ], fab: rdFab(k));

/// **شريط الأسبوع** — سبع دواير فوق، ومواعيد اليوم تحتها.
Widget appt3() => rdPhone(k, children: [
      rdTop(k, 'مواعيدى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (final d in const [
            ('خ', '1', true, 1),
            ('ج', '2', false, 1),
            ('س', '3', false, 0),
            ('ح', '4', false, 0),
            ('ن', '5', false, 2),
            ('ث', '6', false, 1),
            ('ر', '7', false, 0),
          ])
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: d.$3 ? k.accent : k.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: d.$3 ? k.accent : k.line)),
                child: Column(children: [
                  rdT(d.$1, k,
                      size: 10,
                      color: d.$3 ? Colors.white70 : k.mute,
                      w: FontWeight.w700),
                  const SizedBox(height: 4),
                  rdT(d.$2, k,
                      size: 15,
                      w: FontWeight.w900,
                      color: d.$3 ? Colors.white : k.ink),
                  const SizedBox(height: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: d.$4 == 0
                            ? Colors.transparent
                            : (d.$3 ? Colors.white : _blue),
                        shape: BoxShape.circle),
                  ),
                ]),
              ),
            ),
        ]),
        rdSection(k, 'النهاردة', trailing: 'موعد واحد'),
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Container(
                  width: 3,
                  height: 46,
                  decoration: BoxDecoration(
                      color: _blue, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  rdT('10:30 ص', k, size: 11, color: _blue, w: FontWeight.w800),
                  const SizedBox(height: 3),
                  rdT('د. أحمد — أسنان', k, size: 14, w: FontWeight.w800),
                  const SizedBox(height: 2),
                  rdT('عيادة المهندسين', k, size: 10.5, color: k.mute),
                ]),
              ]),
            ]),
            tint: _blue),
        rdSection(k, 'فات من غير ما تتعمل', trailing: '1'),
        rdCard(
            k,
            _appt(Icons.build_outlined, _rose, 'صيانة العربية', 'عربية', 'أمس',
                faded: true),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2)),
        rdSection(k, 'باقى الأسبوع', trailing: '4'),
        rdCard(
            k,
            Column(children: [
              _appt(Icons.work_outline, _violet, 'اجتماع الشغل', 'أونلاين',
                  'الجمعة'),
              const Divider(height: 1),
              _appt(Icons.school_outlined, _amber, 'حصة ابنى', 'المدرسة',
                  'الاتنين'),
              const Divider(height: 1),
              _appt(Icons.cake_outlined, _rose, 'عيد ميلاد ماما', 'البيت',
                  'التلات'),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      ])),
    ], fab: rdFab(k));

// ═══════════════════════ ٤ · أهدافى ═══════════════════════

/// **الخطوة الجاية** — كل هدف بيقول تعمل إيه بعد كده وفاضل كام.
Widget goals1() => rdPhone(k, children: [
      rdTop(k, 'أهدافى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdChips(k, const ['شغّالة', 'خلصت', 'الكل']),
        const SizedBox(height: 14),
        for (final g in const [
          ('أقرا 12 كتاب', 3, 4, 'ابدأ «الرحيق المختوم»', 'فاضل 92 يوم', _violet,
              Icons.menu_book_outlined),
          ('أوصل 80 كيلو', 1, 2, 'انزل 2 كيلو الشهر ده', 'فاضل 60 يوم', _green,
              Icons.monitor_weight_outlined),
          ('أحفظ جزء عمّ', 0, 0, 'حدّد أول سورة تحفظها', 'من غير خطوات', _amber,
              Icons.mosque_outlined),
        ]) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: k.line)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: k.tint(g.$6),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(g.$7, size: 18, color: g.$6),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                        child: rdT(g.$1, k,
                            size: 14.5, w: FontWeight.w800, maxLines: 1)),
                    rdT(g.$3 == 0 ? '0%' : '${(g.$2 / g.$3 * 100).round()}%', k,
                        size: 15, w: FontWeight.w900, color: g.$6),
                  ]),
                  const SizedBox(height: 11),
                  _bar(g.$3 == 0 ? 0 : g.$2 / g.$3, g.$6),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                        color: k.tint(g.$6),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Icon(Icons.arrow_circle_left_outlined,
                          size: 17, color: g.$6),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            rdT('الخطوة الجاية', k, size: 9.5, color: k.mute),
                            const SizedBox(height: 2),
                            rdT(g.$4, k,
                                size: 12, w: FontWeight.w800, maxLines: 1),
                          ])),
                      rdT(g.$5, k, size: 10, color: k.mute),
                    ]),
                  ),
                ]),
          ),
          const SizedBox(height: 12),
        ],
      ])),
    ], fab: rdFab(k));

/// **هدف واحد قدّامك** — اللى بتركّز فيه كبير، والباقى صغير تحت.
Widget goals2() => rdPhone(k, children: [
      rdTop(k, 'أهدافى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdCard(
            k,
            Column(children: [
              rdT('هدفك الأساسى', k, size: 11.5, color: k.mute),
              const SizedBox(height: 10),
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 13,
                      backgroundColor: k.tint(_violet),
                      valueColor: const AlwaysStoppedAnimation(_violet),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    rdT('9', k, size: 38, w: FontWeight.w900, color: _violet),
                    rdT('من 12 كتاب', k, size: 11, color: k.mute),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              rdT('أقرا 12 كتاب', k, size: 17, w: FontWeight.w900),
              const SizedBox(height: 4),
              rdT('فاضل 92 يوم  ·  كتاب كل 30 يوم', k,
                  size: 11, color: k.mute),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _violet, borderRadius: BorderRadius.circular(15)),
                child: const Text('خلّصت كتاب',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            tint: _violet),
        rdSection(k, 'أهدافك التانية', trailing: '2'),
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_green),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.monitor_weight_outlined,
                      size: 17, color: _green),
                ),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('أوصل 80 كيلو', k, size: 13, w: FontWeight.w800),
                      const SizedBox(height: 5),
                      _bar(0.5, _green, h: 6),
                    ])),
                const SizedBox(width: 10),
                rdT('50%', k, size: 13, w: FontWeight.w900, color: _green),
              ]),
              const Divider(height: 22),
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_amber),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.mosque_outlined,
                      size: 17, color: _amber),
                ),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('أحفظ جزء عمّ', k, size: 13, w: FontWeight.w800),
                      const SizedBox(height: 3),
                      rdT('محتاج تحدّد خطوات', k,
                          size: 10, color: _rose, w: FontWeight.w700),
                    ])),
                const SizedBox(width: 10),
                rdT('0%', k, size: 13, w: FontWeight.w900, color: k.mute),
              ]),
            ])),
      ])),
    ], fab: rdFab(k));

/// **هدف = عادة** — الهدف بيتحقّق بتكرار، فالشاشة بتوريك السلسلة.
Widget goals3() => rdPhone(k, children: [
      rdTop(k, 'أهدافى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdCard(
            k,
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    rdT('3 أهداف شغّالة', k, size: 18, w: FontWeight.w900),
                    const SizedBox(height: 4),
                    rdT('واحد قرّب يخلص · واحد واقف', k,
                        size: 11, color: k.mute),
                  ])),
              Column(children: [
                rdT('42%', k, size: 24, w: FontWeight.w900, color: k.accent),
                rdT('المتوسط', k, size: 10, color: k.mute),
              ]),
            ]),
            tint: _green),
        const SizedBox(height: 14),
        for (final g in const [
          ('أقرا 12 كتاب', '75%', 0.75, _violet, Icons.menu_book_outlined,
              [1, 1, 1, 0, 1, 1, 1]),
          ('أوصل 80 كيلو', '50%', 0.5, _green, Icons.monitor_weight_outlined,
              [1, 0, 1, 1, 0, 0, 1]),
          ('أحفظ جزء عمّ', '0%', 0.0, _amber, Icons.mosque_outlined,
              [0, 0, 0, 0, 0, 0, 0]),
        ]) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: k.line)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: k.tint(g.$4),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(g.$5, size: 17, color: g.$4),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                        child: rdT(g.$1, k,
                            size: 13.5, w: FontWeight.w800, maxLines: 1)),
                    rdT(g.$2, k, size: 14, w: FontWeight.w900, color: g.$4),
                  ]),
                  const SizedBox(height: 11),
                  _bar(g.$3, g.$4, h: 7),
                  const SizedBox(height: 12),
                  Row(children: [
                    rdT('آخر 7 أيام', k, size: 10, color: k.mute),
                    const SizedBox(width: 10),
                    for (final on in g.$6) ...[
                      Container(
                        width: 19,
                        height: 19,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                            color: on == 1 ? g.$4 : k.tint(g.$4),
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ],
                  ]),
                ]),
          ),
          const SizedBox(height: 11),
        ],
      ])),
    ], fab: rdFab(k));

// ═══════════════════════ ٥ · تطوّرى ═══════════════════════

/// **رقم لكل بند** — نفس قاعدة فلوسى: مافيش باب من غير ما يقول اللى وراه.
Widget growth1() => rdPhone(k, height: 900, children: [
      rdTop(k, 'تطوّرى', badge: 0),
      rdPad(Column(children: [
        rdCard(
            k,
            Column(children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: k.tint(_violet),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.auto_awesome,
                      size: 22, color: _violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      rdT('الأسبوع ده', k, size: 12, color: k.mute),
                      const SizedBox(height: 3),
                      rdT('5 من 7 أيام', k, size: 21, w: FontWeight.w900),
                    ])),
                Column(children: [
                  rdT('12', k, size: 22, w: FontWeight.w900, color: _orange),
                  rdT('يوم ورا بعض', k, size: 9.5, color: k.mute),
                ]),
              ]),
              const SizedBox(height: 12),
              _bar(5 / 7, _violet, onTint: true),
            ]),
            tint: _violet),
        _gap(14),
        _btn(Icons.menu_book_outlined, _violet, 'القراءة',
            '«الرحيق المختوم» · صفحة 84',
            big: '3', bigSub: 'كتب السنة دى'),
        _gap(),
        _btn(Icons.school_outlined, _blue, 'التعلّم', 'كورس Flutter · 40%',
            big: '2', bigSub: 'كورس شغّال'),
        _gap(),
        _btn(Icons.repeat, _green, 'عاداتك', 'أطول سلسلة: المشى',
            big: '12', bigSub: 'يوم'),
        _gap(),
        _btn(Icons.flag_outlined, _amber, 'التحديات', 'تحدى الـ30 يوم · يوم 18',
            big: '1', bigSub: 'شغّال'),
        _gap(),
        _btn(Icons.edit_note, _cyan, 'اليوميات', 'آخر تدوينة من 3 أيام',
            big: '28', bigSub: 'تدوينة'),
        _gap(),
        _btn(Icons.smoke_free, _rose, 'عدّاد الإقلاع', 'وفّرت 1,240 جنيه',
            big: '62', bigSub: 'يوم'),
        _gap(),
        _btn(Icons.diversity_3, _teal, 'صلة الرحم', 'محتاج تطمن على 3',
            big: '3', bigSub: 'فاتت'),
        _gap(),
        _btn(Icons.lock_outline, _blue, 'كلمات السر', 'محفوظة على الجهاز',
            big: '19', bigSub: 'كلمة'),
      ])),
    ]);

/// **سلسلة الأيام** — التطوّر تراكم، فالسلسلة هى البطل.
Widget growth2() => rdPhone(k, height: 900, children: [
      rdTop(k, 'تطوّرى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdHero(k,
            icon: Icons.local_fire_department_outlined,
            kicker: 'سلسلتك',
            title: '12 يوم ورا بعض',
            sub: 'أطول سلسلة عملتها: 19 يوم',
            big: '5',
            bigSub: 'من 7 أيام الأسبوع ده',
            primary: 'سجّل النهاردة',
            primaryIcon: Icons.add,
            secondary: 'التفاصيل',
            colors: const [_orange, _amber]),
        rdSection(k, 'آخر 4 أسابيع'),
        rdCard(
            k,
            Column(children: [
              for (final wk in const [
                [1, 1, 1, 0, 1, 1, 1],
                [1, 1, 0, 1, 1, 1, 0],
                [0, 1, 1, 1, 0, 1, 1],
                [1, 1, 1, 1, 1, 0, 0],
              ]) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    for (final on in wk)
                      Expanded(
                        child: Container(
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: on == 1 ? _green : k.tint(_green),
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ]),
                ),
              ],
            ])),
        rdSection(k, 'اللى بيبنى السلسلة'),
        _btn(Icons.repeat, _green, 'عاداتك', 'المشى · القراءة · المياه',
            big: '3'),
        _gap(),
        _btn(Icons.menu_book_outlined, _violet, 'القراءة', 'صفحة 84', big: '3'),
        _gap(),
        _btn(Icons.school_outlined, _blue, 'التعلّم', 'Flutter · 40%', big: '2'),
        _gap(),
        _btn(Icons.flag_outlined, _amber, 'التحديات', 'يوم 18 من 30', big: '1'),
        _gap(),
        _btn(Icons.edit_note, _cyan, 'اليوميات', 'آخر تدوينة من 3 أيام',
            big: '28'),
      ])),
    ]);

/// **مقسوم لمجموعات** — بنود التطوّر مش نوع واحد، فتتقسم.
Widget growth3() => rdPhone(k, height: 900, children: [
      rdTop(k, 'تطوّرى', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdSection(k, 'بتتعلّم', trailing: 'شغّال دلوقتى'),
        Row(children: [
          Expanded(
              child: rdTile(k, Icons.menu_book_outlined, 'القراءة', _violet,
                  value: '3 كتب')),
          const SizedBox(width: 10),
          Expanded(
              child: rdTile(k, Icons.school_outlined, 'التعلّم', _blue,
                  value: '2 كورس')),
        ]),
        rdSection(k, 'بتبنى نفسك'),
        Row(children: [
          Expanded(
              child: rdTile(k, Icons.repeat, 'عاداتك', _green,
                  value: '12 يوم')),
          const SizedBox(width: 10),
          Expanded(
              child: rdTile(k, Icons.flag_outlined, 'التحديات', _amber,
                  value: 'يوم 18')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: rdTile(k, Icons.smoke_free, 'الإقلاع', _rose,
                  value: '62 يوم')),
          const SizedBox(width: 10),
          Expanded(
              child: rdTile(k, Icons.edit_note, 'اليوميات', _cyan,
                  value: '28 تدوينة')),
        ]),
        rdSection(k, 'ناسك وحاجاتك'),
        _btn(Icons.diversity_3, _teal, 'صلة الرحم', 'محتاج تطمن على 3',
            big: '3', bigSub: 'فاتت', bigColor: _rose),
        _gap(),
        _btn(Icons.lock_outline, _blue, 'كلمات السر', 'محفوظة على الجهاز',
            big: '19'),
      ])),
    ]);

// ═══════════════════════════ الرسم ═══════════════════════════

Future<void> _three(
  WidgetTester tester,
  String name,
  List<(String, String, Widget)> options, {
  double height = 890,
}) =>
    shot(
      tester,
      name,
      shotApp(rdTheme(k), rdTriptych(options)),
      size: Size(1152, height),
      pixelRatio: 2,
    );

void main() {
  testWidgets('أفكار باقى البنود', (tester) async {
    await loadShotFonts();

    await _three(tester, 'nx_1_health', [
      ('صحتك النهاردة', 'زى فلوسى · كل زرار بيقول رقمه', health1()),
      ('درجة صحتك', 'رقم واحد يلخّص · واللى رفعه ونزّله', health2()),
      ('لازم النهاردة · أرقامك', 'قسمين واضحين', health3()),
    ], height: 1080);

    await _three(tester, 'nx_2_tasks', [
      ('النهاردة بس', 'مهام اليوم قدّامك · الباقى ورا زرار', tasks1()),
      ('ركّز فى 3', 'تلاتة بس تخلّصهم · والباقى مخفى', tasks2()),
      ('بالمشروع', 'كروت المشاريع فوق · ومهامها تحت', tasks3()),
    ], height: 900);

    await _three(tester, 'nx_3_appointments', [
      ('اللى جاى', 'أقرب موعد كبير · والباقى مجموعات', appt1()),
      ('شهر على طول', 'تقويم بنقط · ومواعيد اليوم', appt2()),
      ('شريط الأسبوع', '7 أيام فوق · ومواعيد اليوم', appt3()),
    ], height: 900);

    await _three(tester, 'nx_4_goals', [
      ('الخطوة الجاية', 'كل هدف بيقول تعمل إيه بعد كده', goals1()),
      ('هدف واحد قدّامك', 'اللى بتركّز فيه كبير', goals2()),
      ('هدف = عادة', 'السلسلة هى اللى بتوصّلك', goals3()),
    ], height: 900);

    await _three(tester, 'nx_5_growth', [
      ('رقم لكل بند', 'زى فلوسى · مافيش باب أعمى', growth1()),
      ('سلسلة الأيام', 'التراكم هو البطل', growth2()),
      ('مقسوم لمجموعات', 'بتتعلّم · بتبنى نفسك · ناسك', growth3()),
    ], height: 1030);
  });
}
