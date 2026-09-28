// الدفعة ٢: الأهداف · صلاتى · صحتى · فلوسى — نفس التلات ترتيبات.
//   flutter test tool/rd_b2_test.dart → build/design_shots/rd_5..8_*.png
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
        bool check = true}) =>
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

/// سطر هدف بشريط تقدّم.
Widget _goalRow(IconData i, String name, String sub, double v, Color c) =>
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
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              rdT(name, k, size: 13.5, w: FontWeight.w700, maxLines: 1),
              rdT(sub, k, size: 10.5, color: k.mute, maxLines: 1),
            ]),
          ),
          rdT('${(v * 100).round()}%', k, size: 13, color: c, w: FontWeight.w900),
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

// ═══════════════════════════ الأهداف ═══════════════════════════

Widget _goalHero() => rdHero(k,
    icon: Icons.flag,
    kicker: 'أقرب هدف يخلص',
    title: 'أقرا 12 كتاب السنة دى',
    sub: 'فاضل 3 كتب · باقى 94 يوم',
    big: '75%',
    bigSub: '9 من 12',
    primary: 'سجّل تقدّم',
    primaryIcon: Icons.add,
    secondary: 'تفاصيل',
    colors: const [_violet, Color(0xFFA78BFA)]);

Widget goal1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الأهداف'),
      const SizedBox(height: 6),
      rdPad(_goalHero()),
      rdPad(rdSection(k, 'شغّالة دلوقتى', trailing: '4')),
      rdPad(rdCard(
          k,
          Column(children: [
            _goalRow(Icons.menu_book, 'أقرا 12 كتاب', '9 من 12 كتاب', 0.75,
                _violet),
            Divider(color: k.line, height: 1),
            _goalRow(Icons.monitor_weight, 'أنزل 10 كيلو', '6.5 من 10 كيلو',
                0.65, _teal),
            Divider(color: k.line, height: 1),
            _goalRow(Icons.savings, 'أوفّر 50 ألف', '32 من 50 ألف', 0.64,
                _green),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10))),
      rdPad(rdSection(k, 'خلصت', trailing: '3 ›')),
      rdPad(rdCard(
          k,
          rdRow(k,
              icon: Icons.school,
              tint: _green,
              title: 'كورس الإنجليزى',
              sub: 'خلص 12 أغسطس',
              done: true),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget goal2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الأهداف'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.flag, '4', 'شغّالة', _violet),
        const SizedBox(width: 11),
        _tile(Icons.emoji_events, '3', 'خلصت', _green),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.donut_large, '68%', 'متوسط التقدّم', _amber),
        const SizedBox(width: 11),
        _tile(Icons.event_busy, '2', 'متأخرة', _rose),
      ])),
      rdPad(rdSection(k, 'أقرب هدف يخلص')),
      rdPad(_goalHero()),
      rdPad(rdSection(k, 'الباقى', trailing: 'الكل ›')),
      rdPad(Row(children: [
        Expanded(
            child: rdTile(k, Icons.monitor_weight, 'أنزل 10 كيلو', _teal,
                value: '65%')),
        const SizedBox(width: 11),
        Expanded(
            child:
                rdTile(k, Icons.savings, 'أوفّر 50 ألف', _green, value: '64%')),
      ])),
    ]);

Widget goal3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الأهداف'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['شغّالة', 'خلصت', 'الكل'])),
      rdPad(Column(children: [
        _head('قرّبت تخلص', trail: '2'),
        _goalRow(Icons.menu_book, 'أقرا 12 كتاب السنة دى', 'فاضل 3 كتب · 94 يوم',
            0.75, _violet),
        Divider(color: k.line, height: 1),
        _goalRow(Icons.monitor_weight, 'أنزل 10 كيلو', 'فاضل 3.5 كيلو', 0.65,
            _teal),
        _head('ماشية', trail: '2'),
        Divider(color: k.line, height: 1),
        _goalRow(Icons.savings, 'أوفّر 50 ألف', 'فاضل 18 ألف', 0.64, _green),
        Divider(color: k.line, height: 1),
        _goalRow(Icons.directions_run, 'أجرى 500 كيلو', '180 من 500', 0.36,
            _cyan),
        _head('متأخرة', trail: '2'),
        Divider(color: k.line, height: 1),
        _goalRow(Icons.mosque, 'أحفظ جزء عمّ', 'مافيش تقدّم من 21 يوم', 0.2,
            _rose),
      ])),
    ]);

// ═══════════════════════════ صلاتى ═══════════════════════════

Widget _prayerHero() => rdHero(k,
    icon: Icons.mosque,
    kicker: 'الصلاة الجاية · بعد 31 دقيقة',
    title: 'المغرب',
    sub: 'القاهرة · باقى على الأذان 31 دقيقة',
    big: '6:12',
    bigSub: 'مساءً',
    primary: 'صلّيتها',
    secondary: 'الأذكار',
    colors: const [_green, Color(0xFF34D399)]);

