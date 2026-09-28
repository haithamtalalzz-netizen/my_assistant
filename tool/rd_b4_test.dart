// الدفعة ٤ (الأخيرة من البنود الرئيسية): مركز التنبيهات · كارت الطوارئ ·
// القايمة الجانبية.
//   flutter test tool/rd_b4_test.dart → build/design_shots/rd_13..15_*.png
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
const _pink = Color(0xFFEC4899);
const _slate = Color(0xFF64748B);

const _t1 = 'بطل + قوايم';
const _n1 = 'أهم حاجة فوق · والباقى مجموعات';
const _t2 = 'مربعات ملوّنة';
const _n2 = 'أرقام فوق · تدوس تفتح';
const _t3 = 'قايمة واحدة';
const _n3 = 'كل حاجة ورا بعضها · أقل دوسات';

Widget _tile(IconData i, String n, String l, Color c) => Expanded(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 24, color: c, fontWeight: FontWeight.w900)),
          rdT(l, k, size: 12, w: FontWeight.w700, maxLines: 1),
        ]),
      ),
    );

Widget _head(String s, {String? trail}) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
      child: Row(children: [
        Expanded(child: rdT(s, k, size: 13, color: k.mute, w: FontWeight.w800)),
        if (trail != null)
          rdT(trail, k, size: 11.5, color: k.mute, w: FontWeight.w700),
      ]),
    );

Widget _flat(
        {required IconData icon,
        required Color tint,
        required String title,
        String? sub,
        String? trail,
        bool done = false,
        bool check = false}) =>
    Column(children: [
      rdRow(k,
          icon: icon,
          tint: tint,
          title: title,
          sub: sub,
          trail: trail,
          done: done,
          check: check),
      Divider(color: k.line, height: 1),
    ]);

Widget _tiles3(List<(IconData, String, Color, String?)> items) =>
    rdPad(Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        Expanded(
            child: rdTile(k, items[i].$1, items[i].$2, items[i].$3,
                value: items[i].$4)),
        if (i != items.length - 1) const SizedBox(width: 11),
      ]
    ]));

// ═══════════════════════ مركز التنبيهات ═══════════════════════

Widget _alertHero() => rdHero(k,
    icon: Icons.priority_high,
    kicker: 'أهم حاجة محتاجة منك دلوقتى',
    title: 'فاتورة الكهربا فات ميعادها',
    sub: 'من يومين · 420 جنيه',
    big: '4',
    bigSub: 'تنبيه',
    primary: 'اتدفعت',
    secondary: 'فكّرنى بكرة',
    colors: const [_rose, Color(0xFFFB7185)]);

Widget alerts1() => rdPhone(k, children: [
      rdTop(k, 'مركز التنبيهات'),
      const SizedBox(height: 6),
      rdPad(_alertHero()),
      rdPad(rdSection(k, 'محتاج تتصرّف', trailing: '3')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.medication,
                tint: _rose,
                title: 'كونكور 5 مج',
                sub: 'فاتت جرعة 4:00 م',
                trail: 'اتاخدت؟'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.inventory_2,
                tint: _amber,
                title: 'دوا قرّب يخلص',
                sub: 'فاضل 3 أقراص بس',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'للعلم بس', trailing: '5 ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.backup,
                tint: _green,
                title: 'النسخة الاحتياطية بقالها 3 أيام',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.cake,
                tint: _pink,
                title: 'عيد ميلاد سارة بعد 5 أيام',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget alerts2() => rdPhone(k, children: [
      rdTop(k, 'مركز التنبيهات'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.error_outline, '4', 'محتاج تصرّف', _rose),
        const SizedBox(width: 11),
        _tile(Icons.info_outline, '5', 'للعلم', _blue),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.event, '3', 'مواعيد', _violet),
        const SizedBox(width: 11),
        _tile(Icons.payments, '2', 'فلوس', _amber),
      ])),
      rdPad(rdSection(k, 'أهم حاجة دلوقتى')),
      rdPad(_alertHero()),
      rdPad(rdSection(k, 'بعد كده', trailing: 'الكل ›')),
      rdPad(Column(children: [
        rdRow(k,
            icon: Icons.medication,
            tint: _rose,
            title: 'كونكور 5 مج',
            sub: 'فاتت جرعة 4:00 م',
            box: true),
      ])),
    ]);

