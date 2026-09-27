// كل بنود التطبيق بشكل «يومك أولاً» — بيتبنوا من نفس الطقم
// (`design_a_kit.dart`) عشان يفضلوا متسقين.
//
//   flutter test tool/design_a_screens_test.dart
//   → build/design_shots/a_<البند>.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_a_kit.dart';
import 'shot_harness.dart';

const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFFF6B8A);
const _purple = Color(0xFF7C5CFF);
const _amber = Color(0xFFF2A93B);
const _teal = Color(0xFF14B8A6);

// ———————————————————— مواعيدى ————————————————————

Widget appointments() => aScreen(
      title: 'مواعيدى',
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.event,
              kicker: 'أقرب موعد',
              title: 'د. أحمد — أسنان',
              trailingBig: '6:00',
              trailingSmall: 'بعد 3 ساعات',
              primary: 'تم',
              primaryIcon: Icons.check,
              secondary: 'تأجيل',
              colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              extra: Row(children: [
                const Icon(Icons.place_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text('عيادة المهندسين — 6 ش جامعة الدول',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.9))),
              ]),
            ),
            const SizedBox(height: 20),
            aSection('النهارده وبكرة', trailing: '4 مواعيد'),
            aCard(Column(children: [
              aTimelineRow(
                  time: '6:00',
                  title: 'د. أحمد — أسنان',
                  sub: 'النهارده · عيادة المهندسين',
                  tint: _blue),
              aTimelineRow(
                  time: '9:00',
                  title: 'جرعة كونكور',
                  sub: 'النهارده · دوا يومى',
                  tint: _pink),
              aTimelineRow(
                  time: '10:30',
                  title: 'اجتماع الشغل',
                  sub: 'بكرة · أونلاين',
                  tint: _purple),
              aTimelineRow(
                  time: '4:00',
                  title: 'ميعاد العربية — صيانة',
                  sub: 'بكرة · توكيل مصر الجديدة',
                  tint: _amber,
                  last: true),
            ])),
            const SizedBox(height: 20),
            aSection('الأسبوع الجاى', trailing: 'عرض شهرى'),
            aCard(
              Column(children: [
                aListRow(
                    icon: Icons.cake_outlined,
                    tint: _pink,
                    title: 'عيد ميلاد ماما',
                    sub: 'الخميس 2 أكتوبر',
                    trailing: const Text('بعد 5 أيام',
                        style: TextStyle(fontSize: 11, color: aMuted))),
                aListRow(
                    icon: Icons.description_outlined,
                    tint: _amber,
                    title: 'تجديد رخصة القيادة',
                    sub: 'بتنتهى 8 أكتوبر',
                    trailing: const Text('بعد 11 يوم',
                        style: TextStyle(fontSize: 11, color: aMuted)),
                    divider: false),
              ]),
            ),
            const SizedBox(height: 90),
          ]),
          top: 8,
        ),
      ],
    );

// ———————————————————— مهامى ————————————————————

Widget tasks() => aScreen(
      title: 'مهامى',
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.bolt,
              kicker: 'ابدأ بيها دلوقتى',
              title: 'دهان الأوضة',
              trailingBig: '2',
              trailingSmall: 'من 4 خطوات',
              primary: 'خلّصتها',
              primaryIcon: Icons.check,
              secondary: 'ركّز 25 دقيقة',
              colors: const [Color(0xFF16B57E), Color(0xFF0E8C74)],
              extra: aHeroBar(0.5, 'مشروع «تجهيز الشقة» · باقى خطوتين'),
            ),
            const SizedBox(height: 18),
          ]),
          top: 8,
        ),
        aChips(const ['النهارده 3', 'بكرة 2', 'الكل 9', 'خلصت 12']),
        const SizedBox(height: 16),
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aSection('النهارده', trailing: 'واحدة خلصت'),
            aCard(Column(children: [
              aListRow(
                  check: true,
                  checked: true,
                  title: 'دفع فاتورة الغاز',
                  sub: 'خلصت 11:20 ص'),
              aListRow(
                  check: true,
                  title: 'دهان الأوضة',
                  sub: 'مشروع تجهيز الشقة · خطوتين باقيين',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Text('مهم',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444))),
                  )),
              aListRow(
                  check: true,
                  title: 'اتصل بشركة النت',
                  sub: 'من غير ميعاد',
                  divider: false),
            ])),
            const SizedBox(height: 18),
            aSection('بكرة'),
            aCard(Column(children: [
              aListRow(check: true, title: 'تجديد الباقة', sub: 'بكرة 12:00 م'),
              aListRow(
                  check: true,
                  title: 'شراء الدهانات',
                  sub: 'خطوة فى «دهان الأوضة»',
                  divider: false),
            ])),
            const SizedBox(height: 90),
          ]),
        ),
      ],
    );