Widget _prayerChip(String name, String time, bool done) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: done ? k.tint(_green) : k.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: done ? _green.withValues(alpha: 0.3) : k.line)),
        child: Column(children: [
          Icon(done ? Icons.check_circle : Icons.circle_outlined,
              size: 15, color: done ? _green : k.mute),
          const SizedBox(height: 5),
          rdT(name, k, size: 11.5, w: FontWeight.w800, maxLines: 1),
          rdT(time, k, size: 10, color: k.mute, maxLines: 1),
        ]),
      ),
    );

Widget prayer1() => rdPhone(k, fab: rdFab(k, icon: Icons.menu_book), children: [
      rdTop(k, 'صلاتى'),
      const SizedBox(height: 6),
      rdPad(_prayerHero()),
      const SizedBox(height: 14),
      rdPad(Row(children: [
        _prayerChip('الفجر', '5:02', true),
        _prayerChip('الظهر', '12:36', true),
        _prayerChip('العصر', '3:41', true),
        _prayerChip('المغرب', '6:12', false),
        _prayerChip('العشا', '7:32', false),
      ])),
      rdPad(rdSection(k, 'وردى النهارده', trailing: '3 من 5')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.wb_sunny,
                tint: _amber,
                title: 'أذكار الصباح',
                sub: 'اتعملت 7:10 ص',
                done: true),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.nightlight,
                tint: _violet,
                title: 'أذكار المساء',
                sub: 'بعد المغرب'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.menu_book,
                tint: _teal,
                title: 'وردك من القرآن',
                sub: '5 من 10 صفحات',
                trail: '50%'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'الختمة', trailing: 'صفحة 218')),
      rdPad(rdCard(k, rdBar(k, 0.36, 'باقى 386 صفحة · تقريبًا 39 يوم'),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13))),
    ]);

Widget prayer2() => rdPhone(k, fab: rdFab(k, icon: Icons.menu_book), children: [
      rdTop(k, 'صلاتى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.mosque, '3/5', 'صلّيت', _green),
        const SizedBox(width: 11),
        _tile(Icons.menu_book, '218', 'صفحة الختمة', _blue),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.auto_awesome, '1/2', 'الأذكار', _amber),
        const SizedBox(width: 11),
        _tile(Icons.nights_stay, '12', 'أيام صيام', _violet),
      ])),
      rdPad(rdSection(k, 'الصلاة الجاية')),
      rdPad(_prayerHero()),
      rdPad(rdSection(k, 'أدوات', trailing: 'الكل ›')),
      rdPad(Row(children: [
        Expanded(child: rdTile(k, Icons.explore, 'القبلة', _cyan)),
        const SizedBox(width: 11),
        Expanded(child: rdTile(k, Icons.menu_book, 'المصحف', _teal)),
        const SizedBox(width: 11),
        Expanded(child: rdTile(k, Icons.favorite, 'السبحة', _pink)),
      ])),
    ]);