Widget alerts3() => rdPhone(k, children: [
      rdTop(k, 'مركز التنبيهات'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['الكل', 'محتاج تصرّف', 'للعلم'])),
      rdPad(Column(children: [
        _head('النهارده', trail: '4'),
        _flat(
            icon: Icons.bolt,
            tint: _rose,
            title: 'فاتورة الكهربا فات ميعادها',
            sub: 'من يومين · 420 جنيه',
            trail: 'اتدفعت',
            check: true),
        _flat(
            icon: Icons.medication,
            tint: _rose,
            title: 'فاتتك جرعة كونكور',
            sub: '4:00 م',
            check: true),
        _flat(
            icon: Icons.inventory_2,
            tint: _amber,
            title: 'دوا قرّب يخلص',
            sub: 'فاضل 3 أقراص'),
        _flat(
            icon: Icons.event,
            tint: _blue,
            title: 'د. أحمد — أسنان',
            sub: 'بعد ساعتين'),
        _head('امبارح', trail: '3'),
        _flat(
            icon: Icons.backup,
            tint: _green,
            title: 'النسخة الاحتياطية بقالها 3 أيام'),
        _flat(
            icon: Icons.cake,
            tint: _pink,
            title: 'عيد ميلاد سارة بعد 5 أيام'),
        _head('الأسبوع ده', trail: '5'),
        _flat(
            icon: Icons.insights,
            tint: _teal,
            title: 'أسبوعك أحسن بـ 12%',
            sub: 'رؤى المدير'),
      ])),
    ]);

// ═══════════════════════ كارت الطوارئ ═══════════════════════

Widget _sosCard() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_rose, Color(0xFFFB7185)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(k.radius + 4),
        boxShadow: [
          BoxShadow(
              color: _rose.withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 9))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.emergency, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('هيثم طلال',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w900)),
                Text('فصيلة الدم ${ltr('O+')} · 38 سنة',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
        const SizedBox(height: 14),
        Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.phone, size: 18, color: _rose),
            const SizedBox(width: 7),
            const Text('اتصل بمنى — الزوجة',
                style: TextStyle(
                    fontSize: 13.5, color: _rose, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );

Widget sos1() => rdPhone(k, children: [
      rdTop(k, 'كارت الطوارئ', badge: 0),
      const SizedBox(height: 6),
      rdPad(_sosCard()),
      rdPad(rdSection(k, 'لازم يعرفوا', trailing: '3')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.warning_amber,
                tint: _rose,
                title: 'حساسية من البنسلين',
                sub: 'شديدة',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.favorite,
                tint: _pink,
                title: 'ضغط مرتفع',
                sub: 'بياخد كونكور 5 مج يومى',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'أرقام الطوارئ', trailing: '4')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.person,
                tint: _violet,
                title: 'منى — الزوجة',
                sub: ltr('0100 123 4567'),
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.medical_services,
                tint: _blue,
                title: 'د. أحمد — الباطنة',
                sub: ltr('0122 987 6543'),
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget sos2() => rdPhone(k, children: [
      rdTop(k, 'كارت الطوارئ', badge: 0),
      const SizedBox(height: 6),
      rdPad(_sosCard()),
      const SizedBox(height: 14),
      rdPad(Row(children: [
        _tile(Icons.bloodtype, ltr('O+'), 'فصيلة الدم', _rose),
        const SizedBox(width: 11),
        _tile(Icons.warning_amber, '2', 'حساسية', _amber),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.medication, '3', 'أدوية دايمة', _violet),
        const SizedBox(width: 11),
        _tile(Icons.contacts, '4', 'أرقام طوارئ', _blue),
      ])),
      rdPad(rdSection(k, 'كمان')),
      _tiles3([
        (Icons.vaccines, 'التطعيمات', _teal, '6'),
        (Icons.bloodtype, 'التحاليل', _cyan, '9'),
        (Icons.local_hospital, 'التأمين', _green, null),
      ]),
    ]);

Widget sos3() => rdPhone(k, children: [
      rdTop(k, 'كارت الطوارئ', badge: 0),
      const SizedBox(height: 6),
      rdPad(_sosCard()),
      rdPad(Column(children: [
        _head('بياناتك'),
        _flat(
            icon: Icons.bloodtype,
            tint: _rose,
            title: 'فصيلة الدم',
            trail: ltr('O+')),
        _flat(
            icon: Icons.cake_outlined,
            tint: _slate,
            title: 'السن',
            trail: '38 سنة'),
        _head('لازم يعرفوا', trail: '3'),
        _flat(
            icon: Icons.warning_amber,
            tint: _rose,
            title: 'حساسية من البنسلين',
            sub: 'شديدة'),
        _flat(
            icon: Icons.favorite,
            tint: _pink,
            title: 'ضغط مرتفع',
            sub: 'كونكور 5 مج يومى'),
        _head('أرقام الطوارئ', trail: '4'),
        _flat(
            icon: Icons.person,
            tint: _violet,
            title: 'منى — الزوجة',
            sub: ltr('0100 123 4567'),
            trail: 'اتصل'),
        _flat(
            icon: Icons.medical_services,
            tint: _blue,
            title: 'د. أحمد — الباطنة',
            sub: ltr('0122 987 6543'),
            trail: 'اتصل'),
        _head('كمان'),
        _flat(
            icon: Icons.vaccines, tint: _teal, title: 'التطعيمات', trail: '6'),
        _flat(
            icon: Icons.local_hospital,
            tint: _green,
            title: 'التأمين الصحى'),
      ])),
    ]);

// ═══════════════════════ القايمة الجانبية ═══════════════════════

Widget _drawerHeader() => rdPad(Row(children: [
      Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: k.tint(k.accent), borderRadius: BorderRadius.circular(23)),
        child: rdT('ه', k, size: 19, color: k.accent, w: FontWeight.w900),
      ),
      const SizedBox(width: 11),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdT('هيثم طلال', k, size: 15, w: FontWeight.w800),
        rdT('الاثنين 29 سبتمبر', k, size: 11, color: k.mute),
      ])),
      Icon(Icons.settings, color: k.mute, size: 21),
    ]));

