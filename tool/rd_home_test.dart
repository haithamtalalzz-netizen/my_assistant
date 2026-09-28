// ٣ اختيارات لشاشة «الرئيسية» — اختيار المستخدم هنا بيحدّد مظهر التطبيق كله.
//   flutter test tool/rd_home_test.dart → build/design_shots/rd_home.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rd_kit.dart';
import 'shot_harness.dart';

const _blue = Color(0xFF3B82F6);
const _rose = Color(0xFFF43F5E);
const _amber = Color(0xFFF59E0B);
const _green = Color(0xFF10B981);
const _violet = Color(0xFF8B5CF6);
const _cyan = Color(0xFF06B6D4);

Widget _greet(RdLook k) => rdPad(Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          rdT('مساء الخير يا هيثم', k, size: 17, w: FontWeight.w800),
          const SizedBox(height: 2),
          rdT('الاثنين 29 سبتمبر', k, size: 11.5, color: k.mute),
        ]),
      ),
      Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: k.tint(k.accent), borderRadius: BorderRadius.circular(20)),
        child: rdT('ه', k, size: 16, color: k.accent, w: FontWeight.w900),
      ),
    ]));

// ————————————————— 1 · نضيف وواسع —————————————————

Widget _clean() {
  const k = rdClean;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'الرئيسية'),
    const SizedBox(height: 4),
    _greet(k),
    const SizedBox(height: 14),
    rdPad(rdHero(k,
        icon: Icons.event,
        kicker: 'الجاية دلوقتى',
        title: 'د. أحمد — أسنان',
        sub: 'عيادة المهندسين · فاضل ساعتين',
        big: '6:00',
        bigSub: 'مساءً',
        primary: 'تم',
        secondary: 'تأجيل',
        colors: const [_blue, Color(0xFF1D4ED8)])),
    const SizedBox(height: 14),
    rdPad(Row(children: [
      rdStat(k, Icons.error_outline, '2', 'فاتك', _rose),
      const SizedBox(width: 10),
      rdStat(k, Icons.schedule, '5', 'جاى', _amber),
      const SizedBox(width: 10),
      rdStat(k, Icons.task_alt, '8', 'خلصت', _green),
    ])),
    rdPad(rdSection(k, 'خط يومك', trailing: '8 من 13 ›')),
    rdPad(rdCard(
        k,
        Column(children: [
          rdBar(k, 0.62, 'إنجاز اليوم'),
          const SizedBox(height: 10),
          Divider(color: k.line, height: 1),
          rdRow(k,
              icon: Icons.mosque,
              tint: _green,
              title: 'صلاة العصر',
              sub: '3:41 م',
              done: true),
          Divider(color: k.line, height: 1),
          rdRow(k,
              icon: Icons.medication,
              tint: _rose,
              title: 'كونكور 5 مج',
              sub: 'فاتت 4:00 م',
              trail: 'فات'),
          Divider(color: k.line, height: 1),
          rdRow(k,
              icon: Icons.fitness_center,
              tint: _violet,
              title: 'جيم — تمرين صدر',
              sub: '7:30 م'),
        ]),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 6))),
    rdPad(rdSection(k, 'مهام النهارده', trailing: 'الكل ›')),
    rdPad(rdCard(
        k,
        Column(children: [
          rdRow(k,
              icon: Icons.receipt_long,
              tint: _amber,
              title: 'فاتورة الكهربا',
              sub: 'فات · 27 سبتمبر'),
          Divider(color: k.line, height: 1),
          rdRow(k,
              icon: Icons.phone,
              tint: _cyan,
              title: 'أكلّم ماما',
              sub: 'النهارده'),
        ]),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4))),
  ]);
}

// ————————————————— 2 · ملوّن وودّى —————————————————

Widget _friendlyTile(RdLook k, IconData i, String n, String l, Color c) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: k.tint(c),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(17)),
            child: Icon(i, size: 18, color: c),
          ),
          const SizedBox(height: 8),
          Text(n,
              style: TextStyle(
                  fontSize: 25, color: c, fontWeight: FontWeight.w900)),
          rdT(l, k, size: 12, w: FontWeight.w700, maxLines: 1),
        ]),
      ),
    );

