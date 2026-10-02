// أشكال «خط اليوم»: الزرار فى الرئيسية + الصفحة اللى بيفتحها.
//
// الصفحة موجودة أصلاً (`DayFullScreen`) بس مرتّبة **بالمجموعات**
// (فاتك/الجاى/خلصت) — يعنى دوا الساعة ٨ اللى اتاخد بينزل تحت خالص تحت
// «خلصت»، فالترتيب اللى بتشوفه مش ترتيب الساعة. الأشكال هنا بتجرّب
// الترتيب الزمنى الحقيقى وبدايله.
//
//   flutter test tool/nx_dayline_test.dart
//   → build/design_shots/nx_6_dayline.png · nx_7_daybtn.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _green = Color(0xFF10B981);
const _rose = Color(0xFFF43F5E);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);
const _violet = Color(0xFF8B5CF6);

/// بند واحد فى اليوم: (الوقت، الاسم، النوع، اللون، الأيقونة، خلص؟)
typedef Ev = (String, String, String, Color, IconData, bool);

const _day = <Ev>[
  ('5:23 ص', 'الفجر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('8:00 ص', 'كونكور 5', 'دوا', _rose, Icons.medication_outlined, true),
  ('10:30 ص', 'د. أحمد — أسنان', 'موعد', _blue, Icons.medical_services_outlined, true),
  ('12:00 م', 'xarelto 20mg', 'دوا', _rose, Icons.medication_outlined, false),
  ('12:46 م', 'الضهر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('4:08 م', 'العصر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('5:00 م', 'دهان الأوضة', 'مهمة', _amber, Icons.checklist_rtl, false),
  ('6:40 م', 'المغرب', 'صلاة', _green, Icons.mosque_outlined, false),
  ('7:57 م', 'العشا', 'صلاة', _green, Icons.mosque_outlined, false),
];

/// دلوقتى الساعة ١٢:٣٠ — اللى قبلها فات، واللى بعدها جاى.
const _nowAfter = 3; // بعد «xarelto 12:00»

bool _missed(int i) => i < _nowAfter && !_day[i].$6;

Widget _bar(double v, Color c, {bool onTint = false, double h = 8}) => ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: v,
        minHeight: h,
        backgroundColor: onTint ? Colors.white : k.tint(c),
        valueColor: AlwaysStoppedAnimation(c),
      ),
    );

/// دايرة الحالة: خلص · فات · لسه.
Widget _mark(bool done, bool missed) => Icon(
      done
          ? Icons.check_circle
          : missed
              ? Icons.error_outline
              : Icons.circle_outlined,
      size: 22,
      color: done ? _green : (missed ? _rose : const Color(0xFF9AA6B5)),
    );

// ═══════════════ ١ · خط زمنى بالساعة ═══════════════

/// كل اليوم بترتيب الساعة، من غير ما البنود تتفرز لمجموعات.
///
/// الفرق المهم: الدوا اللى اتاخد الساعة ٨ بيفضل **مكانه** فى الصبح، مش
/// بينزل آخر الصفحة تحت «خلصت». الورقة بتتقرا زى يومك ما حصل بالظبط.
Widget line1() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'خط اليوم', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdCard(
            k,
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      rdT('2 من 9 خلصوا', k, size: 17, w: FontWeight.w900),
                      const SizedBox(height: 8),
                      _bar(2 / 9, _green, onTint: true),
                    ]),
              ),
              const SizedBox(width: 12),
              Column(children: [
                rdT('2', k, size: 19, w: FontWeight.w900, color: _rose),
                rdT('فاتوا', k, size: 9.5, color: k.mute),
              ]),
            ]),
            tint: _green),
        const SizedBox(height: 14),
        for (var i = 0; i < _day.length; i++) ...[
          // علامة «دلوقتى» بين اللى فات واللى جاى — عشان تعرف انت فين
          // من غير ما تحسب.
          if (i == _nowAfter) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: k.accent,
                      borderRadius: BorderRadius.circular(99)),
                  child: rdT('دلوقتى 12:30 م', k,
                      size: 10, w: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Container(height: 1.4, color: k.accent)),
              ]),
            ),
          ],
          Row(children: [
            SizedBox(
              width: 58,
              child: rdT(_day[i].$1, k,
                  size: 11,
                  w: FontWeight.w800,
                  color: _missed(i) ? _rose : k.mute,
                  align: TextAlign.center),
            ),
            // الخط الرأسى اللى بيربط اليوم ببعضه.
            SizedBox(
              width: 22,
              child: Column(children: [
                Container(
                    width: 2,
                    height: 12,
                    color: i == 0 ? Colors.transparent : k.line),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _day[i].$6
                        ? _green
                        : _missed(i)
                            ? _rose
                            : k.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _day[i].$6
                            ? _green
                            : _missed(i)
                                ? _rose
                                : k.line,
                        width: 2),
                  ),
                ),
                Container(
                    width: 2,
                    height: 26,
                    color: i == _day.length - 1 ? Colors.transparent : k.line),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: k.line),
                  ),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: k.tint(_day[i].$4),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(_day[i].$5, size: 15, color: _day[i].$4),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_day[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _day[i].$6 ? k.mute : k.ink,
                                    decoration: _day[i].$6
                                        ? TextDecoration.lineThrough
                                        : null)),
                            rdT(_day[i].$3, k, size: 9.5, color: k.mute),
                          ]),
                    ),
                    _mark(_day[i].$6, _missed(i)),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ])),
    ]);

