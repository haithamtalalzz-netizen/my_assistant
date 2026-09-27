// ٣ **هياكل** جديدة للشاشة الرئيسية — مختلفة فى الترتيب نفسه، مش فى القشرة.
// (الجولة الأولى كانت ٤ قشور لهيكل واحد؛ دى بتضيف تنويع حقيقى.)
//
//   flutter test tool/design_layouts_test.dart
//   → build/design_shots/layout_<الاسم>.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_home_test.dart' show Item, cards, greeting, dateLine;
import 'shot_harness.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF8A93A5);
const _accent = Color(0xFF16B57E);
const _bg = Color(0xFFF6F8FA);

ThemeData _theme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2FDE9B)),
    );

/// بند فى خط اليوم.
class Ev {
  final String time, title, sub;
  final IconData icon;
  final Color tint;
  final bool done;
  const Ev(this.time, this.title, this.sub, this.icon, this.tint,
      {this.done = false});
}

const day = <Ev>[
  Ev('٥:١٢', 'الفجر', 'اتصلّت', Icons.mosque, _accent, done: true),
  Ev('١٢:٠٥', 'الظهر', 'اتصلّت', Icons.mosque, _accent, done: true),
  Ev('٣:٤٨', 'العصر', 'الصلاة الجاية', Icons.mosque, Color(0xFF2FDE9B)),
  Ev('٦:٠٠', 'د. أحمد — أسنان', 'عيادة المهندسين', Icons.event,
      Color(0xFF3B82F6)),
  Ev('٩:٠٠', 'جرعة الدوا', 'كونكور ٥', Icons.medication, Color(0xFFFF6B8A)),
  Ev('٩:٣٠', 'مشى ٣٠ دقيقة', 'عادة يومية', Icons.directions_walk,
      Color(0xFFF2A93B)),
  Ev('١٠:٠٠', 'ورد القرآن', 'صفحتين', Icons.menu_book, Color(0xFF7C5CFF)),
];

Widget _topBar({bool compact = false}) => Padding(
      padding: EdgeInsets.fromLTRB(18, compact ? 10 : 14, 18, 6),
      child: Row(children: [
        const Icon(Icons.menu, color: _ink, size: 25),
        const SizedBox(width: 14),
        const Text('الرئيسية',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
        const Spacer(),
        Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.notifications_none, color: _ink, size: 23),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
              child: const Text('٥',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(width: 14),
        const Icon(Icons.search, color: _ink, size: 23),
      ]),
    );

// ——————————————— أ) «يومك أولاً» ———————————————
// الفكرة: أكبر حاجة فى الشاشة = اللى جاى دلوقتى، وتحتها خط يومك بالساعة.
// الأرقام (الكروت) بتنزل تحت لإنها مرجع، مش اللى بتحتاجه أول ما تفتح.

Widget focusFirst() {
  Widget evRow(Ev e, {bool last = false}) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                  color: e.done ? _accent : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: e.done ? _accent : e.tint, width: 2.4)),
            ),
            if (!last)
              Expanded(
                  child: Container(width: 2, color: const Color(0xFFE6EAF0))),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: e.done ? _muted : _ink,
                              decoration: e.done
                                  ? TextDecoration.lineThrough
                                  : null)),
                      const SizedBox(height: 1),
                      Text(e.sub,
                          style:
                              const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ),
                ),
                Text(e.time,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: e.done ? _muted : e.tint)),
              ]),
            ),
          ),
        ]),
      );

  Widget chip(Item i) => Container(
        width: 108,
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F0B1B33), blurRadius: 14, offset: Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i.icon, size: 17, color: i.tint),
            const SizedBox(height: 8),
            Text(i.value,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
            Text(i.title,
                style: const TextStyle(fontSize: 10.5, color: _muted)),
          ],
        ),
      );

  return Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: ListView(padding: EdgeInsets.zero, children: [
        _topBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(dateLine,
                  style: TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(height: 14),
              // البطل: اللى جاى دلوقتى
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF16B57E), Color(0xFF0E8C74)]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x3316B57E),
                        blurRadius: 22,
                        offset: Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.mosque,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الجاية دلوقتى',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.white.withValues(alpha: 0.85))),
                          const Text('صلاة العصر',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      const Spacer(),
                      const Column(children: [
                        Text('٣:٤٨',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('فاضل ٥٢ دقيقة',
                            style: TextStyle(
                                fontSize: 10, color: Colors.white70)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14)),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16, color: _accent),
                                SizedBox(width: 5),
                                Text('صلّيت',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _accent)),
                              ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.55))),
                          child: const Text('كل المواقيت',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Text('خط يومك',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const Spacer(),
                Text('٢ من ٧ خلصوا',
                    style: TextStyle(fontSize: 11.5, color: _muted)),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0F0B1B33),
                          blurRadius: 16,
                          offset: Offset(0, 6))
                    ]),
                child: Column(children: [
                  for (var i = 0; i < day.length; i++)
                    evRow(day[i], last: i == day.length - 1),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('أرقامك',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [for (final c in cards) chip(c)],
          ),
        ),
        const SizedBox(height: 22),
      ]),
    ),
  );
}

// ——————————————— ب) «تبويبات تحت» ———————————————
// الفكرة: التنقّل ينزل لشريط سفلى (٥ بنود بإيدك)، والرئيسية تبقى
// «اللى محتاج منك دلوقتى» بس — مش كل الأرقام.