// ———————————————————— تذكيراتى ————————————————————

Widget notes() => aScreen(
      title: 'تذكيراتى',
      fabIcon: Icons.edit,
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.edit_note,
              kicker: 'اكتب بسرعة',
              title: 'إيه اللى فى دماغك؟',
              primary: 'اكتب',
              primaryIcon: Icons.edit,
              secondary: 'سجّل بصوتك',
              colors: const [Color(0xFF7C5CFF), Color(0xFF4F32C9)],
            ),
            const SizedBox(height: 20),
            aSection('مثبّتة'),
            aCard(Column(children: [
              aListRow(
                icon: Icons.push_pin,
                tint: _purple,
                title: 'عندى بكره شغل الساعه 7:00 الصبح',
                sub: 'اتعدّلت امبارح',
                divider: false,
                trailing: Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: aAccent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.alarm, size: 11, color: aAccent),
                      SizedBox(width: 3),
                      Text('7:00 ص',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: aAccent)),
                    ]),
                  ),
                ]),
              ),
            ])),
            const SizedBox(height: 18),
            aSection('كل الملاحظات', trailing: '7 ملاحظات'),
            aCard(Column(children: [
              aListRow(
                  icon: Icons.sticky_note_2_outlined,
                  tint: _amber,
                  title: 'قائمة السوبر ماركت: زيت · رز · جبنة',
                  sub: 'من ساعتين',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_arrow, size: 12, color: _teal),
                      SizedBox(width: 2),
                      Text('0:12',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _teal)),
                    ]),
                  )),
              aListRow(
                  icon: Icons.sticky_note_2_outlined,
                  tint: _amber,
                  title: 'رقم الفنى: 01223456789',
                  sub: 'امبارح'),
              aListRow(
                  icon: Icons.sticky_note_2_outlined,
                  tint: _amber,
                  title: 'فكرة: أعمل جدول مذاكرة للأولاد',
                  sub: 'من 3 أيام',
                  divider: false),
            ])),
            const SizedBox(height: 90),
          ]),
          top: 8,
        ),
      ],
    );

// ———————————————————— الأهداف ————————————————————

Widget goals() {
  Widget goalRow(String title, String sub, double v, Color tint,
          {bool last = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: last
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: aLine, width: 1))),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: aInk)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 11, color: aMuted)),
                ],
              ),
            ),
            Text('${(v * 100).round()}٪',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tint)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: aLine,
                color: tint),
          ),
        ]),
      );

  return aScreen(
    title: 'الأهداف',
    children: [
      aPad(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          aHero(
            icon: Icons.flag,
            kicker: 'أقرب هدف للنهاية',
            title: 'أقرا 12 كتاب',
            trailingBig: '75٪',
            trailingSmall: '9 من 12',
            primary: 'سجّل تقدّم',
            primaryIcon: Icons.add,
            secondary: 'التفاصيل',
            colors: const [Color(0xFFF2A93B), Color(0xFFC77D12)],
            extra: aHeroBar(0.75, 'باقى 3 كتب · وفاضل 3 شهور على نهاية السنة'),
          ),
          const SizedBox(height: 20),
          aSection('أهدافك', trailing: '5 أهداف'),
          aCard(Column(children: [
            goalRow('أقرا 12 كتاب', 'هدف سنوى · 9 من 12', 0.75, _amber),
            goalRow('أوصل 80 كيلو', 'من 92 كيلو · نزلت 7', 0.58, _pink),
            goalRow('أوفّر 50 ألف', 'المحفظة · 22 ألف', 0.44, aAccent),
            goalRow('أحفظ جزء عمّ', '12 سورة من 37', 0.32, _teal),
            goalRow('كورس إنجليزى', '12 من 30 وحدة', 0.40, _purple,
                last: true),
          ])),
          const SizedBox(height: 90),
        ]),
        top: 8,
      ),
    ],
  );
}

