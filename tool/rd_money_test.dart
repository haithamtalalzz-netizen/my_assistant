// نفس التلات مظاهر على «فلوسى» — أكتر شاشة فيها أرقام، فهى اللى بتكشف
// المظهر اللى هيريّح العين ولا لأ.
//   flutter test tool/rd_money_test.dart → build/design_shots/rd_money.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFEC4899);

Widget _monthNav(RdLook k) => rdPad(Row(children: [
      Icon(Icons.chevron_right, color: k.mute, size: 22),
      Expanded(
          child: rdT('سبتمبر 2026', k,
              size: 15, w: FontWeight.w800, align: TextAlign.center)),
      Icon(Icons.chevron_left, color: k.mute, size: 22),
    ]));

Widget _catRow(RdLook k, IconData i, String name, String amount, double v,
        Color c, String left) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: k.tint(c), borderRadius: BorderRadius.circular(11)),
            child: Icon(i, size: 17, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(child: rdT(name, k, size: 13.5, w: FontWeight.w700)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            rdT(amount, k, size: 13.5, w: FontWeight.w900),
            rdT(left, k, size: 10.5, color: k.mute),
          ]),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: k.line,
              valueColor: AlwaysStoppedAnimation(c)),
        ),
      ]),
    );

// ————————————————— 1 · نضيف وواسع —————————————————

Widget _clean() {
  const k = rdClean;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'فلوسى'),
    _monthNav(k),
    const SizedBox(height: 10),
    rdPad(rdHero(k,
        icon: Icons.account_balance_wallet,
        kicker: 'فاضل معاك لغاية آخر الشهر',
        title: '4,250 جنيه',
        sub: 'الشهر ماشى كويس · يعنى 141 جنيه فى اليوم',
        big: '66%',
        bigSub: 'اتصرف',
        primary: 'صرفت فلوس',
        primaryIcon: Icons.remove,
        secondary: 'قبضت',
        colors: const [Color(0xFF059669), _green])),
    const SizedBox(height: 14),
    rdPad(Row(children: [
      rdStat(k, Icons.arrow_downward, '12,400', 'دخل', _green),
      const SizedBox(width: 10),
      rdStat(k, Icons.arrow_upward, '8,150', 'صرفت', _red),
      const SizedBox(width: 10),
      rdStat(k, Icons.event_repeat, '3', 'فواتير', _amber),
    ])),
    rdPad(rdSection(k, 'راحت فين؟', trailing: 'الكل ›')),
    rdPad(rdCard(
        k,
        Column(children: [
          _catRow(k, Icons.shopping_cart, 'أكل وشرب', '3,100', 0.78, _amber,
              'من 4,000'),
          Divider(color: k.line, height: 1),
          _catRow(k, Icons.directions_car, 'مواصلات', '1,450', 0.48, _blue,
              'من 3,000'),
          Divider(color: k.line, height: 1),
          _catRow(k, Icons.medical_services, 'صحة', '900', 0.9, _pink,
              'من 1,000'),
        ]),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10))),
    rdPad(rdSection(k, 'عليّا إيه؟', trailing: '3 فواتير ›')),
    rdPad(rdCard(
        k,
        Column(children: [
          rdRow(k,
              icon: Icons.bolt,
              tint: _amber,
              title: 'كهربا',
              sub: 'فات ميعادها · 27 سبتمبر',
              trail: '420'),
        ]),
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
  ]);
}

// ————————————————— 2 · ملوّن وودّى —————————————————

Widget _bigNum(RdLook k, String n, String l, Color c, IconData i) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: k.tint(c),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Icon(i, size: 16, color: c),
            ),
            const SizedBox(width: 7),
            Expanded(child: rdT(l, k, size: 12, w: FontWeight.w700, maxLines: 1)),
          ]),
          const SizedBox(height: 9),
          Text(n,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 21, color: c, fontWeight: FontWeight.w900)),
        ]),
      ),
    );

