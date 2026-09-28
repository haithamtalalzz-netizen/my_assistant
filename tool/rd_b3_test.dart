// الدفعة ٣: ملابسى · تطوّرى · المتابعة والأدوات · الإعدادات.
//   flutter test tool/rd_b3_test.dart → build/design_shots/rd_9..12_*.png
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

/// صف من ٣ مربعات هَب.
Widget _tiles3(List<(IconData, String, Color, String?)> items) =>
    rdPad(Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        Expanded(
            child: rdTile(k, items[i].$1, items[i].$2, items[i].$3,
                value: items[i].$4)),
        if (i != items.length - 1) const SizedBox(width: 11),
      ]
    ]));

// ═══════════════════════════ ملابسى ═══════════════════════════

Widget _wardrobeHero() => rdHero(k,
    icon: Icons.checkroom,
    kicker: 'ألبس إيه النهارده؟',
    title: 'قميص أزرق + بنطلون بيچ',
    sub: 'الجو 28 درجة · مالبستهاش من 3 أسابيع',
    big: '28°',
    bigSub: 'دافى',
    primary: 'لبستها',
    secondary: 'غيّرلى',
    colors: const [_cyan, Color(0xFF38BDF8)]);

Widget wardrobe1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'ملابسى'),
      const SizedBox(height: 6),
      rdPad(_wardrobeHero()),
      rdPad(rdSection(k, 'أطقمك', trailing: '12 ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.work,
                tint: _blue,
                title: 'طقم الشغل',
                sub: 'قميص + بنطلون + جزمة',
                trail: '5 مرات',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.celebration,
                tint: _violet,
                title: 'طقم المناسبات',
                sub: 'بدلة كحلى',
                trail: 'مرة',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'محتاج انتباه', trailing: '2')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.local_laundry_service,
                tint: _amber,
                title: 'فى الغسيل',
                sub: '6 قطع من 4 أيام',
                trail: 'خلّصت؟',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.visibility_off,
                tint: _slate,
                title: 'مالبستهاش من زمان',
                sub: '9 قطع من أكتر من 3 شهور',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget wardrobe2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'ملابسى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.checkroom, '84', 'قطعة', _cyan),
        const SizedBox(width: 11),
        _tile(Icons.style, '12', 'طقم', _violet),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.local_laundry_service, '6', 'فى الغسيل', _amber),
        const SizedBox(width: 11),
        _tile(Icons.visibility_off, '9', 'مالبستهاش', _slate),
      ])),
      rdPad(rdSection(k, 'ألبس إيه النهارده؟')),
      rdPad(_wardrobeHero()),
      rdPad(rdSection(k, 'أقسام الدولاب', trailing: 'الكل ›')),
      _tiles3([
        (Icons.checkroom, 'قمصان', _blue, '18'),
        (Icons.dry_cleaning, 'بناطيل', _teal, '11'),
        (Icons.ac_unit, 'شتوى', _violet, '14'),
      ]),
    ]);

Widget wardrobe3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'ملابسى'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['الكل', 'صيفى', 'شتوى', 'رسمى'])),
      rdPad(Column(children: [
        _head('اقتراح النهارده'),
        _flat(
            icon: Icons.wb_sunny,
            tint: _cyan,
            title: 'قميص أزرق + بنطلون بيچ',
            sub: 'الجو 28 درجة',
            trail: 'لبستها',
            check: true),
        _head('أطقمك', trail: '12'),
        _flat(
            icon: Icons.work,
            tint: _blue,
            title: 'طقم الشغل',
            sub: 'قميص + بنطلون + جزمة',
            trail: '5 مرات'),
        _flat(
            icon: Icons.celebration,
            tint: _violet,
            title: 'طقم المناسبات',
            sub: 'بدلة كحلى',
            trail: 'مرة'),
        _head('أقسام الدولاب', trail: '84 قطعة'),
        _flat(icon: Icons.checkroom, tint: _blue, title: 'قمصان', trail: '18'),
        _flat(
            icon: Icons.dry_cleaning, tint: _teal, title: 'بناطيل', trail: '11'),
        _flat(icon: Icons.ac_unit, tint: _violet, title: 'شتوى', trail: '14'),
        _head('محتاج انتباه', trail: '2'),
        _flat(
            icon: Icons.local_laundry_service,
            tint: _amber,
            title: 'فى الغسيل',
            sub: '6 قطع من 4 أيام'),
      ])),
    ]);