// ———————————————————— صلاتى ————————————————————

Widget prayer() {
  Widget tool(IconData i, String label, Color c) => Column(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18)),
          child: Icon(i, color: c, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: aInk)),
      ]);

  return aScreen(
    title: 'صلاتى',
    fab: false,
    children: [
      aPad(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          aHero(
            icon: Icons.mosque,
            kicker: 'الجاية دلوقتى',
            title: 'صلاة العصر',
            trailingBig: '3:48',
            trailingSmall: 'فاضل 52 دقيقة',
            primary: 'صلّيت',
            primaryIcon: Icons.check,
            secondary: 'كل المواقيت',
          ),
          const SizedBox(height: 20),
          aSection('صلوات النهارده', trailing: '2 من 5'),
          aCard(Column(children: [
            aTimelineRow(
                time: '5:12',
                title: 'الفجر',
                sub: 'اتصلّت',
                tint: aAccent,
                done: true),
            aTimelineRow(
                time: '12:05',
                title: 'الظهر',
                sub: 'اتصلّت',
                tint: aAccent,
                done: true),
            aTimelineRow(
                time: '3:48',
                title: 'العصر',
                sub: 'الجاية',
                tint: aAccentLight),
            aTimelineRow(
                time: '6:20', title: 'المغرب', sub: '', tint: aMuted),
            aTimelineRow(
                time: '7:40',
                title: 'العشاء',
                sub: '',
                tint: aMuted,
                last: true),
          ])),
          const SizedBox(height: 20),
          aSection('برنامجى الدينى', trailing: '40٪ النهارده'),
          aCard(Column(children: [
            aListRow(
                icon: Icons.menu_book,
                tint: _purple,
                title: 'ورد القرآن',
                sub: 'صفحتين من ختمتك · الصفحة 184',
                trailing: const Icon(Icons.chevron_left,
                    size: 20, color: aMuted)),
            aListRow(
                icon: Icons.wb_twilight,
                tint: _amber,
                title: 'أذكار المساء',
                sub: 'لسه ما اتقرتش',
                trailing:
                    const Icon(Icons.chevron_left, size: 20, color: aMuted),
                divider: false),
          ])),
          const SizedBox(height: 20),
          aSection('أدوات'),
          const SizedBox(height: 2),
        ]),
        top: 8,
      ),
      aPad(
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          tool(Icons.menu_book, 'المصحف', _teal),
          tool(Icons.auto_stories, 'القصص\nوالسيرة', _purple),
          tool(Icons.favorite, 'الأذكار', _pink),
          tool(Icons.explore, 'القبلة', _blue),
          tool(Icons.calculate, 'الزكاة', _amber),
        ]),
        bottom: 26,
      ),
    ],
  );
}

// ———————————————————— فلوسى ————————————————————