Widget bottomNav() {
  Widget need(IconData ic, Color c, String t, String s, String btn) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D0B1B33), blurRadius: 14, offset: Offset(0, 5))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(ic, size: 20, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(s, style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(999)),
            child: Text(btn,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
      );

  Widget navItem(IconData ic, String label, bool on) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
                color: on ? _accent.withValues(alpha: 0.14) : null,
                borderRadius: BorderRadius.circular(999)),
            child: Icon(ic, size: 22, color: on ? _accent : _muted),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  color: on ? _accent : _muted)),
        ]),
      );

  return Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      bottom: false,
      child: ListView(padding: EdgeInsets.zero, children: [
        _topBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(greeting,
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
              const SizedBox(height: 3),
              const Text(dateLine,
                  style: TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.priority_high,
                      size: 14, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 8),
                const Text('محتاج منك دلوقتى',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const Spacer(),
                Text('٣ بنود', style: const TextStyle(fontSize: 11.5, color: _muted)),
              ]),
              const SizedBox(height: 12),
              need(Icons.mosque, _accent, 'صلاة العصر', 'فاضل ٥٢ دقيقة',
                  'صلّيت'),
              need(Icons.event, const Color(0xFF3B82F6), 'د. أحمد — أسنان',
                  'النهارده ٦:٠٠ م', 'تفاصيل'),
              need(Icons.medication, const Color(0xFFFF6B8A), 'جرعة كونكور',
                  '٩:٠٠ م', 'اتاخدت'),
              const SizedBox(height: 10),
              Row(children: [
                const Text('لمحة سريعة',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const Spacer(),
                Text('كل الكروت ‹',
                    style: const TextStyle(fontSize: 11.5, color: _accent)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                for (final c in cards.take(3)) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x0D0B1B33),
                                blurRadius: 12,
                                offset: Offset(0, 4))
                          ]),
                      child: Column(children: [
                        Icon(c.icon, size: 18, color: c.tint),
                        const SizedBox(height: 7),
                        Text(c.value,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        Text(c.title,
                            style:
                                const TextStyle(fontSize: 10.5, color: _muted)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ]),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ]),
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x140B1B33), blurRadius: 18, offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 14),
      child: Row(children: [
        navItem(Icons.home_rounded, 'الرئيسية', true),
        navItem(Icons.event_note, 'مواعيدى', false),
        navItem(Icons.checklist, 'مهامى', false),
        navItem(Icons.mosque, 'صلاتى', false),
        navItem(Icons.grid_view_rounded, 'المزيد', false),
      ]),
    ),
    floatingActionButton: Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: _accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: _accent.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    ),
  );
}

// ——————————————— ج) «مدمج» ———————————————
// الفكرة: كل حاجة فى شاشة واحدة **من غير تمرير** — حلقة إنجاز + كروت
// صغيرة ٣ فى الصف + قايمة اليوم مضغوطة.

Widget dense() {
  Widget mini(Item i) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEFF4)),
        ),
        child: Column(children: [
          Icon(i.icon, size: 16, color: i.tint),
          const SizedBox(height: 6),
          Text(i.value,
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          Text(i.title, style: const TextStyle(fontSize: 9.5, color: _muted)),
        ]),
      );

  Widget line(Ev e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(e.done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18, color: e.done ? _accent : const Color(0xFFCBD3DE)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(e.title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: e.done ? _muted : _ink,
                    decoration: e.done ? TextDecoration.lineThrough : null)),
          ),
          Text(e.time,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: e.done ? _muted : e.tint)),
        ]),
      );

  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _topBar(compact: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(alignment: Alignment.center, children: [
                  const SizedBox(
                    width: 62,
                    height: 62,
                    child: CircularProgressIndicator(
                        value: 0.4,
                        strokeWidth: 6,
                        backgroundColor: Color(0xFFEBEFF4),
                        color: _accent),
                  ),
                  const Text('٤٠٪',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ]),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    SizedBox(height: 2),
                    Text(dateLine,
                        style: TextStyle(fontSize: 10.5, color: _muted)),
                    SizedBox(height: 4),
                    Text('٢ من ٧ خلصوا — الجاية: العصر ٣:٤٨',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accent)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.16,
              children: [for (final c in cards) mini(c)],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('يومك',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(999)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, size: 13, color: Colors.white),
                        SizedBox(width: 3),
                        Text('ضيف',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  for (final e in day) line(e),
                  const Spacer(),
                  Row(children: [
                    for (final q in const [
                      (Icons.favorite, 'الصحة', Color(0xFFFF6B8A)),
                      (Icons.mic, 'صوت', Color(0xFF7C5CFF)),
                      (Icons.event, 'مواعيد', Color(0xFF3B82F6)),
                      (
                        Icons.account_balance_wallet,
                        'الفلوس',
                        Color(0xFF3DC4A0)
                      ),
                    ])
                      Expanded(
                        child: Column(children: [
                          Icon(q.$1, size: 20, color: q.$3),
                          const SizedBox(height: 4),
                          Text(q.$2,
                              style: const TextStyle(
                                  fontSize: 10, color: _muted)),
                        ]),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

void main() {
  testWidgets('رندر ٣ هياكل جديدة', (tester) async {
    await loadShotFonts();
    final all = {
      'A_focus': focusFirst(),
      'B_bottomnav': bottomNav(),
      'C_dense': dense(),
    };
    for (final e in all.entries) {
      final f = await shot(tester, 'layout_${e.key}', shotApp(_theme(), e.value),
          pixelRatio: 2);
      expect(f.lengthSync(), greaterThan(10000), reason: e.key);
    }
  });
}
