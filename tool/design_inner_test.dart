// معاينة شكل **الشاشات الداخلية** فى «فلوسى» (المصاريف · الدخل ·
// الثابت) — ٣ طرق مختلفة فعلاً. المصاريف هى المثال لإنها أزحم شاشة،
// والشكل اللى تختاره بينطبق على الدخل والفواتير زيّه بزيّه.
//   flutter test tool/design_inner_test.dart → build/design_shots/inner_*.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'shot_harness.dart';

const _bg = Color(0xFFF4F6FA);
const _ink = Color(0xFF0F172A);
const _mute = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _red = Color(0xFFDC2626);
const _blue = Color(0xFF2563EB);
const _green = Color(0xFF16A34A);

ThemeData _theme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: _bg,
      colorScheme: ColorScheme.fromSeed(seedColor: _blue),
    );

Text _t(String s,
        {double size = 13,
        Color color = _ink,
        FontWeight w = FontWeight.w600,
        TextAlign? align}) =>
    Text(s,
        textAlign: align,
        style: TextStyle(fontSize: size, color: color, fontWeight: w));

Widget _card(Widget child, {EdgeInsets? pad}) => Container(
      width: double.infinity,
      padding: pad ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: child,
    );

PreferredSizeWidget _bar(String title) => AppBar(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      title: _t(title, size: 18, w: FontWeight.w800),
      leading: const Icon(Icons.arrow_forward, color: _ink),
    );

const _cats = [
  ('أكل', Icons.restaurant, Color(0xFFF59E0B), 1289, 24),
  ('مواصلات', Icons.directions_bus, Color(0xFF0EA5E9), 894, 17),
  ('تسوق', Icons.shopping_bag_outlined, Color(0xFFA855F7), 746, 14),
  ('فواتير', Icons.receipt_long_outlined, Color(0xFFEF4444), 450, 8),
  ('صحة', Icons.medical_services_outlined, Color(0xFF14B8A6), 598, 11),
];

Widget _tx(String title, String sub, String amount, Color c, IconData i) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(i, size: 17, color: c),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(title, size: 13.5),
            const SizedBox(height: 2),
            _t(sub, size: 11, color: _mute, w: FontWeight.w500),
          ]),
        ),
        _t(amount, size: 14, w: FontWeight.w800),
      ]),
    );