Widget _friendly() {
  const k = rdFriendly;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'الرئيسية'),
    const SizedBox(height: 4),
    _greet(k),
    const SizedBox(height: 14),
    rdPad(Row(children: [
      _friendlyTile(k, Icons.error_outline, '2', 'فاتك', _rose),
      const SizedBox(width: 11),
      _friendlyTile(k, Icons.schedule, '5', 'جاى دلوقتى', _amber),
    ])),
    const SizedBox(height: 11),
    rdPad(Row(children: [
      _friendlyTile(k, Icons.task_alt, '8', 'خلصت', _green),
      const SizedBox(width: 11),
      _friendlyTile(k, Icons.checklist, '3', 'مهامك', _violet),
    ])),
    rdPad(rdSection(k, 'اللى جاى دلوقتى')),
    rdPad(rdHero(k,
        icon: Icons.event,
        kicker: 'بعد ساعتين',
        title: 'د. أحمد — أسنان',
        big: '6:00',
        bigSub: 'مساءً',
        primary: 'تم',
        secondary: 'تأجيل',
        colors: const [_blue, Color(0xFF60A5FA)])),
    rdPad(rdSection(k, 'خط يومك', trailing: '8 من 13 ›')),
    rdPad(Column(children: [
      rdRow(k,
          icon: Icons.mosque,
          tint: _green,
          title: 'صلاة العصر',
          sub: '3:41 م',
          done: true,
          box: true),
      rdRow(k,
          icon: Icons.medication,
          tint: _rose,
          title: 'كونكور 5 مج',
          sub: 'فاتت 4:00 م',
          box: true),
      rdRow(k,
          icon: Icons.fitness_center,
          tint: _violet,
          title: 'جيم — تمرين صدر',
          sub: '7:30 م',
          box: true),
    ])),
  ]);
}

// ————————————————— 3 · غامق ومركّز —————————————————

Widget _focus() {
  const k = rdFocus;
  return rdPhone(k, fab: rdFab(k), children: [
    rdTop(k, 'الرئيسية'),
    const SizedBox(height: 10),
    rdPad(Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          rdT('حاجة واحدة بس دلوقتى', k, size: 12, color: k.mute),
          const SizedBox(height: 3),
          rdT('مساء الخير يا هيثم', k, size: 18, w: FontWeight.w800),
        ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('62%',
            style: TextStyle(
                fontSize: 26, color: k.accent, fontWeight: FontWeight.w900)),
        rdT('إنجاز اليوم', k, size: 10, color: k.mute),
      ]),
    ])),
    const SizedBox(height: 16),
    rdPad(Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: k.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: k.accent.withValues(alpha: 0.14),
              blurRadius: 26,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: k.tint(_blue), borderRadius: BorderRadius.circular(99)),
            child: rdT('بعد ساعتين', k,
                size: 11, color: _blue, w: FontWeight.w800),
          ),
          const Spacer(),
          Icon(Icons.event, color: k.mute, size: 19),
        ]),
        const SizedBox(height: 14),
        rdT('د. أحمد — أسنان', k, size: 23, w: FontWeight.w900, height: 1.2),
        const SizedBox(height: 5),
        rdT('عيادة المهندسين · 6 ش جامعة الدول', k,
            size: 12, color: k.mute, maxLines: 1),
        const SizedBox(height: 16),
        Row(children: [
          Text('6:00',
              style: TextStyle(
                  fontSize: 40, color: k.ink, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: rdT('مساءً', k, size: 13, color: k.mute),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [k.accent, k.accent2]),
                  borderRadius: BorderRadius.circular(14)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check, size: 18, color: k.onAccent),
                const SizedBox(width: 6),
                rdT('خلّصتها', k,
                    size: 13.5, color: k.onAccent, w: FontWeight.w800),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: k.line)),
            child: rdT('تأجيل', k, size: 13, w: FontWeight.w700),
          ),
        ]),
      ]),
    )),
    const SizedBox(height: 14),
    rdPad(Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: k.tint(_rose),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _rose.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _rose, size: 18),
        const SizedBox(width: 9),
        Expanded(child: rdT('فاتك حاجتين', k, size: 12.5, w: FontWeight.w800)),
        rdT('شوفهم ›', k, size: 11.5, color: _rose, w: FontWeight.w800),
      ]),
    )),
    rdPad(rdSection(k, 'بعد كده', trailing: 'خط يومك ›')),
    rdPad(Column(children: [
      rdRow(k,
          icon: Icons.fitness_center,
          tint: _violet,
          title: 'جيم — تمرين صدر',
          sub: '7:30 م',
          circle: false),
      Divider(color: k.line, height: 1),
      rdRow(k,
          icon: Icons.mosque,
          tint: _green,
          title: 'صلاة المغرب',
          sub: '6:12 م',
          circle: false),
      Divider(color: k.line, height: 1),
      rdRow(k,
          icon: Icons.local_drink,
          tint: _cyan,
          title: 'مياه — فاضل 3 أكواب',
          sub: 'على مدار اليوم',
          circle: false),
    ])),
  ]);
}

void main() {
  testWidgets('rd home', (tester) async {
    await loadShotFonts();
    await shot(
      tester,
      'rd_home',
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