Widget _friendly() {
  const k = rdFriendly;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'فلوسى'),
    _monthNav(k),
    const SizedBox(height: 10),
    rdPad(Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: k.tint(_green),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _green.withValues(alpha: 0.3))),
      child: Column(children: [
        rdT('فاضل معاك', k, size: 12.5, color: k.mute, w: FontWeight.w700),
        const SizedBox(height: 4),
        const Text('4,250',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 40,
                color: Color(0xFF059669),
                fontWeight: FontWeight.w900)),
        rdT('جنيه لغاية آخر الشهر', k, size: 12, color: k.mute),
        const SizedBox(height: 12),
        rdBar(k, 0.66, 'اتصرف من دخلك', color: _green),
      ]),
    )),
    const SizedBox(height: 12),
    rdPad(Row(children: [
      _bigNum(k, '12,400', 'دخل', _green, Icons.arrow_downward),
      const SizedBox(width: 11),
      _bigNum(k, '8,150', 'صرفت', _red, Icons.arrow_upward),
    ])),
    rdPad(rdSection(k, 'راحت فين؟', trailing: 'الكل ›')),
    rdPad(Column(children: [
      rdCard(
          k,
          _catRow(k, Icons.shopping_cart, 'أكل وشرب', '3,100', 0.78, _amber,
              'من 4,000'),
          padding: const EdgeInsets.fromLTRB(13, 3, 13, 9),
          tint: _amber),
      const SizedBox(height: 9),
      rdCard(
          k,
          _catRow(k, Icons.directions_car, 'مواصلات', '1,450', 0.48, _blue,
              'من 3,000'),
          padding: const EdgeInsets.fromLTRB(13, 3, 13, 9),
          tint: _blue),
      const SizedBox(height: 9),
      rdCard(
          k,
          _catRow(
              k, Icons.medical_services, 'صحة', '900', 0.9, _pink, 'من 1,000'),
          padding: const EdgeInsets.fromLTRB(13, 3, 13, 9),
          tint: _pink),
    ])),
  ]);
}

// ————————————————— 3 · غامق ومركّز —————————————————

Widget _focus() {
  const k = rdFocus;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'فلوسى'),
    _monthNav(k),
    const SizedBox(height: 14),
    rdPad(Column(children: [
      rdT('فاضل معاك لغاية آخر الشهر', k, size: 12.5, color: k.mute),
      const SizedBox(height: 6),
      Text('4,250',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 52,
              color: k.ink,
              fontWeight: FontWeight.w900,
              height: 1.05)),
      rdT('جنيه · يعنى 141 فى اليوم', k, size: 12, color: k.accent),
      const SizedBox(height: 16),
      rdBar(k, 0.66, 'اتصرف 8,150 من 12,400'),
    ])),
    const SizedBox(height: 18),
    rdPad(Row(children: [
      Expanded(
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [k.accent, k.accent2]),
              borderRadius: BorderRadius.circular(15)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.remove, size: 18, color: k.onAccent),
            const SizedBox(width: 6),
            rdT('صرفت فلوس', k,
                size: 13.5, color: k.onAccent, w: FontWeight.w800),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: k.line)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add, size: 18, color: k.ink),
            const SizedBox(width: 6),
            rdT('قبضت', k, size: 13.5, w: FontWeight.w800),
          ]),
        ),
      ),
    ])),
    rdPad(rdSection(k, 'راحت فين؟', trailing: 'الكل ›')),
    rdPad(Column(children: [
      _catRow(k, Icons.shopping_cart, 'أكل وشرب', '3,100', 0.78, _amber,
          'من 4,000'),
      _catRow(
          k, Icons.directions_car, 'مواصلات', '1,450', 0.48, _blue, 'من 3,000'),
      _catRow(k, Icons.medical_services, 'صحة', '900', 0.9, _pink, 'من 1,000'),
    ])),
    const SizedBox(height: 10),
    rdPad(Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: k.tint(_amber),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _amber.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.bolt, color: _amber, size: 19),
        const SizedBox(width: 9),
        Expanded(
            child: rdT('كهربا — فات ميعادها', k, size: 12.5, w: FontWeight.w800)),
        rdT('420', k, size: 13, color: _amber, w: FontWeight.w900),
      ]),
    )),
  ]);
}

void main() {
  testWidgets('rd money', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'rd_money',
      shotApp(
        rdTheme(rdClean),
        rdTriptych([
          (rdClean.name, rdClean.note, _clean()),
          (rdFriendly.name, rdFriendly.note, _friendly()),
          (rdFocus.name, rdFocus.note, _focus()),
        ]),
      ),
      size: const Size(1152, 890),
      pixelRatio: 2,
    );
  });
}
