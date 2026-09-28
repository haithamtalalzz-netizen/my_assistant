// معاينة تصميمات «فلوسى» — 3 أشكال مختلفة **فعلاً** (مش نفس الهيكل بألوان).
// بترسم Flutter حقيقى بخط التطبيق عشان الصورة تبقى صادقة.
//   flutter test tool/design_money_test.dart   →  build/design_shots/money_*.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'shot_harness.dart';

const _bg = Color(0xFFF4F6FA);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFDC2626);
const _ink = Color(0xFF0F172A);
const _mute = Color(0xFF64748B);
const _blue = Color(0xFF2563EB);
const _line = Color(0xFFE2E8F0);

ThemeData _theme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: _bg,
      colorScheme: ColorScheme.fromSeed(seedColor: _blue),
    );

Widget _card(Widget child, {EdgeInsets? pad, Color? color}) => Container(
      width: double.infinity,
      padding: pad ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: child,
    );

Text _t(String s,
        {double size = 13,
        Color color = _ink,
        FontWeight w = FontWeight.w600,
        TextAlign? align}) =>
    Text(s,
        textAlign: align,
        style: TextStyle(fontSize: size, color: color, fontWeight: w));

/// صفّ عملية واحدة: أيقونة + اسم + وقت + مبلغ.
Widget _tx(String title, String sub, String amount, bool income,
        {IconData icon = Icons.receipt_long_outlined}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: (income ? _green : _red).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(income ? Icons.south_west : icon,
              size: 17, color: income ? _green : _red),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(title, size: 13.5),
            const SizedBox(height: 2),
            _t(sub, size: 11, color: _mute, w: FontWeight.w500),
          ]),
        ),
        _t(amount,
            size: 14,
            w: FontWeight.w800,
            color: income ? _green : _ink),
      ]),
    );

// ————————————————————————————————————————————————————————————
// تصميم أ — «رقم واحد + تبويبات»
// الفكرة: سؤال واحد فوق («أصرف كام النهاردة؟») وتبويبات بتفصل الزمن
// (النهاردة / الشهر / الثابت / بلدنا). التحليل مش بيزاحم التسجيل.
// ————————————————————————————————————————————————————————————
Widget _designA() => Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: _t('فلوسى', size: 19, w: FontWeight.w800),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t('تقدر تصرف النهاردة',
                size: 12, color: Colors.white70, w: FontWeight.w600),
            const SizedBox(height: 4),
            _t('240 ج.م', size: 34, color: Colors.white, w: FontWeight.w900),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                  value: 0.56,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            _t('صرفت 5461 من 9800 • فاضل 6 أيام فى الشهر',
                size: 11, color: Colors.white70, w: FontWeight.w500),
          ]),
        ),
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final e in [
              ('النهاردة', true),
              ('الشهر', false),
              ('الثابت', false),
              ('بلدنا', false),
            ])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e.$2 ? _blue : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: e.$2 ? _blue : _line),
                  ),
                  child: _t(e.$1,
                      size: 12.5, color: e.$2 ? Colors.white : _mute),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _t('سجّل بسرعة', size: 12, color: _mute),
              const SizedBox(height: 8),
              Row(children: [
                for (final q in [
                  ('أكل', Icons.restaurant, Color(0xFFF59E0B)),
                  ('مواصلات', Icons.directions_bus, Color(0xFF0EA5E9)),
                  ('تسوق', Icons.shopping_bag_outlined, Color(0xFFA855F7)),
                  ('غيرها', Icons.add, _mute),
                ])
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _line)),
                      child: Column(children: [
                        Icon(q.$2, size: 19, color: q.$3),
                        const SizedBox(height: 5),
                        _t(q.$1, size: 10.5, color: _mute),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _t('عمليات النهاردة', size: 13.5)),
                _t('324 ج.م', size: 13.5, color: _red, w: FontWeight.w800),
              ]),
              const SizedBox(height: 6),
              _card(Column(children: [
                _tx('أكل', 'كشرى • 2:10 م', '76 ج.م', false,
                    icon: Icons.restaurant),
                const Divider(height: 1, color: _line),
                _tx('مواصلات', 'أوبر • 12:40 م', '48 ج.م', false,
                    icon: Icons.directions_bus),
                const Divider(height: 1, color: _line),
                _tx('تسوق', 'سوبر ماركت • 11:05 ص', '200 ج.م', false,
                    icon: Icons.shopping_bag_outlined),
              ])),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('مصروف', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

// ————————————————————————————————————————————————————————————
// تصميم ب — «رئيسية قصيرة + هَبّات»
// الفكرة: الصفحة الأولى **بتقعد فى شاشة واحدة**: رقم + 6 كروت، وكل كارت
// صفحة كاملة لوحدها. التحليل بند مستقل مش كروت مرصوصة.
// ————————————————————————————————————————————————————————————
Widget _hub(String title, String value, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 19, color: color),
        ),
        const Spacer(),
        _t(title, size: 12.5, color: _mute),
        const SizedBox(height: 2),
        _t(value, size: 15.5, w: FontWeight.w800),
      ]),
    );

