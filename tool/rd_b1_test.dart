// الدفعة ١ من الريديزاين — بند بند، ٣ ترتيبات لكل بند بالشكل «ملوّن وودّى».
//
// الشكل اتثبت، فالاختيار هنا بقى **الترتيب**: إزاى المعلومة متظبّطة جوّه
// الشاشة. نفس التلات ترتيبات فى كل بند عشان الاختيار يبقى قابل للمقارنة:
//   1 بطل + قوايم   ·   2 مربعات ملوّنة   ·   3 قايمة واحدة
//   flutter test tool/rd_b1_test.dart → build/design_shots/rd_<بند>.png
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
              style:
                  TextStyle(fontSize: 25, color: c, fontWeight: FontWeight.w900)),
          rdT(l, k, size: 12, w: FontWeight.w700, maxLines: 1),
        ]),
      ),
    );

/// عنوان صغير جوّه القايمة الواحدة — بديل الكارت.
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

// ═══════════════════════════ الرئيسية ═══════════════════════════

Widget _greet() => rdPad(Row(children: [
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

Widget _homeHero() => rdHero(k,
    icon: Icons.event,
    kicker: 'اللى جاى دلوقتى · بعد ساعتين',
    title: 'د. أحمد — أسنان',
    sub: 'عيادة المهندسين · 6 ش جامعة الدول',
    big: '6:00',
    bigSub: 'مساءً',
    primary: 'تم',
    secondary: 'تأجيل',
    colors: const [_blue, Color(0xFF60A5FA)]);

Widget home1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الرئيسية'),
      const SizedBox(height: 4),
      _greet(),
      const SizedBox(height: 14),
      rdPad(_homeHero()),
      rdPad(rdSection(k, 'خط يومك', trailing: '8 من 13 ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdBar(k, 0.62, 'إنجاز اليوم'),
            const SizedBox(height: 8),
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
          rdRow(k,
              icon: Icons.receipt_long,
              tint: _amber,
              title: 'فاتورة الكهربا',
              sub: 'فات · 27 سبتمبر'),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget home2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الرئيسية'),
      const SizedBox(height: 4),
      _greet(),
      const SizedBox(height: 14),
      rdPad(Row(children: [
        _tile(Icons.error_outline, '2', 'فاتك', _rose),
        const SizedBox(width: 11),
        _tile(Icons.schedule, '5', 'جاى دلوقتى', _amber),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.task_alt, '8', 'خلصت', _green),
        const SizedBox(width: 11),
        _tile(Icons.checklist, '3', 'مهامك', _violet),
      ])),
      rdPad(rdSection(k, 'اللى جاى دلوقتى')),
      rdPad(_homeHero()),
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
      ])),
    ]);

Widget home3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'الرئيسية'),
      const SizedBox(height: 4),
      _greet(),
      const SizedBox(height: 12),
      rdPad(rdCard(
          k,
          Row(children: [
            Expanded(
                child: rdBar(k, 0.62, 'إنجاز اليوم · 8 من 13')),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12))),
      rdPad(Column(children: [
        _head('فاتك', trail: '2'),
        _flat(
            icon: Icons.medication,
            tint: _rose,
            title: 'كونكور 5 مج',
            sub: '4:00 م',
            trail: 'فات'),
        _flat(
            icon: Icons.receipt_long,
            tint: _amber,
            title: 'فاتورة الكهربا',
            sub: '27 سبتمبر',
            trail: 'فات'),
        _head('دلوقتى'),
        _flat(
            icon: Icons.event,
            tint: _blue,
            title: 'د. أحمد — أسنان',
            sub: 'عيادة المهندسين',
            trail: '6:00'),
        _head('بعد كده'),
        _flat(
            icon: Icons.mosque,
            tint: _green,
            title: 'صلاة المغرب',
            sub: 'الجامع',
            trail: '6:12'),
        _flat(
            icon: Icons.fitness_center,
            tint: _violet,
            title: 'جيم — تمرين صدر',
            trail: '7:30'),
        _flat(
            icon: Icons.local_drink,
            tint: _cyan,
            title: 'مياه — فاضل 3 أكواب'),
        _head('خلصت', trail: '8'),
        _flat(
            icon: Icons.mosque,
            tint: _green,
            title: 'صلاة العصر',
            sub: '3:41 م',
            done: true),
      ])),
    ]);

// ═══════════════════════════ مواعيدى ═══════════════════════════