// ═══════════════ ٢ · مجموعات (الشكل الحالى) ═══════════════

Widget _row2(int i) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: k.tint(_day[i].$4),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_day[i].$5, size: 17, color: _day[i].$4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_day[i].$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _day[i].$6 ? k.mute : k.ink,
                    decoration:
                        _day[i].$6 ? TextDecoration.lineThrough : null)),
            rdT(_day[i].$3, k, size: 10, color: k.mute),
          ]),
        ),
        rdT(_day[i].$1, k,
            size: 11,
            w: FontWeight.w700,
            color: _missed(i) ? _rose : k.mute),
        const SizedBox(width: 8),
        _mark(_day[i].$6, _missed(i)),
      ]),
    );

Widget line2() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'خط اليوم', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdCard(
            k,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT('2 من 9 خلصوا', k, size: 17, w: FontWeight.w900),
              const SizedBox(height: 8),
              _bar(2 / 9, _green, onTint: true),
            ]),
            tint: _green),
        rdSection(k, 'فاتك', trailing: '2'),
        rdCard(
            k,
            Column(children: [
              for (var i = 0; i < _day.length; i++)
                if (_missed(i)) _row2(i),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
        rdSection(k, 'الجاى', trailing: '5'),
        rdCard(
            k,
            Column(children: [
              for (var i = 0; i < _day.length; i++)
                if (i >= _nowAfter && !_day[i].$6) _row2(i),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
        rdSection(k, 'خلصت', trailing: '2'),
        rdCard(
            k,
            Column(children: [
              for (var i = 0; i < _day.length; i++)
                if (_day[i].$6) _row2(i),
            ]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
      ])),
    ]);

// ═══════════════ ٣ · فترات اليوم ═══════════════

/// نفس الترتيب الزمنى بس مقسوم على فترات اليوم (صبح · ضهر · مغرب).
/// الفايدة: بتشوف الفترة اللى جاية كوحدة واحدة، والفترة اللى فاتت
/// بتتقفل وراك.
Widget line3() => rdPhone(k, height: 1000, children: [
      rdTop(k, 'خط اليوم', back: true, badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (final p in const [
            ('الصبح', 3, 2, _amber, Icons.wb_twilight),
            ('الضهر', 3, 0, _blue, Icons.wb_sunny_outlined),
            ('بالليل', 3, 0, _violet, Icons.nights_stay_outlined),
          ]) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    color: k.tint(p.$4),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: p.$4.withValues(alpha: 0.25))),
                child: Column(children: [
                  Icon(p.$5, size: 17, color: p.$4),
                  const SizedBox(height: 5),
                  rdT(p.$1, k, size: 11.5, w: FontWeight.w800),
                  const SizedBox(height: 2),
                  rdT('${p.$3} من ${p.$2}', k, size: 10, color: k.mute),
                ]),
              ),
            ),
          ],
        ]),
        rdSection(k, 'الصبح', trailing: '2 من 3'),
        rdCard(
            k,
            Column(children: [for (final i in [0, 1, 2]) _row2(i)]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
        rdSection(k, 'الضهر والعصر', trailing: '0 من 3'),
        rdCard(
            k,
            Column(children: [for (final i in [3, 4, 5]) _row2(i)]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
        rdSection(k, 'بالليل', trailing: '0 من 3'),
        rdCard(
            k,
            Column(children: [for (final i in [6, 7, 8]) _row2(i)]),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2)),
      ])),
    ]);

// ═══════════════ أشكال الزرار فى الرئيسية ═══════════════