Widget _designB() => Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: _t('فلوسى', size: 19, w: FontWeight.w800),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _card(
            Row(children: [
              Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _t('صافى سبتمبر', size: 12, color: _mute),
                  const SizedBox(height: 3),
                  _t('+4339 ج.م', size: 26, color: _green, w: FontWeight.w900),
                  const SizedBox(height: 3),
                  _t('دخل 9800 • مصروف 5461',
                      size: 11.5, color: _mute, w: FontWeight.w500),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999)),
                child: _t('وفّرت 44٪', size: 12, color: _green, w: FontWeight.w800),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.35,
            children: [
              _hub('المصاريف', '5461 ج.م', Icons.receipt_long_outlined, _red),
              _hub('الدخل', '9800 ج.م', Icons.south_west, _green),
              _hub('الثابت والفواتير', '550 ج.م', Icons.repeat, _blue),
              _hub('الديون', 'متعادل', Icons.handshake_outlined,
                  const Color(0xFFF59E0B)),
              _hub('الادخار', '12000 ج.م', Icons.savings_outlined,
                  const Color(0xFF0EA5E9)),
              _hub('التحليل', 'راحت فين؟', Icons.insights_outlined,
                  const Color(0xFFA855F7)),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _t('آخر العمليات', size: 13.5)),
            _t('الكل ›', size: 12.5, color: _blue),
          ]),
          const SizedBox(height: 6),
          _card(Column(children: [
            _tx('مرتب', 'دخل • 24 سبتمبر', '+9000 ج.م', true),
            const Divider(height: 1, color: _line),
            _tx('مواصلات', 'أوبر • 27 سبتمبر', '77 ج.م', false,
                icon: Icons.directions_bus),
            const Divider(height: 1, color: _line),
            _tx('سوبر ماركت', 'أكل • 27 سبتمبر', '220 ج.م', false,
                icon: Icons.shopping_bag_outlined),
          ])),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('مصروف', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

// ————————————————————————————————————————————————————————————
// تصميم ج — «دفتر واحد» (كشف حساب)
// الفكرة: مفيش كروت خالص. كشف واحد بالتاريخ، الدخل أخضر والمصروف أحمر،
// والرصيد بيتحدّث سطر بسطر — زى كشف البنك. الفلاتر فوق.
// ————————————————————————————————————————————————————————————
Widget _ledgerRow(String title, String cat, String amount, bool income,
        String balance) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
                color: income ? _green : _red,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(title, size: 13.5),
            const SizedBox(height: 2),
            _t(cat, size: 11, color: _mute, w: FontWeight.w500),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _t('${income ? '+' : '−'}$amount',
              size: 14, w: FontWeight.w800, color: income ? _green : _ink),
          const SizedBox(height: 2),
          _t('الرصيد $balance', size: 10.5, color: _mute, w: FontWeight.w500),
        ]),
      ]),
    );

Widget _designC() => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: _t('فلوسى', size: 19, w: FontWeight.w800),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.insights_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _t('الرصيد الحالى', size: 11.5, color: _mute),
                _t('14339 ج.م', size: 28, w: FontWeight.w900),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _t('+9800', size: 13, color: _green, w: FontWeight.w800),
              _t('−5461', size: 13, color: _red, w: FontWeight.w800),
            ]),
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
                ('مصروف', false),
                ('دخل', false),
                ('ثابت', false),
                ('ديون', false),
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
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _dayHeader('النهاردة • 28 سبتمبر', '−324'),
              _ledgerRow('كشرى', 'أكل', '76', false, '14339'),
              _ledgerRow('أوبر', 'مواصلات', '48', false, '14415'),
              _ledgerRow('سوبر ماركت', 'تسوق', '200', false, '14463'),
              _dayHeader('امبارح • 27 سبتمبر', '−191'),
              _ledgerRow('بنزين', 'مواصلات', '140', false, '14663'),
              _ledgerRow('صيدلية', 'صحة', '51', false, '14803'),
              _dayHeader('24 سبتمبر', '+9000'),
              _ledgerRow('مرتب', 'دخل دورى • إيجار الشقة', '9000', true,
                  '14854'),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _ink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: _t('عملية', size: 13.5, color: Colors.white, w: FontWeight.w700),
      ),
    );

Widget _dayHeader(String day, String sum) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Row(children: [
        Expanded(child: _t(day, size: 12, color: _mute, w: FontWeight.w700)),
        _t(sum, size: 12, color: _mute, w: FontWeight.w700),
      ]),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadShotFonts();
  });

  testWidgets('تصميم أ', (t) async {
    await shot(t, 'money_a', shotApp(_theme(), _designA()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('تصميم ب', (t) async {
    await shot(t, 'money_b', shotApp(_theme(), _designB()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('تصميم ج', (t) async {
    await shot(t, 'money_c', shotApp(_theme(), _designC()),
        size: const Size(390, 844), pixelRatio: 2);
  });
}