Widget _navRow(IconData i, String t, Color c, {String? badge, bool on = false}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
          color: on ? k.tint(c) : Colors.transparent,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: on ? Colors.white : k.tint(c),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(i, size: 17, color: c),
        ),
        const SizedBox(width: 11),
        Expanded(
            child: rdT(t, k,
                size: 13.5,
                w: on ? FontWeight.w900 : FontWeight.w700,
                maxLines: 1)),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(99)),
            child: Text(badge,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ),
      ]),
    );

Widget drawer1() => rdPhone(k, children: [
      const SizedBox(height: 8),
      _drawerHeader(),
      rdPad(rdSection(k, 'يومك')),
      rdPad(Column(children: [
        _navRow(Icons.home, 'الرئيسية', k.accent, on: true),
        _navRow(Icons.event, 'مواعيدى', _blue, badge: '2'),
        _navRow(Icons.checklist, 'مهامى', _amber, badge: '3'),
        _navRow(Icons.alarm, 'تذكيراتى', _violet),
      ])),
      rdPad(rdSection(k, 'حياتك')),
      rdPad(Column(children: [
        _navRow(Icons.flag, 'الأهداف', _teal),
        _navRow(Icons.mosque, 'صلاتى', _green),
        _navRow(Icons.favorite, 'صحتى', _rose),
        _navRow(Icons.account_balance_wallet, 'فلوسى', _green),
        _navRow(Icons.checkroom, 'ملابسى', _cyan),
        _navRow(Icons.school, 'تطوّرى', _violet),
      ])),
    ]);

Widget drawer2() => rdPhone(k, children: [
      const SizedBox(height: 8),
      _drawerHeader(),
      const SizedBox(height: 14),
      _tiles3([
        (Icons.home, 'الرئيسية', k.accent, null),
        (Icons.event, 'مواعيدى', _blue, '2'),
        (Icons.checklist, 'مهامى', _amber, '3'),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.alarm, 'تذكيراتى', _violet, null),
        (Icons.flag, 'الأهداف', _teal, '4'),
        (Icons.mosque, 'صلاتى', _green, null),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.favorite, 'صحتى', _rose, null),
        (Icons.account_balance_wallet, 'فلوسى', _green, null),
        (Icons.checkroom, 'ملابسى', _cyan, null),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.school, 'تطوّرى', _violet, null),
        (Icons.insights, 'المتابعة', _teal, null),
        (Icons.settings, 'الإعدادات', _slate, null),
      ]),
    ]);

Widget drawer3() => rdPhone(k, children: [
      const SizedBox(height: 8),
      _drawerHeader(),
      const SizedBox(height: 12),
      rdPad(Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: k.line)),
        child: Row(children: [
          Icon(Icons.search, size: 18, color: k.mute),
          const SizedBox(width: 8),
          rdT('دوّر على بند…', k, size: 12, color: k.mute),
        ]),
      )),
      const SizedBox(height: 10),
      rdPad(Column(children: [
        _navRow(Icons.home, 'الرئيسية', k.accent, on: true),
        _navRow(Icons.event, 'مواعيدى', _blue, badge: '2'),
        _navRow(Icons.checklist, 'مهامى', _amber, badge: '3'),
        _navRow(Icons.alarm, 'تذكيراتى', _violet),
        _navRow(Icons.flag, 'الأهداف', _teal),
        _navRow(Icons.mosque, 'صلاتى', _green),
        _navRow(Icons.favorite, 'صحتى', _rose),
        _navRow(Icons.account_balance_wallet, 'فلوسى', _green),
        _navRow(Icons.checkroom, 'ملابسى', _cyan),
        _navRow(Icons.school, 'تطوّرى', _violet),
        _navRow(Icons.insights, 'المتابعة والأدوات', _teal),
        _navRow(Icons.settings, 'الإعدادات', _slate),
      ])),
    ]);

// ═══════════════════════════ الرسم ═══════════════════════════

Future<void> _three(WidgetTester tester, String name, Widget a, Widget b,
        Widget c) async =>
    shot(
      tester,
      name,
      shotApp(rdTheme(k),
          rdTriptych([(_t1, _n1, a), (_t2, _n2, b), (_t3, _n3, c)])),
      size: const Size(1152, 890),
      pixelRatio: 2,
    );

void main() {
  testWidgets('rd batch 4', (tester) async {
    await loadShotFonts();
    await _three(tester, 'rd_13_alerts', alerts1(), alerts2(), alerts3());
    await _three(tester, 'rd_14_sos', sos1(), sos2(), sos3());
    await _three(tester, 'rd_15_drawer', drawer1(), drawer2(), drawer3());
  });
}