Widget _apptHero() => rdHero(k,
    icon: Icons.medical_services,
    kicker: 'أقرب موعد · بعد ساعتين',
    title: 'د. أحمد — أسنان',
    sub: 'عيادة المهندسين · 6 ش جامعة الدول',
    big: '6:00',
    bigSub: 'مساءً',
    primary: 'رحت',
    secondary: 'تأجيل',
    colors: const [_blue, Color(0xFF60A5FA)]);

Widget appt1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مواعيدى'),
      const SizedBox(height: 6),
      rdPad(_apptHero()),
      rdPad(rdSection(k, 'النهارده', trailing: '2')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.medical_services,
                tint: _blue,
                title: 'د. أحمد — أسنان',
                sub: 'عيادة المهندسين',
                trail: '6:00'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.science,
                tint: _violet,
                title: 'تحليل صورة دم',
                sub: 'معمل البرج',
                trail: '8:30'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'بكرة', trailing: '1')),
      rdPad(rdCard(
          k,
          rdRow(k,
              icon: Icons.build,
              tint: _amber,
              title: 'صيانة العربية',
              sub: 'تويوتا المعادى',
              trail: '10:00'),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'الأسبوع ده', trailing: '3 ›')),
      rdPad(rdCard(
          k,
          rdRow(k,
              icon: Icons.school,
              tint: _green,
              title: 'اجتماع المدرسة',
              sub: 'الخميس',
              trail: '4:00'),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget appt2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مواعيدى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.today, '2', 'النهارده', _blue),
        const SizedBox(width: 11),
        _tile(Icons.event_available, '1', 'بكرة', _amber),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.date_range, '5', 'الأسبوع ده', _violet),
        const SizedBox(width: 11),
        _tile(Icons.done_all, '12', 'اللى تمت', _green),
      ])),
      rdPad(rdSection(k, 'أقرب موعد')),
      rdPad(_apptHero()),
      rdPad(rdSection(k, 'بعد كده', trailing: 'الكل ›')),
      rdPad(Column(children: [
        rdRow(k,
            icon: Icons.science,
            tint: _violet,
            title: 'تحليل صورة دم',
            sub: 'معمل البرج · 8:30',
            box: true),
        rdRow(k,
            icon: Icons.build,
            tint: _amber,
            title: 'صيانة العربية',
            sub: 'بكرة · 10:00',
            box: true),
      ])),
    ]);

Widget appt3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مواعيدى'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['القادمة', 'اللى تمت', 'الكل'])),
      rdPad(Column(children: [
        _head('النهارده · 29 سبتمبر', trail: '2'),
        _flat(
            icon: Icons.medical_services,
            tint: _blue,
            title: 'د. أحمد — أسنان',
            sub: 'عيادة المهندسين',
            trail: '6:00'),
        _flat(
            icon: Icons.science,
            tint: _violet,
            title: 'تحليل صورة دم',
            sub: 'معمل البرج',
            trail: '8:30'),
        _head('بكرة · 30 سبتمبر', trail: '1'),
        _flat(
            icon: Icons.build,
            tint: _amber,
            title: 'صيانة العربية',
            sub: 'تويوتا المعادى',
            trail: '10:00'),
        _head('الخميس · 2 أكتوبر', trail: '2'),
        _flat(
            icon: Icons.school,
            tint: _green,
            title: 'اجتماع المدرسة',
            trail: '4:00'),
        _flat(
            icon: Icons.work,
            tint: _cyan,
            title: 'مقابلة شغل',
            sub: 'مدينة نصر',
            trail: '12:00'),
        _head('اللى تمت', trail: '12'),
        _flat(
            icon: Icons.medical_services,
            tint: _blue,
            title: 'د. منى — عيون',
            sub: '22 سبتمبر',
            done: true),
      ])),
    ]);

// ═══════════════════════════ مهامى ═══════════════════════════

Widget _taskHero() => rdHero(k,
    icon: Icons.priority_high,
    kicker: 'أهم حاجة النهارده',
    title: 'تسليم تقرير الشغل',
    sub: 'فاضل 3 ساعات · أولوية عالية',
    big: '2',
    bigSub: 'فاتت',
    primary: 'خلّصتها',
    secondary: 'تأجيل',
    colors: const [_rose, Color(0xFFFB7185)]);

