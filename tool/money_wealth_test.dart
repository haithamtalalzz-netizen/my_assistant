// «فلوسى» بالتقسيمة اللى طلبها:
//   ١ إجمالى فلوسى فوق، مقسوم على المحافظ (كاش · بنوك · ذهب وفضة ·
//     أصول · مواشى)
//   ٢ «صرفت إيه النهاردة» — تدوس تفتح تقويم (يوم · شهر · سنة · من–إلى)
//   ٣ زرار + صرفت و + قبضت
//   ٤ «اللى ثابت كل شهر» زى نموذج ٤
//
// التلاتة بيفرقوا فى **إزاى الإجمالى والمحافظ بيتعرضوا** — الباقى واحد.
//   flutter test tool/money_wealth_test.dart
//   → build/design_shots/money_wealth.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const k = RdLook(
  name: 'فلوسى',
  note: '',
  bg: Color(0xFFF6F8FC),
  surface: Colors.white,
  ink: Color(0xFF0F172A),
  mute: Color(0xFF6E7A8C),
  line: Color(0xFFE6EBF3),
  accent: Color(0xFF2E86F5),
  accent2: Color(0xFF5BA4F8),
  onAccent: Colors.white,
  radius: 22,
  tinted: true,
  dark: false,
);

const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFF59E0B);
const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);
const _gold = Color(0xFFD9A441);
const _brown = Color(0xFF9A6B4F);

/// المحافظ: الاسم · المبلغ · اللون · الأيقونة · نصيبه من الإجمالى.
const _wallets = <(String, String, Color, IconData, double)>[
  ('كاش', '12,400', _green, Icons.payments, 0.010),
  ('بنوك', '172,100', _teal, Icons.account_balance, 0.134),
  ('ذهب وفضة', '340,000', _gold, Icons.diamond, 0.265),
  ('أصول', '750,000', _violet, Icons.home_work, 0.584),
  ('مواشى', '10,000', _brown, Icons.pets, 0.008),
];

const _total = '1,284,500';

Widget _head(String s, {String? trail}) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
      child: Row(children: [
        Expanded(child: rdT(s, k, size: 13, color: k.mute, w: FontWeight.w800)),
        if (trail != null)
          rdT(trail, k, size: 11.5, color: k.mute, w: FontWeight.w700),
      ]),
    );

Widget _row(IconData i, String title, String sub, String amount, Color c,
        {bool last = false, bool chevron = false}) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(c), borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 18, color: c),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(title, k, size: 13.5, w: FontWeight.w700, maxLines: 1),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
              ],
            ]),
          ),
          rdT(ltr(amount), k, size: 13.5, color: c, w: FontWeight.w900),
          if (chevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_left, size: 19, color: k.mute),
          ],
        ]),
      ),
      if (!last) Divider(color: k.line, height: 1),
    ]);

/// «صرفت إيه النهاردة» — الضغط بيفتح تقويم يختار منه المدى.
Widget _spentToday() => Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: k.line),
          boxShadow: k.shadow),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: k.tint(_red), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.trending_down, size: 20, color: _red),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            rdT('صرفت إيه النهاردة؟', k, size: 13.5, w: FontWeight.w800),
            const SizedBox(height: 2),
            rdT('٤ حركات · دوس تختار يوم أو شهر أو فترة', k,
                size: 10.5, color: k.mute, maxLines: 1),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('655',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 19,
                  color: _red,
                  fontWeight: FontWeight.w900)),
          Row(children: [
            Icon(Icons.calendar_month, size: 12, color: k.mute),
            const SizedBox(width: 3),
            rdT('النهاردة', k, size: 10, color: k.mute),
          ]),
        ]),
      ]),
    );

Widget _twoButtons() => Row(children: [
      Expanded(
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _red, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.remove, size: 19, color: Colors.white),
            const SizedBox(width: 6),
            const Text('صرفت',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _green, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add, size: 19, color: Colors.white),
            const SizedBox(width: 6),
            const Text('قبضت',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ]);

Widget _fixedMonthly() => Column(children: [
      _head('اللى ثابت كل شهر'),
      _row(Icons.payments, 'دخلك', 'يوم 1', '11,000', _green),
      _row(Icons.receipt_long, 'فواتير ثابتة', 'كهربا · نت · مدرسة', '2,100',
          _amber),
      _row(Icons.savings, 'بتدخّر', 'أول الشهر', '2,000', _teal, last: true),
    ]);

// ═══════════════ ١ · مربعات المحافظ ═══════════════

Widget _walletTile(int i) {
  final (name, amount, c, icon, _) = _wallets[i];
  return Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
        color: k.tint(c),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: c),
        ),
        const SizedBox(width: 7),
        Expanded(
            child: rdT(name, k, size: 11.5, w: FontWeight.w800, maxLines: 1)),
      ]),
      const SizedBox(height: 8),
      Text(amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: c,
              fontWeight: FontWeight.w900)),
    ]),
  );
}