// ————————————————————————————————————————————————————————————
// ١ — «رقم واحد + فلاتر»: الإجمالى فوق، شرائح للفئات، وقايمة واحدة.
// مفيش كروت تحليل جوّه الشاشة — التحليل ليه بنده.
// ————————————————————————————————————————————————————————————
Widget _one() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar('المصاريف'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _t('صرفت الشهر ده', size: 12, color: _mute),
                _t('2800 ج.م', size: 30, w: FontWeight.w900, color: _red),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999)),
              child: _t('الميزانية 9000', size: 12, color: _blue),
            ),
          ]),
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in [
                ('الكل', true),
                ('أكل', false),
                ('مواصلات', false),
                ('تسوق', false),
                ('فواتير', false),
              ])
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: f.$2 ? _ink : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: f.$2 ? _ink : _line),
                  ),
                  child: _t(f.$1,
                      size: 12, color: f.$2 ? Colors.white : _mute),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _card(Column(children: [
                _tx('نت اورنج', 'فواتير • 28 سبتمبر', '1500 ج.م',
                    const Color(0xFFEF4444), Icons.receipt_long_outlined),
                const Divider(height: 1, color: _line),
                _tx('vodafone', 'فواتير • 28 سبتمبر', '1300 ج.م',
                    const Color(0xFFEF4444), Icons.receipt_long_outlined),
                const Divider(height: 1, color: _line),
                _tx('سوبر ماركت', 'أكل • 27 سبتمبر', '220 ج.م',
                    const Color(0xFFF59E0B), Icons.restaurant),
                const Divider(height: 1, color: _line),
                _tx('أوبر', 'مواصلات • 27 سبتمبر', '77 ج.م',
                    const Color(0xFF0EA5E9), Icons.directions_bus),
              ])),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('سجل مصروف', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

// ————————————————————————————————————————————————————————————
// ٢ — «الفئات أولاً»: بتشوف راح فين من نظرة، وتدوس على فئة تشوف
// عملياتها. أقل حاجات على الشاشة الواحدة.
// ————————————————————————————————————————————————————————————
Widget _two() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar('المصاريف'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _card(Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _t('صرفت الشهر ده', size: 12, color: _mute),
                _t('2800 ج.م', size: 26, w: FontWeight.w900, color: _red),
              ]),
            ),
            SizedBox(
              width: 92,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _t('من 9000', size: 11.5, color: _mute, w: FontWeight.w500),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                      value: 0.31, minHeight: 7, color: _blue),
                ),
              ]),
            ),
          ])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _t('راحت فين؟', size: 14)),
            _t('كل العمليات ›', size: 12.5, color: _blue),
          ]),
          const SizedBox(height: 8),
          for (final c in _cats)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _card(
                pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: c.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(c.$2, size: 19, color: c.$3),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: _t(c.$1, size: 13.5)),
                            _t('${c.$4} ج.م', size: 13.5, w: FontWeight.w800),
                          ]),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                                value: c.$5 / 30,
                                minHeight: 6,
                                color: c.$3,
                                backgroundColor: c.$3.withValues(alpha: 0.13)),
                          ),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  _t('${c.$5}٪', size: 12, color: _mute, w: FontWeight.w700),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('سجل مصروف', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

// ————————————————————————————————————————————————————————————
// ٣ — «باليوم»: العمليات متجمّعة تحت كل يوم بمجموعه. أقرب لطريقة
// تفكيرك («صرفت كام النهاردة؟») وبتلاقى العملية بسرعة.
// ————————————————————————————————————————————————————————————
Widget _dayHead(String day, String sum) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(children: [
        Expanded(child: _t(day, size: 12.5, color: _mute, w: FontWeight.w700)),
        _t(sum, size: 12.5, color: _red, w: FontWeight.w800),
      ]),
    );

Widget _three() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar('المصاريف'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Expanded(child: _t('صرفت الشهر ده', size: 13, color: _mute)),
              _t('2800 ج.م', size: 19, w: FontWeight.w900, color: _red),
            ]),
          ),
          _dayHead('النهاردة • 28 سبتمبر', '−2800'),
          _card(Column(children: [
            _tx('نت اورنج', 'فواتير', '1500 ج.م', const Color(0xFFEF4444),
                Icons.receipt_long_outlined),
            const Divider(height: 1, color: _line),
            _tx('vodafone', 'فواتير', '1300 ج.م', const Color(0xFFEF4444),
                Icons.receipt_long_outlined),
          ])),
          _dayHead('امبارح • 27 سبتمبر', '−297'),
          _card(Column(children: [
            _tx('سوبر ماركت', 'أكل', '220 ج.م', const Color(0xFFF59E0B),
                Icons.restaurant),
            const Divider(height: 1, color: _line),
            _tx('أوبر', 'مواصلات', '77 ج.م', const Color(0xFF0EA5E9),
                Icons.directions_bus),
          ])),
          _dayHead('25 سبتمبر', '−151'),
          _card(Column(children: [
            _tx('صيدلية', 'صحة', '151 ج.م', const Color(0xFF14B8A6),
                Icons.medical_services_outlined),
          ])),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('سجل مصروف', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadShotFonts();
  });

  testWidgets('١ — رقم واحد + فلاتر', (t) async {
    await shot(t, 'inner_1', shotApp(_theme(), _one()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('٢ — الفئات أولاً', (t) async {
    await shot(t, 'inner_2', shotApp(_theme(), _two()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('٣ — باليوم', (t) async {
    await shot(t, 'inner_3', shotApp(_theme(), _three()),
        size: const Size(390, 844), pixelRatio: 2);
  });
}
