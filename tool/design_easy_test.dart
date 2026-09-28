// معاينة «فلوسى للمبتدئ» — ٣ طرق مختلفة فعلاً.
//
// المشكلة اللى بنحلّها: الشكل الحالى ٨ كروت بمصطلحات محاسبة («صافى» ·
// «الثابت والفواتير» · «التحليل» · «متعادل») — مبتدئ مش هيعرف يبدأ منين.
// التلات طرق بيستبدلوا المصطلح بسؤال بالعربى الدارج.
//   flutter test tool/design_easy_test.dart → build/design_shots/easy_*.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'shot_harness.dart';

const _bg = Color(0xFFF6F7FB);
const _ink = Color(0xFF0F172A);
const _mute = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);
const _green = Color(0xFF16A34A);
const _red = Color(0xFFDC2626);
const _blue = Color(0xFF2563EB);
const _amber = Color(0xFFF59E0B);

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
        TextAlign? align,
        int? maxLines}) =>
    Text(s,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: TextStyle(fontSize: size, color: color, fontWeight: w));

PreferredSizeWidget _bar() => AppBar(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      title: _t('فلوسى', size: 19, w: FontWeight.w800),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
      ],
    );

Widget _fab(String label) => FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: _blue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: _t(label, size: 14, color: Colors.white, w: FontWeight.w700),
    );

// ════════════════════════════════════════════════════════════
// ١ — «أسئلة بالعربى»
// كل سطر سؤال بيسأله أى حد عن فلوسه، والإجابة تحته بالكلام مش بالمصطلح.
// ════════════════════════════════════════════════════════════
Widget _qRow(String q, String a, String note, IconData icon, Color c,
        {Widget? extra}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, size: 22, color: c),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(q, size: 13, color: _mute, maxLines: 1),
            const SizedBox(height: 4),
            _t(a, size: 19, w: FontWeight.w900, color: c, maxLines: 1),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 3),
              _t(note, size: 11.5, color: _mute, w: FontWeight.w500, maxLines: 1),
            ],
            if (extra != null) ...[const SizedBox(height: 8), extra],
          ]),
        ),
        const Icon(Icons.chevron_left, color: _mute, size: 22),
      ]),
    );

Widget _one() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _t('سبتمبر 2026', size: 12.5, color: _mute),
          const SizedBox(height: 12),
          _qRow('أقدر أصرف كام النهاردة؟', '240 ج.م', 'باقى 6 أيام فى الشهر',
              Icons.savings_outlined, _blue),
          _qRow('فلوسى راحت فين؟', 'أكتر حاجة: الأكل', '1289 من 5461 ج.م',
              Icons.pie_chart_outline, _amber,
              extra: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                    value: 0.24,
                    minHeight: 6,
                    color: _amber,
                    backgroundColor: Color(0xFFFDE8C8)),
              )),
          _qRow('هيجيلى كام؟', '9800 ج.م', 'المرتب يوم 1 من كل شهر',
              Icons.south_west, _green),
          _qRow('عليّا إيه؟', '3 فواتير — 3200 ج.م', 'أقربها فاتورة النت يوم 15',
              Icons.receipt_long_outlined, _red),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz, size: 18),
              label: _t('حاجات تانية: ديون · جمعيات · ادخار',
                  size: 12.5, color: _blue),
            ),
          ),
        ],
      ),
      floatingActionButton: _fab('سجّل'),
    );

// ════════════════════════════════════════════════════════════
// ٢ — «اعمل إيه دلوقتى؟»
// جملة واحدة بتقول حالتك، وتحتها خطوات جاهزة بزرار لكل واحدة.
// ════════════════════════════════════════════════════════════
Widget _todo(String title, String sub, String action, Color c, IconData i) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(i, size: 19, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(title, size: 13.5, maxLines: 1),
            const SizedBox(height: 2),
            _t(sub, size: 11.5, color: _mute, w: FontWeight.w500, maxLines: 1),
          ]),
        ),
        const SizedBox(width: 6),
        FilledButton.tonal(
          onPressed: () {},
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 38),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _t(action, size: 12.5, color: c, w: FontWeight.w700),
        ),
      ]),
    );