// ═══════════════════════════ تطوّرى ═══════════════════════════

Widget _growthHero() => rdHero(k,
    icon: Icons.school,
    kicker: 'اللى شغّال عليه دلوقتى',
    title: 'كورس التسويق الرقمى',
    sub: 'الدرس 7 من 20 · آخر مرة من يومين',
    big: '35%',
    bigSub: '7 من 20',
    primary: 'كمّل',
    primaryIcon: Icons.play_arrow,
    secondary: 'تفاصيل',
    colors: const [_violet, Color(0xFFA78BFA)]);

Widget growth1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تطوّرى'),
      const SizedBox(height: 6),
      rdPad(_growthHero()),
      rdPad(rdSection(k, 'ماشى معاك', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.menu_book,
                tint: _teal,
                title: 'كتاب: العادات الذرية',
                sub: 'صفحة 142 من 320',
                trail: '44%',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.smoke_free,
                tint: _green,
                title: 'عدّاد الإقلاع',
                sub: 'من 47 يوم',
                trail: 'وفّرت 2,350',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.emoji_events,
                tint: _amber,
                title: 'تحدى: مشى كل يوم',
                sub: 'يوم 12 من 30',
                trail: '40%',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'كمان', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.edit_note,
                tint: _blue,
                title: 'اليوميات',
                sub: 'آخر تدوينة امبارح',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.diversity_3,
                tint: _pink,
                title: 'صلة الرحم',
                sub: '3 ماتكلمتش معاهم من شهر',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget growth2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تطوّرى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.school, '2', 'كورسات', _violet),
        const SizedBox(width: 11),
        _tile(Icons.menu_book, '3', 'كتب', _teal),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.emoji_events, '1', 'تحدى', _amber),
        const SizedBox(width: 11),
        _tile(Icons.smoke_free, '47', 'يوم إقلاع', _green),
      ])),
      rdPad(rdSection(k, 'شغّال عليه دلوقتى')),
      rdPad(_growthHero()),
      rdPad(rdSection(k, 'بنود تطوّرك', trailing: 'الكل ›')),
      _tiles3([
        (Icons.edit_note, 'اليوميات', _blue, 'امبارح'),
        (Icons.diversity_3, 'صلة الرحم', _pink, '3 فايتين'),
        (Icons.lock, 'كلمات السر', _slate, '28'),
      ]),
    ]);

Widget growth3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تطوّرى'),
      const SizedBox(height: 8),
      rdPad(Column(children: [
        _head('ماشى معاك دلوقتى', trail: '4'),
        _flat(
            icon: Icons.school,
            tint: _violet,
            title: 'كورس التسويق الرقمى',
            sub: 'الدرس 7 من 20',
            trail: '35%'),
        _flat(
            icon: Icons.menu_book,
            tint: _teal,
            title: 'العادات الذرية',
            sub: 'صفحة 142 من 320',
            trail: '44%'),
        _flat(
            icon: Icons.emoji_events,
            tint: _amber,
            title: 'تحدى: مشى كل يوم',
            sub: 'يوم 12 من 30',
            trail: '40%'),
        _flat(
            icon: Icons.smoke_free,
            tint: _green,
            title: 'عدّاد الإقلاع',
            sub: '47 يوم · وفّرت 2,350',
            trail: 'ماشى'),
        _head('بنود تانية'),
        _flat(
            icon: Icons.edit_note,
            tint: _blue,
            title: 'اليوميات',
            sub: 'آخر تدوينة امبارح',
            trail: '64'),
        _flat(
            icon: Icons.diversity_3,
            tint: _pink,
            title: 'صلة الرحم',
            sub: '3 ماتكلمتش معاهم من شهر'),
        _flat(
            icon: Icons.insights,
            tint: _cyan,
            title: 'تحليلات العادات',
            sub: 'أحسن أسبوع من 6 أسابيع'),
        _flat(
            icon: Icons.lock, tint: _slate, title: 'كلمات السر', trail: '28'),
      ])),
    ]);

// ═══════════════════ المتابعة والأدوات ═══════════════════

Widget _toolsHero() => rdHero(k,
    icon: Icons.insights,
    kicker: 'رؤى المدير · الأسبوع ده',
    title: 'أسبوعك أحسن بـ 12% عن اللى قبله',
    sub: 'أعلى إنجاز يوم التلات · أضعف يوم الجمعة',
    big: '82',
    bigSub: 'من 100',
    primary: 'شوف التفاصيل',
    primaryIcon: Icons.arrow_back,
    colors: const [_teal, Color(0xFF2DD4BF)]);