Widget task1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مهامى'),
      const SizedBox(height: 6),
      rdPad(_taskHero()),
      rdPad(rdSection(k, 'فاتت', trailing: '2')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.receipt_long,
                tint: _rose,
                title: 'فاتورة الكهربا',
                sub: '27 سبتمبر'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.phone,
                tint: _rose,
                title: 'أكلّم ماما',
                sub: '28 سبتمبر'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'النهارده', trailing: '3')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.description,
                tint: _amber,
                title: 'تسليم تقرير الشغل',
                sub: 'قبل 9:00 م'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.shopping_cart,
                tint: _green,
                title: 'مشاوير السوبر ماركت'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'خلصت', trailing: '8 ›')),
      rdPad(rdCard(
          k,
          rdRow(k,
              icon: Icons.local_gas_station,
              tint: _green,
              title: 'بنزين العربية',
              done: true),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget task2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مهامى'),
      const SizedBox(height: 8),
      rdPad(Row(children: [
        _tile(Icons.error_outline, '2', 'فاتت', _rose),
        const SizedBox(width: 11),
        _tile(Icons.today, '3', 'النهارده', _amber),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(children: [
        _tile(Icons.schedule, '6', 'بعدين', _violet),
        const SizedBox(width: 11),
        _tile(Icons.task_alt, '8', 'خلصت', _green),
      ])),
      rdPad(rdSection(k, 'أهم حاجة النهارده')),
      rdPad(_taskHero()),
      rdPad(rdSection(k, 'المشاريع', trailing: 'الكل ›')),
      rdPad(Row(children: [
        Expanded(
            child: rdTile(k, Icons.home_work, 'تجديد الشقة', _cyan,
                value: '4 من 11')),
        const SizedBox(width: 11),
        Expanded(
            child: rdTile(k, Icons.flight_takeoff, 'سفر الصيف', _violet,
                value: '2 من 7')),
      ])),
    ]);

Widget task3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'مهامى'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['الكل', 'النهارده', 'المشاريع'])),
      rdPad(Column(children: [
        _head('فاتت', trail: '2'),
        _flat(
            icon: Icons.receipt_long,
            tint: _rose,
            title: 'فاتورة الكهربا',
            sub: '27 سبتمبر'),
        _flat(
            icon: Icons.phone, tint: _rose, title: 'أكلّم ماما', sub: '28 سبتمبر'),
        _head('النهارده', trail: '3'),
        _flat(
            icon: Icons.description,
            tint: _amber,
            title: 'تسليم تقرير الشغل',
            sub: 'قبل 9:00 م',
            trail: 'مهمة'),
        _flat(
            icon: Icons.shopping_cart,
            tint: _green,
            title: 'مشاوير السوبر ماركت'),
        _flat(
            icon: Icons.home_work,
            tint: _cyan,
            title: 'أكلّم النقاش',
            sub: 'تجديد الشقة'),
        _head('بعدين', trail: '6'),
        _flat(
            icon: Icons.flight_takeoff,
            tint: _violet,
            title: 'حجز تذاكر الصيف',
            sub: '15 أكتوبر'),
        _head('خلصت', trail: '8'),
        _flat(
            icon: Icons.local_gas_station,
            tint: _green,
            title: 'بنزين العربية',
            done: true),
      ])),
    ]);

// ═══════════════════════════ تذكيراتى ═══════════════════════════

Widget _noteCard(String title, String body, Color c, String when) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: k.tint(c),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.push_pin, size: 15, color: c),
          const SizedBox(width: 6),
          Expanded(child: rdT(title, k, size: 13, w: FontWeight.w800, maxLines: 1)),
        ]),
        const SizedBox(height: 7),
        rdT(body, k, size: 11.5, color: k.mute, maxLines: 3, height: 1.5),
        const SizedBox(height: 9),
        Row(children: [
          Icon(Icons.alarm, size: 13, color: c),
          const SizedBox(width: 4),
          rdT(when, k, size: 10.5, color: c, w: FontWeight.w800),
        ]),
      ]),
    );