Widget prayer3() => rdPhone(k, fab: rdFab(k, icon: Icons.menu_book), children: [
      rdTop(k, 'صلاتى'),
      const SizedBox(height: 8),
      rdPad(rdCard(
          k,
          Row(children: [
            const Icon(Icons.mosque, color: _green, size: 20),
            const SizedBox(width: 9),
            Expanded(
                child: rdT('المغرب بعد 31 دقيقة · 6:12 م', k,
                    size: 13.5, w: FontWeight.w800)),
            rdT('صلّيتها ›', k, size: 12, color: _green, w: FontWeight.w800),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          tint: _green)),
      rdPad(Column(children: [
        _head('صلوات النهارده', trail: '3 من 5'),
        _flat(
            icon: Icons.wb_twilight,
            tint: _green,
            title: 'الفجر',
            sub: '5:02 ص',
            done: true),
        _flat(
            icon: Icons.light_mode,
            tint: _green,
            title: 'الظهر',
            sub: '12:36 م',
            done: true),
        _flat(
            icon: Icons.wb_sunny,
            tint: _green,
            title: 'العصر',
            sub: '3:41 م',
            done: true),
        _flat(
            icon: Icons.nightlight_round,
            tint: _amber,
            title: 'المغرب',
            sub: '6:12 م',
            trail: 'بعد 31 د'),
        _flat(
            icon: Icons.dark_mode, tint: _violet, title: 'العشاء', sub: '7:32 م'),
        _head('وردك', trail: '3 من 5'),
        _flat(
            icon: Icons.auto_awesome,
            tint: _amber,
            title: 'أذكار الصباح',
            sub: '7:10 ص',
            done: true),
        _flat(
            icon: Icons.nights_stay,
            tint: _violet,
            title: 'أذكار المساء',
            sub: 'بعد المغرب'),
        _flat(
            icon: Icons.menu_book,
            tint: _teal,
            title: 'وردك من القرآن',
            sub: '5 من 10 صفحات',
            trail: '50%'),
      ])),
    ]);

// ═══════════════════════════ صحتى ═══════════════════════════

Widget _healthHero() => rdHero(k,
    icon: Icons.medication,
    kicker: 'الجرعة الجاية · بعد ساعة',
    title: 'كونكور 5 مج',
    sub: 'بعد الأكل · فاضل 12 قرص فى العلبة',
    big: '6:00',
    bigSub: 'مساءً',
    primary: 'اتاخدت',
    secondary: 'تأجيل',
    colors: const [_rose, Color(0xFFFB7185)]);

Widget health1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'صحتى'),
      const SizedBox(height: 6),
      rdPad(_healthHero()),
      rdPad(rdSection(k, 'النهارده', trailing: 'تفاصيل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdBar(k, 0.62, 'مياه · 5 من 8 أكواب', color: _cyan),
            const SizedBox(height: 12),
            rdBar(k, 0.74, 'خطوات · 7,400 من 10,000', color: _green),
            const SizedBox(height: 12),
            rdBar(k, 0.81, 'نوم · 6 س 30 د من 8', color: _violet),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14))),
      rdPad(rdSection(k, 'أرقامك', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.monitor_weight,
                tint: _teal,
                title: 'الوزن',
                sub: 'من 3 أيام',
                trail: '84.5 كجم',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.favorite,
                tint: _rose,
                title: 'الضغط',
                sub: 'امبارح',
                trail: '12/8',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget health2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'صحتى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.local_drink, '5/8', 'مياه', _cyan),
        const SizedBox(width: 11),
        _tile(Icons.directions_walk, '7.4k', 'خطوات', _green),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.medication, '2/3', 'أدوية', _rose),
        const SizedBox(width: 11),
        _tile(Icons.bedtime, '6:30', 'نوم', _violet),
      ])),
      rdPad(rdSection(k, 'الجرعة الجاية')),
      rdPad(_healthHero()),
      rdPad(rdSection(k, 'أقسام صحتك', trailing: 'الكل ›')),
      rdPad(Row(children: [
        Expanded(child: rdTile(k, Icons.fitness_center, 'الرياضة', _violet)),
        const SizedBox(width: 11),
        Expanded(child: rdTile(k, Icons.restaurant, 'الأكل', _amber)),
        const SizedBox(width: 11),
        Expanded(child: rdTile(k, Icons.medical_information, 'الملف', _blue)),
      ])),
    ]);

Widget health3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'صحتى'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['النهارده', 'الأسبوع', 'الكل'])),
      rdPad(Column(children: [
        _head('أدويتك', trail: '2 من 3'),
        _flat(
            icon: Icons.medication,
            tint: _green,
            title: 'أسبرين 75',
            sub: 'الصبح · اتاخد 8:00 ص',
            done: true),
        _flat(
            icon: Icons.medication,
            tint: _rose,
            title: 'كونكور 5 مج',
            sub: 'بعد الأكل',
            trail: '6:00 م'),
        _head('عدّادات اليوم'),
        _flat(
            icon: Icons.local_drink,
            tint: _cyan,
            title: 'مياه',
            sub: '5 من 8 أكواب',
            trail: '62%',
            check: false),
        _flat(
            icon: Icons.directions_walk,
            tint: _green,
            title: 'خطوات',
            sub: '7,400 من 10,000',
            trail: '74%',
            check: false),
        _flat(
            icon: Icons.bedtime,
            tint: _violet,
            title: 'نوم',
            sub: '6 س 30 د',
            trail: '81%',
            check: false),
        _head('آخر قياساتك'),
        _flat(
            icon: Icons.monitor_weight,
            tint: _teal,
            title: 'الوزن',
            sub: 'من 3 أيام',
            trail: '84.5',
            check: false),
        _flat(
            icon: Icons.favorite,
            tint: _rose,
            title: 'الضغط',
            sub: 'امبارح',
            trail: '12/8',
            check: false),
      ])),
    ]);

// ═══════════════════════════ فلوسى ═══════════════════════════

Widget _catRow(IconData i, String name, String amount, double v, Color c,
        String left) =>
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

Widget _monthNav() => rdPad(Row(children: [
      Icon(Icons.chevron_right, color: k.mute, size: 22),
      Expanded(
          child: rdT('سبتمبر 2026', k,
              size: 15, w: FontWeight.w800, align: TextAlign.center)),
      Icon(Icons.chevron_left, color: k.mute, size: 22),
    ]));