Widget tools1() => rdPhone(k, fab: rdFab(k, icon: Icons.search), children: [
      rdTop(k, 'المتابعة والأدوات'),
      const SizedBox(height: 6),
      rdPad(_toolsHero()),
      rdPad(rdSection(k, 'تقارير', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.bar_chart,
                tint: _blue,
                title: 'إحصائياتك',
                sub: 'شهر سبتمبر',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.calendar_month,
                tint: _violet,
                title: 'المراجعة السنوية',
                sub: '2026',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'أدوات', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.inbox,
                tint: _amber,
                title: 'صندوق الوارد',
                sub: '5 حاجات مستنية ترتّبها',
                trail: '5',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.event_note,
                tint: _green,
                title: 'التخطيط الأسبوعى',
                sub: 'أسبوع 30 سبتمبر',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.folder,
                tint: _slate,
                title: 'المستندات',
                sub: '23 ملف',
                trail: '23',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget tools2() => rdPhone(k, fab: rdFab(k, icon: Icons.search), children: [
      rdTop(k, 'المتابعة والأدوات'),
      const SizedBox(height: 8),
      rdPad(_toolsHero()),
      rdPad(rdSection(k, 'تقارير')),
      _tiles3([
        (Icons.bar_chart, 'إحصائياتك', _blue, 'سبتمبر'),
        (Icons.calendar_month, 'المراجعة السنوية', _violet, '2026'),
        (Icons.description, 'التقارير', _teal, 'PDF'),
      ]),
      rdPad(rdSection(k, 'أدوات')),
      _tiles3([
        (Icons.inbox, 'صندوق الوارد', _amber, '5'),
        (Icons.event_note, 'التخطيط الأسبوعى', _green, null),
        (Icons.folder, 'المستندات', _slate, '23'),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.calculate, 'حاسبات', _cyan, null),
        (Icons.history, 'آلة الزمن', _pink, null),
        (Icons.rule, 'قواعدى', _rose, '7'),
      ]),
    ]);

Widget tools3() => rdPhone(k, fab: rdFab(k, icon: Icons.search), children: [
      rdTop(k, 'المتابعة والأدوات'),
      const SizedBox(height: 8),
      rdPad(rdCard(
          k,
          Row(children: [
            const Icon(Icons.insights, color: _teal, size: 20),
            const SizedBox(width: 9),
            Expanded(
                child: rdT('أسبوعك أحسن بـ 12% عن اللى قبله', k,
                    size: 13, w: FontWeight.w800, maxLines: 1)),
            rdT('82', k, size: 15, color: _teal, w: FontWeight.w900),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          tint: _teal)),
      rdPad(Column(children: [
        _head('تقارير'),
        _flat(
            icon: Icons.insights,
            tint: _teal,
            title: 'رؤى المدير',
            sub: 'الأسبوع ده'),
        _flat(
            icon: Icons.bar_chart,
            tint: _blue,
            title: 'إحصائياتك',
            sub: 'شهر سبتمبر'),
        _flat(
            icon: Icons.calendar_month,
            tint: _violet,
            title: 'المراجعة السنوية',
            sub: '2026'),
        _flat(
            icon: Icons.description, tint: _teal, title: 'التقارير', sub: 'PDF'),
        _head('أدوات'),
        _flat(
            icon: Icons.inbox,
            tint: _amber,
            title: 'صندوق الوارد',
            sub: '5 حاجات مستنية',
            trail: '5'),
        _flat(
            icon: Icons.event_note,
            tint: _green,
            title: 'التخطيط الأسبوعى',
            sub: 'أسبوع 30 سبتمبر'),
        _flat(
            icon: Icons.folder, tint: _slate, title: 'المستندات', trail: '23'),
        _flat(icon: Icons.calculate, tint: _cyan, title: 'حاسبات'),
        _flat(icon: Icons.history, tint: _pink, title: 'آلة الزمن'),
        _flat(icon: Icons.rule, tint: _rose, title: 'قواعدى', trail: '7'),
      ])),
    ]);

// ═══════════════════════════ الإعدادات ═══════════════════════════

Widget _account() => rdCard(
    k,
    Row(children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: k.tint(k.accent), borderRadius: BorderRadius.circular(26)),
        child: rdT('ه', k, size: 21, color: k.accent, w: FontWeight.w900),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rdT('هيثم طلال', k, size: 15, w: FontWeight.w800),
        rdT('كل بياناتك على الموبايل · مفيش حساب', k,
            size: 11, color: k.mute, maxLines: 1),
      ])),
      Icon(Icons.chevron_left, color: k.mute, size: 20),
    ]),
    padding: const EdgeInsets.all(13),
    tint: k.accent);