Widget shape1() => rdPhone(k, height: 900, children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 6),
      rdPad(Column(children: [
        rdT('إجمالى فلوسى', k, size: 12.5, color: k.mute, w: FontWeight.w700),
        const SizedBox(height: 2),
        Text(_total,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 38,
                color: k.accent,
                fontWeight: FontWeight.w900,
                height: 1.1)),
        rdT('جنيه', k, size: 11.5, color: k.mute),
      ])),
      const SizedBox(height: 14),
      rdPad(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _walletTile(0)),
          const SizedBox(width: 10),
          Expanded(child: _walletTile(1)),
        ]),
      )),
      const SizedBox(height: 10),
      rdPad(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _walletTile(2)),
          const SizedBox(width: 10),
          Expanded(child: _walletTile(3)),
        ]),
      )),
      const SizedBox(height: 10),
      rdPad(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _walletTile(4)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: k.line)),
            child: Row(children: [
              Icon(Icons.add_circle_outline, size: 19, color: k.accent),
              const SizedBox(width: 8),
              Expanded(
                  child: rdT('محفظة جديدة', k,
                      size: 11.5, color: k.mute, w: FontWeight.w700)),
            ]),
          ),
        ),
      ]))),
      const SizedBox(height: 18),
      rdPad(_spentToday()),
      const SizedBox(height: 12),
      rdPad(_twoButtons()),
      rdPad(_fixedMonthly()),
    ]);

// ═══════════════ ٢ · شريط مقسوم + قايمة ═══════════════

Widget _stackedBar() => ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 12,
        child: Row(children: [
          for (final w in _wallets)
            Expanded(
              flex: (w.$5 * 1000).round().clamp(8, 1000),
              child: Container(color: w.$3),
            ),
        ]),
      ),
    );

Widget shape2() => rdPhone(k, height: 900, children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 6),
      rdPad(Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
            color: k.tint(k.accent),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: k.accent.withValues(alpha: 0.25))),
        child: Column(children: [
          rdT('إجمالى فلوسى', k, size: 12, color: k.mute, w: FontWeight.w700),
          const SizedBox(height: 2),
          Text(_total,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 34,
                  color: k.accent,
                  fontWeight: FontWeight.w900,
                  height: 1.15)),
          const SizedBox(height: 12),
          _stackedBar(),
        ]),
      )),
      rdPad(Column(children: [
        _head('محافظك', trail: '٥'),
        for (var i = 0; i < _wallets.length; i++)
          _row(_wallets[i].$4, _wallets[i].$1,
              '${(_wallets[i].$5 * 100).round()}٪ من إجمالى فلوسك',
              _wallets[i].$2, _wallets[i].$3,
              last: i == _wallets.length - 1, chevron: true),
      ])),
      const SizedBox(height: 14),
      rdPad(_spentToday()),
      const SizedBox(height: 12),
      rdPad(_twoButtons()),
      rdPad(_fixedMonthly()),
    ]);

// ═══════════════ ٣ · كارت واحد جامع ═══════════════

Widget _legend(int i) {
  final (name, amount, c, icon, pct) = _wallets[i];
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Icon(icon, size: 15, color: c),
      const SizedBox(width: 7),
      Expanded(child: rdT(name, k, size: 12.5, w: FontWeight.w700, maxLines: 1)),
      rdT('${(pct * 100).round()}٪', k, size: 11, color: k.mute),
      const SizedBox(width: 9),
      rdT(amount, k, size: 13, w: FontWeight.w900),
    ]),
  );
}

Widget shape3() => rdPhone(k, height: 900, children: [
      rdTop(k, 'فلوسى', badge: 0),
      const SizedBox(height: 6),
      rdPad(Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
        decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: k.line),
            boxShadow: k.shadow),
        child: Column(children: [
          Row(children: [
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                rdT('إجمالى فلوسى', k,
                    size: 12, color: k.mute, w: FontWeight.w700),
                const SizedBox(height: 2),
                Text(_total,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 30,
                        color: k.ink,
                        fontWeight: FontWeight.w900,
                        height: 1.15)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: k.tint(_green),
                  borderRadius: BorderRadius.circular(99)),
              child: rdT('٥ محافظ', k,
                  size: 11, color: _green, w: FontWeight.w800),
            ),
          ]),
          const SizedBox(height: 12),
          _stackedBar(),
          const SizedBox(height: 6),
          for (var i = 0; i < _wallets.length; i++) _legend(i),
          Divider(color: k.line, height: 14),
          Row(children: [
            Icon(Icons.add_circle_outline, size: 17, color: k.accent),
            const SizedBox(width: 7),
            rdT('ضيف محفظة أو أصل', k,
                size: 12, color: k.accent, w: FontWeight.w700),
          ]),
        ]),
      )),
      const SizedBox(height: 16),
      rdPad(_spentToday()),
      const SizedBox(height: 12),
      rdPad(_twoButtons()),
      rdPad(_fixedMonthly()),
    ]);

void main() {
  testWidgets('money wealth shapes', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'money_wealth',
      shotApp(
        rdTheme(k),
        rdTriptych([
          ('مربعات المحافظ', 'كل محفظة مربّع بلونها', shape1()),
          ('شريط + قايمة', 'شريط مقسوم فوق · والمحافظ سطور', shape2()),
          ('كارت واحد جامع', 'الإجمالى والتقسيمة فى كارت واحد', shape3()),
        ]),
      ),
      size: const Size(1152, 1030),
      pixelRatio: 2,
    );
  });
}