Widget _moneyHero() => rdHero(k,
    icon: Icons.account_balance_wallet,
    kicker: 'فاضل معاك لغاية آخر الشهر',
    title: '4,250 جنيه',
    sub: 'الشهر ماشى كويس · يعنى 141 جنيه فى اليوم',
    big: '66%',
    bigSub: 'اتصرف',
    primary: 'صرفت',
    primaryIcon: Icons.remove,
    secondary: 'قبضت',
    colors: const [Color(0xFF059669), _green]);

Widget money1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى'),
      _monthNav(),
      const SizedBox(height: 8),
      rdPad(_moneyHero()),
      rdPad(rdSection(k, 'راحت فين؟', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            _catRow(Icons.shopping_cart, 'أكل وشرب', '3,100', 0.78, _amber,
                'من 4,000'),
            Divider(color: k.line, height: 1),
            _catRow(Icons.directions_car, 'مواصلات', '1,450', 0.48, _blue,
                'من 3,000'),
            Divider(color: k.line, height: 1),
            _catRow(Icons.medical_services, 'صحة', '900', 0.9, _pink,
                'من 1,000'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10))),
      rdPad(rdSection(k, 'عليّا إيه؟', trailing: '3 فواتير ›')),
      rdPad(rdCard(
          k,
          rdRow(k,
              icon: Icons.bolt,
              tint: _amber,
              title: 'كهربا',
              sub: 'فات ميعادها · 27 سبتمبر',
              trail: '420'),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget money2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى'),
      _monthNav(),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.arrow_downward, '12,400', 'دخل', _green),
        const SizedBox(width: 11),
        _tile(Icons.arrow_upward, '8,150', 'صرفت', _rose),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.savings, '4,250', 'فاضل', _teal),
        const SizedBox(width: 11),
        _tile(Icons.event_repeat, '3', 'فواتير', _amber),
      ])),
      rdPad(rdSection(k, 'راحت فين؟', trailing: 'الكل ›')),
      rdPad(Row(children: [
        Expanded(
            child: rdTile(k, Icons.shopping_cart, 'أكل وشرب', _amber,
                value: '3,100')),
        const SizedBox(width: 11),
        Expanded(
            child: rdTile(k, Icons.directions_car, 'مواصلات', _blue,
                value: '1,450')),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        Expanded(
            child:
                rdTile(k, Icons.medical_services, 'صحة', _pink, value: '900')),
        const SizedBox(width: 11),
        Expanded(
            child: rdTile(k, Icons.home, 'البيت', _violet, value: '2,700')),
      ])),
    ]);

Widget money3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'فلوسى'),
      _monthNav(),
      const SizedBox(height: 10),
      rdPad(rdCard(
          k,
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  rdT('فاضل معاك', k, size: 11.5, color: k.mute),
                  rdT('4,250 جنيه', k, size: 20, w: FontWeight.w900),
                ])),
            rdT('66% اتصرف', k, size: 12, color: _green, w: FontWeight.w800),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          tint: _green)),
      rdPad(Column(children: [
        _head('راحت فين؟', trail: '8,150'),
        _flat(
            icon: Icons.shopping_cart,
            tint: _amber,
            title: 'أكل وشرب',
            sub: 'من 4,000',
            trail: '3,100',
            check: false),
        _flat(
            icon: Icons.directions_car,
            tint: _blue,
            title: 'مواصلات',
            sub: 'من 3,000',
            trail: '1,450',
            check: false),
        _flat(
            icon: Icons.medical_services,
            tint: _pink,
            title: 'صحة',
            sub: 'من 1,000',
            trail: '900',
            check: false),
        _head('هيجيلى كام؟', trail: '12,400'),
        _flat(
            icon: Icons.payments,
            tint: _green,
            title: 'المرتب',
            sub: 'كل 1 فى الشهر',
            trail: '11,000'),
        _head('عليّا إيه؟', trail: '3'),
        _flat(
            icon: Icons.bolt,
            tint: _rose,
            title: 'كهربا',
            sub: 'فات ميعادها · 27 سبتمبر',
            trail: '420'),
        _flat(
            icon: Icons.water_drop,
            tint: _cyan,
            title: 'مياه',
            sub: '5 أكتوبر',
            trail: '180'),
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
  testWidgets('rd batch 2', (tester) async {
    await loadShotFonts();
    await _three(tester, 'rd_5_goals', goal1(), goal2(), goal3());
    await _three(tester, 'rd_6_prayer', prayer1(), prayer2(), prayer3());
    await _three(tester, 'rd_7_health', health1(), health2(), health3());
    await _three(tester, 'rd_8_money', money1(), money2(), money3());
  });
}