Widget money() => aScreen(
      title: 'فلوسى',
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.account_balance_wallet,
              kicker: 'رصيدك دلوقتى',
              title: '25895 ج.م',
              trailingBig: '0 ج.م',
              trailingSmall: 'مصروف الشهر',
              primary: 'سجّل مصروف',
              primaryIcon: Icons.add,
              secondary: 'سجّل دخل',
              colors: const [Color(0xFF0F9D7B), Color(0xFF0A6E63)],
              extra: aHeroBar(0.0, 'متاح للصرف النهارده: 863 ج.م'),
            ),
            const SizedBox(height: 20),
            aSection('محتاج انتباهك', trailing: '3 بنود'),
            aCard(Column(children: [
              aListRow(
                  icon: Icons.receipt_long,
                  tint: const Color(0xFFEF4444),
                  title: 'فاتورة الكهربا',
                  sub: 'مستحقة النهارده',
                  trailing: const Text('320 ج.م',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444)))),
              aListRow(
                  icon: Icons.sell_outlined,
                  tint: _purple,
                  title: 'محمود — سلفة',
                  sub: 'ليك عنده',
                  trailing: const Text('3000 ج.م',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _purple)),
                  divider: false),
            ])),
            const SizedBox(height: 20),
            aSection('بنود فلوسك'),
          ]),
          top: 8,
        ),
        aPad(
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
            children: [
              aHubTile(Icons.account_balance_wallet, 'المحفظة', aAccent,
                  sub: '25895 ج.م'),
              aHubTile(Icons.savings_outlined, 'الادخار', _teal,
                  sub: '3 أهداف'),
              aHubTile(Icons.sell_outlined, 'الديون والسلف', _purple,
                  sub: '3000 ليك'),
              aHubTile(Icons.groups_outlined, 'الجمعيات', _amber,
                  sub: 'دورك 4'),
              aHubTile(Icons.subscriptions_outlined, 'الاشتراكات', _blue,
                  sub: '4 شهرية', badge: 2),
              aHubTile(Icons.favorite_outline, 'قائمة الأمنيات', _pink,
                  sub: '6 حاجات'),
            ],
          ),
          bottom: 90,
        ),
      ],
    );

// ———————————————————— صحتى ————————————————————

Widget health() => aScreen(
      title: 'صحتى',
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.local_drink,
              kicker: 'مياه النهارده',
              title: '0 من 2000 مل',
              trailingBig: '0٪',
              primary: 'شربت كوباية',
              primaryIcon: Icons.add,
              secondary: 'كل الصحة',
              colors: const [Color(0xFFFF6B8A), Color(0xFFD63B63)],
              extra: aHeroBar(0.0, 'مشيت 2400 خطوة · نمت 6 ساعات'),
            ),
            const SizedBox(height: 20),
            aSection('النهارده', trailing: 'جرعة واحدة فاضلة'),
            aCard(Column(children: [
              aListRow(
                  check: true,
                  checked: true,
                  title: 'كونكور 5 — الصبح',
                  sub: 'اتاخدت 8:00 ص'),
              aListRow(
                  check: true,
                  title: 'كونكور 5 — بالليل',
                  sub: '9:00 م',
                  divider: false),
            ])),
            const SizedBox(height: 20),
            aSection('بنود صحتك'),
          ]),
          top: 8,
        ),
        aPad(
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              aHubTile(Icons.dashboard_outlined, 'لوحة الصحة', _pink,
                  sub: 'نظرة شاملة'),
              aHubTile(Icons.favorite_outline, 'الصحة', _pink,
                  sub: 'أدوية · مزاج · ملف طبى'),
              aHubTile(Icons.fitness_center, 'الرياضة', _purple,
                  sub: 'جيم · مشى · تقدّم'),
              aHubTile(Icons.restaurant_outlined, 'النظام الغذائى', aAccent,
                  sub: 'وجبات · صيام · وصفات'),
            ],
          ),
          bottom: 90,
        ),
      ],
    );

// ———————————————————— ملابسى ————————————————————