Widget settings1() => rdPhone(k, children: [
      rdTop(k, 'الإعدادات', badge: 0),
      const SizedBox(height: 6),
      rdPad(_account()),
      rdPad(rdSection(k, 'الشكل واللغة')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.palette,
                tint: _violet,
                title: 'شكل التطبيق',
                sub: 'ملوّن وودّى',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.dark_mode,
                tint: _slate,
                title: 'الوضع الليلى',
                sub: 'مقفول',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.translate,
                tint: _blue,
                title: 'اللغة',
                sub: 'العربية',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'بياناتك')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.backup,
                tint: _green,
                title: 'نسخة احتياطية',
                sub: 'آخر نسخة من 3 أيام',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.lock,
                tint: _amber,
                title: 'قفل التطبيق',
                sub: 'شغّال',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget settings2() => rdPhone(k, children: [
      rdTop(k, 'الإعدادات', badge: 0),
      const SizedBox(height: 6),
      rdPad(_account()),
      const SizedBox(height: 14),
      _tiles3([
        (Icons.palette, 'الشكل', _violet, 'ملوّن'),
        (Icons.dark_mode, 'الوضع الليلى', _slate, 'مقفول'),
        (Icons.translate, 'اللغة', _blue, 'عربى'),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.backup, 'نسخة احتياطية', _green, 'من 3 أيام'),
        (Icons.lock, 'قفل التطبيق', _amber, 'شغّال'),
        (Icons.notifications, 'التنبيهات', _rose, '12'),
      ]),
      const SizedBox(height: 11),
      _tiles3([
        (Icons.dashboard_customize, 'تخصيص', _cyan, null),
        (Icons.archive, 'الأرشيف', _teal, '9'),
        (Icons.info, 'عن التطبيق', _slate, '1.0'),
      ]),
    ]);

Widget settings3() => rdPhone(k, children: [
      rdTop(k, 'الإعدادات', badge: 0),
      const SizedBox(height: 6),
      rdPad(_account()),
      rdPad(Column(children: [
        _head('الشكل واللغة'),
        _flat(
            icon: Icons.palette,
            tint: _violet,
            title: 'شكل التطبيق',
            trail: 'ملوّن وودّى'),
        _flat(
            icon: Icons.dark_mode,
            tint: _slate,
            title: 'الوضع الليلى',
            trail: 'مقفول'),
        _flat(
            icon: Icons.translate,
            tint: _blue,
            title: 'اللغة',
            trail: 'العربية'),
        _flat(
            icon: Icons.dashboard_customize,
            tint: _cyan,
            title: 'تخصيص التطبيق',
            sub: 'رتّب البنود وأخفى اللى مش بتستعمله'),
        _head('بياناتك'),
        _flat(
            icon: Icons.backup,
            tint: _green,
            title: 'نسخة احتياطية',
            trail: 'من 3 أيام'),
        _flat(
            icon: Icons.lock,
            tint: _amber,
            title: 'قفل التطبيق',
            trail: 'شغّال'),
        _flat(icon: Icons.archive, tint: _teal, title: 'الأرشيف', trail: '9'),
        _head('تانى'),
        _flat(
            icon: Icons.notifications,
            tint: _rose,
            title: 'التنبيهات',
            trail: '12'),
        _flat(
            icon: Icons.info, tint: _slate, title: 'عن التطبيق', trail: '1.0'),
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
  testWidgets('rd batch 3', (tester) async {
    await loadShotFonts();
    await _three(
        tester, 'rd_9_wardrobe', wardrobe1(), wardrobe2(), wardrobe3());
    await _three(tester, 'rd_10_growth', growth1(), growth2(), growth3());
    await _three(tester, 'rd_11_tools', tools1(), tools2(), tools3());
    await _three(
        tester, 'rd_12_settings', settings1(), settings2(), settings3());
  });
}