Widget note1() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تذكيراتى'),
      const SizedBox(height: 6),
      rdPad(rdHero(k,
          icon: Icons.alarm,
          kicker: 'أقرب تذكير · بعد 40 دقيقة',
          title: 'تاخد الدوا بعد الأكل',
          sub: 'بيتكرر كل يوم 6:00 م',
          big: '6:00',
          bigSub: 'مساءً',
          primary: 'اتعمل',
          secondary: 'غفوة',
          colors: const [_amber, Color(0xFFFBBF24)])),
      rdPad(rdSection(k, 'مذكّرات مثبّتة', trailing: '3')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.push_pin,
                tint: _violet,
                title: 'مقاسات الشباك',
                sub: '120 × 90 — أوضة النوم',
                check: false),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.wifi,
                tint: _cyan,
                title: 'باسورد الراوتر',
                sub: 'مخفى — دوس تشوفه',
                check: false),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
      rdPad(rdSection(k, 'تذكيرات جاية', trailing: 'الكل ›')),
      rdPad(rdCard(
          k,
          Column(children: [
            rdRow(k,
                icon: Icons.cake,
                tint: _rose,
                title: 'عيد ميلاد سارة',
                sub: '4 أكتوبر',
                trail: 'سنوى'),
            Divider(color: k.line, height: 1),
            rdRow(k,
                icon: Icons.local_shipping,
                tint: _green,
                title: 'استلام الأوردر',
                sub: 'بكرة 11:00 ص'),
          ]),
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 2))),
    ]);

Widget note2() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تذكيراتى'),
      const SizedBox(height: 8),
      rdPad(rdChips(k, ['الكل', 'مثبّتة', 'عليها منبّه'])),
      const SizedBox(height: 14),
      rdPad(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _noteCard('تاخد الدوا', 'كونكور بعد الأكل، ومتاخدوش على معدة فاضية.',
                _amber, 'النهارده 6:00 م')),
        const SizedBox(width: 11),
        Expanded(
            child: _noteCard('مقاسات الشباك', '120 × 90 سم — أوضة النوم. الستارة 140.',
                _violet, 'من غير منبّه')),
      ])),
      const SizedBox(height: 11),
      rdPad(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _noteCard('عيد ميلاد سارة', 'أجيب التورتة من عند سعد. الشوكولاتة.',
                _rose, '4 أكتوبر · سنوى')),
        const SizedBox(width: 11),
        Expanded(
            child: _noteCard('باسورد الراوتر', 'مخفى — دوس عشان تشوفه.', _cyan,
                'من غير منبّه')),
      ])),
    ]);

Widget note3() => rdPhone(k, fab: rdFab(k), children: [
      rdTop(k, 'تذكيراتى'),
      const SizedBox(height: 8),
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
          rdT('دوّر فى التذكيرات…', k, size: 12, color: k.mute),
        ]),
      )),
      rdPad(Column(children: [
        _head('عليها منبّه', trail: '3'),
        _flat(
            icon: Icons.alarm,
            tint: _amber,
            title: 'تاخد الدوا بعد الأكل',
            sub: 'كل يوم 6:00 م',
            trail: 'بعد 40 د'),
        _flat(
            icon: Icons.local_shipping,
            tint: _green,
            title: 'استلام الأوردر',
            sub: 'بكرة 11:00 ص'),
        _flat(
            icon: Icons.cake,
            tint: _rose,
            title: 'عيد ميلاد سارة',
            sub: 'سنوى',
            trail: '4 أكتوبر'),
        _head('مثبّتة', trail: '2'),
        _flat(
            icon: Icons.push_pin,
            tint: _violet,
            title: 'مقاسات الشباك',
            sub: '120 × 90 — أوضة النوم',
            check: false),
        _flat(
            icon: Icons.wifi,
            tint: _cyan,
            title: 'باسورد الراوتر',
            sub: 'مخفى — دوس تشوفه',
            check: false),
        _head('من غير منبّه', trail: '9'),
        _flat(
            icon: Icons.notes,
            tint: _blue,
            title: 'قايمة السوبر ماركت',
            sub: 'لبن · عيش · جبنة',
            check: false),
      ])),
    ]);

// ═══════════════════════════ الرسم ═══════════════════════════

Future<void> _three(WidgetTester tester, String name, Widget a, Widget b,
        Widget c) async =>
    shot(
      tester,
      name,
      shotApp(
          rdTheme(k),
          rdTriptych(
              [(_t1, _n1, a), (_t2, _n2, b), (_t3, _n3, c)])),
      size: const Size(1152, 890),
      pixelRatio: 2,
    );

void main() {
  testWidgets('rd batch 1', (tester) async {
    await loadShotFonts();
    await _three(tester, 'rd_1_home', home1(), home2(), home3());
    await _three(tester, 'rd_2_appointments', appt1(), appt2(), appt3());
    await _three(tester, 'rd_3_tasks', task1(), task2(), task3());
    await _three(tester, 'rd_4_notes', note1(), note2(), note3());
  });
}