Widget _miniStat(String label, String value, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Column(children: [
          _t(value, size: 16, w: FontWeight.w900, color: c, maxLines: 1),
          const SizedBox(height: 2),
          _t(label, size: 11, color: _mute, w: FontWeight.w500, maxLines: 1),
        ]),
      ),
    );

Widget _two() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.thumb_up_alt_outlined, color: _green, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _t('الشهر ماشى كويس', size: 16, w: FontWeight.w800,
                      color: _green),
                  const SizedBox(height: 3),
                  _t('صرفت 5461 من 9800 — وفّرت 44٪',
                      size: 12.5, color: _mute, w: FontWeight.w500, maxLines: 1),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _t('اعمل إيه دلوقتى؟', size: 15, w: FontWeight.w800),
          const SizedBox(height: 10),
          _todo('فاتورة vodafone مستحقة', '1300 ج.م — النهاردة', 'اتدفعت',
              _red, Icons.receipt_long_outlined),
          _todo('سجّل مصاريف النهاردة', 'آخر تسجيل امبارح', 'سجّل', _blue,
              Icons.add_card_outlined),
          _todo('مرتبك جاى يوم 1', 'فاضل 3 أيام', 'تمام', _green,
              Icons.south_west),
          const SizedBox(height: 18),
          Row(children: [
            _miniStat('دخل الشهر', '9800', _green),
            const SizedBox(width: 10),
            _miniStat('مصروف', '5461', _red),
            const SizedBox(width: 10),
            _miniStat('فاضل', '4339', _blue),
          ]),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () {},
              child: _t('شوف كل حاجة ›', size: 13, color: _blue),
            ),
          ),
        ],
      ),
      floatingActionButton: _fab('سجّل'),
    );

// ════════════════════════════════════════════════════════════
// ٣ — «كارت واحد + ٣ أزرار»
// أقصى تبسيط: رقم واحد كبير بالكلام، وتلات أزرار بس.
// ════════════════════════════════════════════════════════════
Widget _bigBtn(String label, IconData icon, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: c),
          ),
          const SizedBox(height: 9),
          _t(label, size: 13, w: FontWeight.w700, maxLines: 1),
        ]),
      ),
    );

Widget _three() => Scaffold(
      backgroundColor: _bg,
      appBar: _bar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t('فى سبتمبر', size: 13, color: Colors.white70),
              const SizedBox(height: 8),
              _t('جالك 9800', size: 21, color: Colors.white, w: FontWeight.w800),
              _t('صرفت 5461', size: 21, color: Colors.white, w: FontWeight.w800),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                    value: 0.56,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    color: Colors.white),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999)),
                child: _t('فاضل معاك 4339 ج.م',
                    size: 14, color: Colors.white, w: FontWeight.w800),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            _bigBtn('صرفت', Icons.remove_circle_outline, _red),
            const SizedBox(width: 11),
            _bigBtn('قبضت', Icons.add_circle_outline, _green),
            const SizedBox(width: 11),
            _bigBtn('فواتيرى', Icons.receipt_long_outlined, _amber),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(children: [
              const Icon(Icons.expand_more, color: _mute),
              const SizedBox(width: 10),
              Expanded(
                  child: _t('المزيد: ديون · جمعيات · ادخار · صيانة البيت',
                      size: 13, color: _mute, maxLines: 1)),
            ]),
          ),
        ],
      ),
      floatingActionButton: _fab('سجّل'),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadShotFonts();
  });

  testWidgets('١ أسئلة', (t) async {
    await shot(t, 'easy_1', shotApp(_theme(), _one()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('٢ اعمل إيه', (t) async {
    await shot(t, 'easy_2', shotApp(_theme(), _two()),
        size: const Size(390, 844), pixelRatio: 2);
  });

  testWidgets('٣ كارت + ٣ أزرار', (t) async {
    await shot(t, 'easy_3', shotApp(_theme(), _three()),
        size: const Size(390, 844), pixelRatio: 2);
  });
}
