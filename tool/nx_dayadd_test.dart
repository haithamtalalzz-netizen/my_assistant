// أشكال زرار «＋ إضافة» فى صفحة «خط اليوم».
//
// اللى ينفع يتضاف على الخط **تلاتة** بس: موعد · مهمة · دوا.
// الصلوات محسوبة من مدينتك مش مضافة، فمالهاش «＋».
//
//   flutter test tool/nx_dayadd_test.dart → build/design_shots/nx_8_dayadd.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = rdFriendly;

const _green = Color(0xFF10B981);
const _rose = Color(0xFFF43F5E);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);

/// (الوقت، الاسم، النوع، اللون، الأيقونة، خلص؟)
const _day = [
  ('5:23 ص', 'الفجر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('8:00 ص', 'كونكور 5', 'دوا', _rose, Icons.medication_outlined, true),
  ('12:00 م', 'xarelto 20mg', 'دوا', _rose, Icons.medication_outlined, false),
  ('12:46 م', 'الضهر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('4:08 م', 'العصر', 'صلاة', _green, Icons.mosque_outlined, false),
  ('5:00 م', 'دهان الأوضة', 'مهمة', _amber, Icons.checklist_rtl, false),
];

const _nowAfter = 3;

bool _missed(int i) => i < _nowAfter && !_day[i].$6;

/// نفس سطر الخط الزمنى اللى اتنفّذ فعلاً.
Widget _row(int i) => IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: rdT(_day[i].$1, k,
                size: 10.5,
                w: FontWeight.w800,
                color: _missed(i) ? _rose : k.mute,
                align: TextAlign.center),
          ),
        ),
        SizedBox(
          width: 18,
          child: Column(children: [
            Container(
                width: 2,
                height: 13,
                color: i == 0 ? Colors.transparent : k.line),
            Container(
              width: 10,
              height: 10,
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
            Expanded(child: Container(width: 2, color: k.line)),
          ]),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: k.line),
              ),
              child: Row(children: [
                Container(
                  width: 29,
                  height: 29,
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
                Icon(
                    _day[i].$6
                        ? Icons.check_circle
                        : _missed(i)
                            ? Icons.error_outline
                            : Icons.circle_outlined,
                    size: 20,
                    color: _day[i].$6
                        ? _green
                        : _missed(i)
                            ? _rose
                            : const Color(0xFF9AA6B5)),
              ]),
            ),
          ),
        ),
      ]),
    );

Widget _timeline({Widget? extra}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rdTop(k, 'خط اليوم', back: true, badge: 0),
        rdPad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          rdCard(
              k,
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rdT('1 من 6 خلصوا', k, size: 16, w: FontWeight.w900),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                              value: 1 / 6,
                              minHeight: 8,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation(_green)),
                        ),
                      ]),
                ),
                const SizedBox(width: 12),
                Column(children: [
                  rdT('2', k, size: 18, w: FontWeight.w900, color: _rose),
                  rdT('فاتوا', k, size: 9, color: k.mute),
                ]),
              ]),
              tint: _green),
          const SizedBox(height: 12),
          for (var i = 0; i < _day.length; i++) ...[
            if (i == _nowAfter)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: k.accent,
                        borderRadius: BorderRadius.circular(99)),
                    child: rdT('دلوقتى 12:30 م', k,
                        size: 9.5, w: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Container(height: 1.4, color: k.accent)),
                ]),
              ),
            _row(i),
          ],
          ?extra,
        ])),
      ],
    );

/// صفّ اختيار: أيقونة ملوّنة + اسم + وصف قصير.
Widget _pick(IconData icon, Color c, String title, String sub) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: k.tint(c), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 21, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            rdT(title, k, size: 14, w: FontWeight.w800),
            const SizedBox(height: 2),
            rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
          ]),
        ),
        Icon(Icons.chevron_left, size: 19, color: k.mute),
      ]),
    );

// ═══════════ ١ · ورقة «تضيف إيه؟» ═══════════

/// زرار واحد، ودوسة تانية تختار النوع.
/// الخط مابيتلخبطش بأزرار، والورقة فيها مكان لوصف كل نوع.
Widget add1() => rdPhone(k, height: 820, children: [
      // ارتفاع ثابت للمسرح: من غيره الـStack بياخد طول العمود جوّاه
      // فالورقة اللى `bottom: 0` بتنزل تحت حدّ الموبايل وتتقصّ.
      SizedBox(
        height: 790,
        child: Stack(children: [
          ClipRect(child: _timeline()),
        // الورقة السفلية مفتوحة
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            decoration: BoxDecoration(
              color: k.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, -6))
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: k.line, borderRadius: BorderRadius.circular(99)),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: rdT('تضيف إيه لليوم؟', k, size: 16, w: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              _pick(Icons.event, _blue, 'موعد', 'دكتور · شغل · مشوار'),
              _pick(Icons.checklist_rtl, _amber, 'مهمة', 'حاجة لازم تتعمل'),
              _pick(Icons.medication_outlined, _rose, 'دوا', 'جرعة بوقتها'),
            ]),
          ),
        ),
      ]),
      ),
    ]);

// ═══════════ ٢ · مروحة ═══════════

Widget _mini(IconData icon, Color c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Icon(icon, size: 21, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
              color: k.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: k.line)),
          child: rdT(label, k, size: 12, w: FontWeight.w800),
        ),
      ]),
    );

/// الزرار بيفتح تلات أزرار صغيّرة فوقه — من غير ما تغطّى الشاشة.
Widget add2() => rdPhone(k, height: 820, children: [
      SizedBox(
        height: 790,
        child: Stack(children: [
        ClipRect(child: _timeline()),
        // الستارة المعتمة جزء من الفكرة مش زينة: من غيرها الأزرار
        // بتتلخبط مع القايمة اللى وراها وماتعرفش انت فى أى وضع.
        Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35))),
        Positioned(
          left: 16,
          bottom: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _mini(Icons.medication_outlined, _rose, 'دوا'),
            _mini(Icons.checklist_rtl, _amber, 'مهمة'),
            _mini(Icons.event, _blue, 'موعد'),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [k.accent, k.accent2]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: k.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 7))
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 26),
            ),
          ]),
        ),
      ]),
      ),
    ]);

// ═══════════ ٣ · تلات أزرار دايمة ═══════════

/// من غير دوسة زيادة: التلاتة قدّامك على طول تحت الخط.
Widget add3() => rdPhone(k, height: 820, children: [
      _timeline(
        extra: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Row(children: [
            for (final b in const [
              ('موعد', _blue, Icons.event),
              ('مهمة', _amber, Icons.checklist_rtl),
              ('دوا', _rose, Icons.medication_outlined),
            ]) ...[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: k.tint(b.$2),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: b.$2.withValues(alpha: 0.3))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, size: 15, color: b.$2),
                      const SizedBox(width: 3),
                      Icon(b.$3, size: 15, color: b.$2),
                    ]),
                    const SizedBox(height: 5),
                    rdT(b.$1, k, size: 12, w: FontWeight.w800, color: b.$2),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    ]);

void main() {
  testWidgets('زرار الإضافة فى خط اليوم', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'nx_8_dayadd',
      shotApp(
          rdTheme(k),
          rdTriptych([
            ('ورقة «تضيف إيه؟»', 'زرار واحد · ودوسة تختار النوع', add1()),
            ('مروحة', 'تلات أزرار بتطلع فوق الزرار', add2()),
            ('تلاتة دايمة', 'قدّامك على طول · من غير دوسة زيادة', add3()),
          ])),
      size: const Size(1152, 950),
      pixelRatio: 2,
    );
  });
}