Widget wardrobe() {
  Widget piece(String name, Color c, IconData icon) => Column(children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 34, color: c),
          ),
        ),
        const SizedBox(height: 6),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: aInk)),
      ]);

  return aScreen(
    title: 'ملابسى',
    children: [
      aPad(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          aHero(
            icon: Icons.auto_awesome,
            kicker: 'الجو النهارده 29° · صحو',
            title: 'ألبس إيه النهارده؟',
            primary: 'اقترحلى طقم',
            primaryIcon: Icons.auto_awesome,
            secondary: 'سلة الغسيل 4',
            colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          const SizedBox(height: 20),
          aSection('طقم النهارده المقترح', trailing: 'كاجوال'),
          aCard(
            SizedBox(
              height: 118,
              child: Row(children: [
                Expanded(child: piece('بولو أخضر', aAccent, Icons.checkroom)),
                const SizedBox(width: 10),
                Expanded(child: piece('جينز أزرق', _blue, Icons.checkroom)),
                const SizedBox(width: 10),
                Expanded(
                    child: piece('كوتشى أبيض', aMuted, Icons.directions_walk)),
                const SizedBox(width: 10),
                Expanded(child: piece('ساعة فضى', _purple, Icons.watch)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
        ]),
        top: 8,
      ),
      aChips(const ['الكل 21', 'قميص', 'بنطلون', 'جاكيت', 'حذاء', 'إكسسوار']),
      const SizedBox(height: 16),
      aPad(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          aSection('خزانتك', trailing: '21 قطعة'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              piece('قميص أبيض', aMuted, Icons.checkroom),
              piece('بولو أخضر', aAccent, Icons.checkroom),
              piece('تيشيرت رمادى', aMuted, Icons.checkroom),
              piece('جينز أزرق', _blue, Icons.checkroom),
              piece('بنطلون أسود', aInk, Icons.checkroom),
              piece('جاكيت جينز', _blue, Icons.checkroom),
            ],
          ),
          const SizedBox(height: 90),
        ]),
      ),
    ],
  );
}

// ———————————————————— تطوّرى ————————————————————

Widget growth() => aScreen(
      title: 'تطوّرى',
      fab: false,
      children: [
        aPad(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            aHero(
              icon: Icons.menu_book,
              kicker: 'بتقرا دلوقتى',
              title: 'العادات الذرية',
              trailingBig: '45٪',
              trailingSmall: '145 من 320',
              primary: 'سجّل صفحات',
              primaryIcon: Icons.add,
              secondary: 'كل الكتب',
              colors: const [Color(0xFF7C5CFF), Color(0xFF4F32C9)],
              extra: aHeroBar(0.45, 'لو قريت 10 صفحات يوميًا هتخلّصه فى 18 يوم'),
            ),
            const SizedBox(height: 20),
            aSection('سلاسلك', trailing: 'أطول سلسلة 21 يوم'),
            aCard(Column(children: [
              aListRow(
                  icon: Icons.local_fire_department,
                  tint: _amber,
                  title: 'قراءة يومية',
                  sub: '12 يوم ورا بعض',
                  trailing: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('12',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _amber)),
                    SizedBox(width: 3),
                    Icon(Icons.local_fire_department, size: 15, color: _amber),
                  ])),
              aListRow(
                  icon: Icons.school_outlined,
                  tint: _blue,
                  title: 'كورس Excel متقدم',
                  sub: '12 من 20 وحدة',
                  trailing: const Text('60٪',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _blue)),
                  divider: false),
            ])),
            const SizedBox(height: 20),
            aSection('بنود تطوّرك'),
          ]),
          top: 8,
        ),
        aPad(
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
            children: [
              aHubTile(Icons.school_outlined, 'التعلّم', _blue, sub: 'كورسين'),
              aHubTile(Icons.menu_book_outlined, 'القراءة', _purple,
                  sub: '3 كتب'),
              aHubTile(Icons.insights_outlined, 'تحليلات العادات', aAccent,
                  sub: '5 عادات'),
              aHubTile(Icons.flag_outlined, 'التحديات', _amber,
                  sub: 'تحدى شغّال'),
              aHubTile(Icons.book_outlined, 'اليوميات', _teal, sub: '24 يومية'),
              aHubTile(Icons.smoke_free, 'عدّاد الإقلاع', _pink,
                  sub: '45 يوم'),
              aHubTile(Icons.diversity_3, 'صلة الرحم', _pink, sub: 'واحد مستحق',
                  badge: 1),
              aHubTile(Icons.key_outlined, 'كلمات السر', aInk, sub: '18 حساب'),
            ],
          ),
          bottom: 26,
        ),
      ],
    );

// ———————————————————— السايدبار ————————————————————