Widget _homeTop() => Column(children: [
      rdTop(k, 'الرئيسية', badge: 0),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdT('مساء الخير', k, size: 19, w: FontWeight.w900, color: k.accent),
        const SizedBox(height: 2),
        rdT('الجمعة 2 أكتوبر 2026', k, size: 11.5, color: k.mute),
        const SizedBox(height: 14),
      ])),
    ]);

/// أ · زرار عريض بيقول أرقامه — نفس قاعدة «فلوسى».
Widget btn1() => rdPhone(k, height: 560, children: [
      _homeTop(),
      rdPad(Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: k.line),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: k.tint(k.accent),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.timeline, size: 20, color: k.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rdT('خط اليوم', k, size: 13.5, w: FontWeight.w800),
                    const SizedBox(height: 2),
                    rdT('2 فاتوا · 5 لسه جايين', k,
                        size: 10.5, color: k.mute),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              rdT('2/9', k, size: 17, w: FontWeight.w900, color: _green),
              rdT('خلصوا', k, size: 9.5, color: k.mute),
            ]),
            Icon(Icons.chevron_left, size: 19, color: k.mute),
          ]),
        ),
        const SizedBox(height: 11),
        rdCard(
            k,
            Row(children: [
              Icon(Icons.mosque_outlined, size: 18, color: _green),
              const SizedBox(width: 9),
              Expanded(
                  child: rdT('الضهر · 12:46 م', k,
                      size: 12.5, w: FontWeight.w700)),
              rdT('الجاى دلوقتى', k, size: 10, color: k.mute),
            ])),
      ])),
    ]);

/// ب · شريط الإنجاز نفسه يبقى **زرار** (الشكل الحالى بس كله يتداس).
Widget btn2() => rdPhone(k, height: 560, children: [
      _homeTop(),
      rdPad(Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 13, 14),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: k.line),
          ),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: rdT('إنجاز اليوم · 2 من 9', k,
                      size: 12.5, w: FontWeight.w800)),
              rdT('22%', k, size: 13, w: FontWeight.w900, color: _green),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left, size: 18, color: k.mute),
            ]),
            const SizedBox(height: 10),
            _bar(2 / 9, _green),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.timeline, size: 14, color: k.accent),
              const SizedBox(width: 6),
              rdT('دوس تشوف خط اليوم كله', k,
                  size: 10.5, color: k.accent, w: FontWeight.w700),
            ]),
          ]),
        ),
      ])),
    ]);

/// ج · تلات أرقام — كل رقم بيفتح الصفحة على اللى هو عايزه.
Widget btn3() => rdPhone(k, height: 560, children: [
      _homeTop(),
      rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: rdT('خط اليوم', k, size: 14, w: FontWeight.w800)),
          rdT('اليوم كله ›', k,
              size: 11, color: k.accent, w: FontWeight.w800),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final c in const [
            ('2', 'فاتوا', _rose, Icons.error_outline),
            ('5', 'جايين', _blue, Icons.schedule),
            ('2', 'خلصوا', _green, Icons.check_circle_outline),
          ]) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 9),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                    color: k.tint(c.$3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.$3.withValues(alpha: 0.25))),
                child: Column(children: [
                  Icon(c.$4, size: 17, color: c.$3),
                  const SizedBox(height: 6),
                  rdT(c.$1, k, size: 20, w: FontWeight.w900, color: c.$3),
                  rdT(c.$2, k, size: 10, color: k.mute),
                ]),
              ),
            ),
          ],
        ]),
      ])),
    ]);

// ═══════════════ الرسم ═══════════════

Future<void> _three(WidgetTester tester, String name,
        List<(String, String, Widget)> opts, double h) =>
    shot(tester, name, shotApp(rdTheme(k), rdTriptych(opts)),
        size: Size(1152, h), pixelRatio: 2);

void main() {
  testWidgets('خط اليوم — الصفحة والزرار', (tester) async {
    await loadShotFonts();

    await _three(tester, 'nx_6_dayline', [
      ('بترتيب الساعة', 'يومك كما حصل · الخلص مايتشالش من مكانه', line1()),
      ('مجموعات', 'فاتك · الجاى · خلصت (الشكل الحالى)', line2()),
      ('فترات اليوم', 'الصبح · الضهر · بالليل', line3()),
    ], 1130);

    await _three(tester, 'nx_7_daybtn', [
      ('زرار بأرقامه', 'زى أزرار فلوسى', btn1()),
      ('شريط الإنجاز يتداس', 'اللى موجود بس كله زرار', btn2()),
      ('تلات أرقام', 'كل رقم بيفتح على نوعه', btn3()),
    ], 690);
  });
}