Widget drawer() {
  Widget row(IconData i, String label, Color c,
          {bool on = false, int badge = 0}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          if (on)
            Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                    color: aAccent,
                    borderRadius: BorderRadius.circular(999)))
          else
            const SizedBox(width: 4),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: c.withValues(alpha: 0.26))),
            child: Icon(i, size: 21, color: c),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? aAccent : aInk)),
          if (badge > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999)),
              child: Text('$badge',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ]),
      );

  const divider = Divider(
      height: 14, thickness: 0.8, indent: 68, endIndent: 16, color: aLine);

  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: [
          // كارت الحساب
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(colors: [
                  aAccent.withValues(alpha: 0.16),
                  aAccentLight.withValues(alpha: 0.08)
                ])),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF2FDE9B), Color(0xFF0E8C74)])),
                child: const Icon(Icons.star, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حسابك',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: aInk)),
                    Text('إدارة حسابك',
                        style: TextStyle(fontSize: 11.5, color: aMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: aMuted),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              row(Icons.home_rounded, 'الرئيسية', aAccent, on: true),
              divider,
              row(Icons.event_note, 'مواعيدى', _blue),
              divider,
              row(Icons.checklist, 'مهامى', aAccent),
              divider,
              row(Icons.sticky_note_2_outlined, 'تذكيراتى', _purple),
              divider,
              row(Icons.flag_outlined, 'الأهداف', _amber),
              const Divider(
                  height: 20, thickness: 0.8, indent: 28, color: aLine),
              row(Icons.mosque, 'صلاتى', _teal),
              divider,
              row(Icons.favorite_outline, 'صحتى', _pink),
              divider,
              row(Icons.account_balance_wallet, 'فلوسى', aAccent, badge: 9),
              divider,
              row(Icons.checkroom, 'ملابسى', _blue),
              divider,
              row(Icons.self_improvement, 'تطوّرى', _purple),
              divider,
              row(Icons.grid_view_rounded, 'المتابعة والأدوات', _teal),
              const Divider(
                  height: 20, thickness: 0.8, indent: 28, color: aLine),
              row(Icons.medical_services_outlined, 'كارت الطوارئ',
                  const Color(0xFFEF4444)),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(22)),
            child: IntrinsicHeight(
              child: Row(children: [
                for (final e in const [
                  (Icons.settings_outlined, 'الإعدادات', 'كل الضبط'),
                  (Icons.translate, 'اللغة', 'عربى'),
                  (Icons.dark_mode_outlined, 'الوضع', 'فاتح'),
                ]) ...[
                  Expanded(
                    child: Column(children: [
                      Icon(e.$1, size: 21, color: aInk),
                      const SizedBox(height: 5),
                      Text(e.$2,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: aInk)),
                      Text(e.$3,
                          style: const TextStyle(fontSize: 10, color: aMuted)),
                    ]),
                  ),
                  if (e.$1 != Icons.dark_mode_outlined)
                    const VerticalDivider(
                        width: 1, thickness: 0.8, color: aLine),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.22))),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                  SizedBox(width: 7),
                  Text('تسجيل الخروج',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444))),
                ]),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('رندر بنود التطبيق بشكل «يومك أولاً»', (tester) async {
    await loadShotFonts();
    // ارتفاع كل شاشة = ارتفاع محتواها، مش 844 — عشان الصورة توريه التصميم
    // كامل بدل ما تقصّ صف فى نصّه ويبان كأنه مكسور.
    final screens = <String, (Widget, double)>{
      '01_appointments': (appointments(), 880),
      '02_tasks': (tasks(), 940),
      '03_notes': (notes(), 790),
      '04_goals': (goals(), 900),
      '05_prayer': (prayer(), 1010),
      '06_money': (money(), 1010),
      '07_health': (health(), 940),
      '08_wardrobe': (wardrobe(), 1010),
      '09_growth': (growth(), 1020),
      '10_drawer': (drawer(), 1090),
    };
    for (final e in screens.entries) {
      final (w, h) = e.value;
      final f = await shot(tester, 'a_${e.key}', shotApp(aTheme(), w),
          size: Size(390, h), pixelRatio: 2);
      expect(f.lengthSync(), greaterThan(10000), reason: e.key);
    }
  });
}
