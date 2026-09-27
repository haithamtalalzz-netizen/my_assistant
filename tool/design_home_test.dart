// 6 اتجاهات تصميم للشاشة الرئيسية — **نفس البيانات بالظبط** فى كلها عشان
// المقارنة تبقى عادلة. بترندر صور PNG حقيقية من ودجت Flutter، مش موك HTML.
//
//   flutter test tool/design_home_test.dart
//   → build/design_shots/home_<اسم الاتجاه>.png
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shot_harness.dart';

// ————————————————— البيانات (واحدة لكل الاتجاهات) —————————————————

class Item {
  final String title, value, sub;
  final IconData icon;
  final Color tint;
  const Item(this.title, this.value, this.sub, this.icon, this.tint);
}

const greeting = 'مساء الخير';
const dateLine = 'الأحد 27 سبتمبر 2026 — 16 ربيع الثانى 1448هـ';
const progressLabel = 'إنجاز اليوم';
const progressHint = 'ابدأ يومك — أول خطوة تفرق';

const cards = <Item>[
  Item('الصلاة', '0/5', 'صلوات النهارده', Icons.mosque, Color(0xFF2FDE9B)),
  Item('الصحة', '0/2000', 'مل مياه النهارده', Icons.favorite, Color(0xFFFF6B8A)),
  Item('الفلوس', '0 ج.م', 'مصروف الشهر', Icons.account_balance_wallet,
      Color(0xFF3DC4A0)),
  Item('مهامى', '0', 'مفيش مستحق النهارده', Icons.checklist, Color(0xFFF2A93B)),
  Item('الديون', '3000 ج.م', 'صافى ليك', Icons.sell, Color(0xFF7C5CFF)),
  Item('الدورة', '—', 'سجّلى أول دورة', Icons.favorite_border,
      Color(0xFFE85D9E)),
];

const quick = <Item>[
  Item('الصحة', '', '', Icons.favorite, Color(0xFFFF6B8A)),
  Item('صوت', '', '', Icons.mic, Color(0xFF7C5CFF)),
  Item('مواعيد', '', '', Icons.event, Color(0xFF3B82F6)),
  Item('الفلوس', '', '', Icons.account_balance_wallet, Color(0xFF3DC4A0)),
];

ThemeData _base(Color seed, Brightness b) => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: b,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b),
    );

/// شريط علوى موحّد الشكل بين الاتجاهات (☰ + العنوان + بحث/جرس).
Widget _bar(Color fg, {Color? badge}) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(children: [
        Icon(Icons.menu, color: fg, size: 26),
        const SizedBox(width: 14),
        Text('الرئيسية',
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.w700, color: fg)),
        const Spacer(),
        Stack(clipBehavior: Clip.none, children: [
          Icon(Icons.notifications_none, color: fg, size: 24),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: badge ?? const Color(0xFFEF4444),
                  shape: BoxShape.circle),
              child: const Text('5',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(width: 14),
        Icon(Icons.search, color: fg, size: 24),
      ]),
    );

// ————————————————— 1) بطاقات ناعمة —————————————————

Widget soft() {
  const bg = Color(0xFFF6F8FA);
  const ink = Color(0xFF111827);
  Widget card(Item i) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F0B1B33), blurRadius: 18, offset: Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: i.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(i.icon, size: 18, color: i.tint),
              ),
              const SizedBox(width: 8),
              Text(i.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
            ]),
            const Spacer(),
            Text(i.value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 2),
            Text(i.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A93A5))),
          ],
        ),
      );

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _bar(ink),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(greeting,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16B57E))),
                const SizedBox(height: 4),
                const Text(dateLine,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF8A93A5))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2FDE9B).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.bolt, size: 18, color: Color(0xFF16B57E)),
                        const SizedBox(width: 6),
                        const Text(progressLabel,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16B57E))),
                        const Spacer(),
                        const Text('0٪',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16B57E))),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: const LinearProgressIndicator(
                            value: 0.02,
                            minHeight: 7,
                            backgroundColor: Color(0xFFDDE3EA),
                            color: Color(0xFF16B57E)),
                      ),
                      const SizedBox(height: 8),
                      const Text(progressHint,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF5B6475))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('إجراءات سريعة',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final q in quick) ...[
                      Expanded(
                        child: Column(children: [
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x0D0B1B33),
                                      blurRadius: 12,
                                      offset: Offset(0, 4))
                                ]),
                            child: Icon(q.icon, color: q.tint, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(q.title,
                              style: const TextStyle(
                                  fontSize: 10.5, color: Color(0xFF5B6475))),
                        ]),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                              color: const Color(0xFF2FDE9B),
                              borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 6),
                        const Text('إضافة',
                            style: TextStyle(
                                fontSize: 10.5, color: Color(0xFF5B6475))),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('كروتك',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.32,
              children: [for (final c in cards) card(c)],
            ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————— 2) خطوط نظيفة —————————————————

Widget outline() {
  const ink = Color(0xFF0B1220);
  const line = Color(0xFFE4E7EC);
  const accent = Color(0xFF16B57E);
  Widget card(Item i) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: line, width: 1.3),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(i.icon, size: 17, color: ink),
              const SizedBox(width: 7),
              Text(i.title,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475467))),
            ]),
            const Spacer(),
            Text(i.value,
                style: const TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 3),
            Text(i.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF98A2B3))),
          ],
        ),
      );

  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _bar(ink, badge: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(greeting,
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 6),
                const Text(dateLine,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF98A2B3))),
                const SizedBox(height: 22),
                Row(children: [
                  const Text(progressLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467))),
                  const Spacer(),
                  const Text('0٪',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ]),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                      color: line, borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.03,
                    child: Container(
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                const SizedBox(height: 26),
                Row(children: [
                  for (final q in quick) ...[
                    Expanded(
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(color: line, width: 1.3),
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(q.icon, color: ink, size: 21),
                        ),
                        const SizedBox(height: 7),
                        Text(q.title,
                            style: const TextStyle(
                                fontSize: 10.5, color: Color(0xFF667085))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(14)),
                        child:
                            const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 7),
                      const Text('إضافة',
                          style: TextStyle(
                              fontSize: 10.5, color: Color(0xFF667085))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 28),
                Row(children: [
                  const Text('كروتك',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 1.3, color: line)),
                ]),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.32,
              children: [for (final c in cards) card(c)],
            ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————— 3) داكن فاخر —————————————————

Widget dark() {
  const bg = Color(0xFF0C0F14);
  const surface = Color(0xFF161B23);
  const accent = Color(0xFF2FDE9B);
  Widget card(Item i) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: i.tint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(i.icon, size: 17, color: i.tint),
              ),
              const SizedBox(width: 8),
              Text(i.title,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.72))),
            ]),
            const Spacer(),
            Text(i.value,
                style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(i.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.5, color: Colors.white.withValues(alpha: 0.42))),
          ],
        ),
      );

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _bar(Colors.white),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(greeting,
                    style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: accent)),
                const SizedBox(height: 4),
                Text(dateLine,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.45))),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF14332B), Color(0xFF16243A)]),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.bolt, size: 18, color: accent),
                        const SizedBox(width: 6),
                        const Text(progressLabel,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const Spacer(),
                        const Text('0٪',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: 0.02,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: accent),
                      ),
                      const SizedBox(height: 10),
                      Text(progressHint,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  for (final q in quick) ...[
                    Expanded(
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06))),
                          child: Icon(q.icon, color: q.tint, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(q.title,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.white.withValues(alpha: 0.55))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6))
                            ]),
                        child: const Icon(Icons.add,
                            color: Color(0xFF07231A), size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text('إضافة',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 22),
                const Text('كروتك',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.32,
              children: [for (final c in cards) card(c)],
            ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————— 4) بلوكات ملوّنة —————————————————

Widget blocks() {
  const bg = Color(0xFFF2F4F8);
  Widget card(Item i) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [i.tint, Color.lerp(i.tint, Colors.black, 0.28)!],
          ),
          boxShadow: [
            BoxShadow(
                color: i.tint.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(i.icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(i.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ]),
            const Spacer(),
            Text(i.value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(i.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.82))),
          ],
        ),
      );

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _bar(const Color(0xFF111827)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF16B57E), Color(0xFF0E7C79)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(greeting,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(dateLine,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Text('$progressLabel 0٪',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const Spacer(),
                        Text(progressHint,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.white.withValues(alpha: 0.85))),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: 0.02,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  for (final q in quick) ...[
                    Expanded(
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                              color: q.tint,
                              borderRadius: BorderRadius.circular(18)),
                          child: Icon(q.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(q.title,
                            style: const TextStyle(
                                fontSize: 10.5, color: Color(0xFF475467))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(18)),
                        child:
                            const Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 6),
                      const Text('إضافة',
                          style: TextStyle(
                              fontSize: 10.5, color: Color(0xFF475467))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 20),
                const Text('كروتك',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
              children: [for (final c in cards) card(c)],
            ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————— 5) ورقى هادى —————————————————

Widget paper() {
  const bg = Color(0xFFFBF8F3);
  const ink = Color(0xFF1C1917);
  const muted = Color(0xFF8A8175);
  const rule = Color(0xFFE7E0D5);
  const accent = Color(0xFF14746F);

  Widget row(Item i, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: rule, width: 1)),
        ),
        child: Row(children: [
          Icon(i.icon, size: 19, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: ink)),
                const SizedBox(height: 2),
                Text(i.sub, style: const TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
          Text(i.value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
        ]),
      );

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _bar(ink, badge: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(greeting,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        height: 1.2)),
                const SizedBox(height: 6),
                const Text(dateLine,
                    style: TextStyle(fontSize: 11.5, color: muted)),
                const SizedBox(height: 20),
                Container(height: 1, color: rule),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('0٪',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          height: 1)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(progressLabel,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: ink)),
                        SizedBox(height: 2),
                        Text(progressHint,
                            style: TextStyle(fontSize: 11, color: muted)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(height: 1, color: rule),
                const SizedBox(height: 18),
                Row(children: [
                  for (final q in quick) ...[
                    Expanded(
                      child: Column(children: [
                        Icon(q.icon, size: 24, color: ink),
                        const SizedBox(height: 8),
                        Text(q.title,
                            style: const TextStyle(fontSize: 11, color: muted)),
                      ]),
                    ),
                  ],
                  Expanded(
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: accent, shape: BoxShape.circle),
                        child: const Icon(Icons.add,
                            size: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('إضافة',
                          style: TextStyle(fontSize: 11, color: muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 22),
                const Text('كروتك',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                for (var i = 0; i < cards.length; i++)
                  row(cards[i], last: i == cards.length - 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————— 6) ويدجتس —————————————————

Widget widgets() {
  const bg = Color(0xFFEFF1F5);
  const ink = Color(0xFF111827);

  Widget tile(Item i, {bool wide = false}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14101828), blurRadius: 20, offset: Offset(0, 8))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: wide
            ? Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: i.tint.withValues(alpha: 0.14),
                      shape: BoxShape.circle),
                  child: Icon(i.icon, size: 24, color: i.tint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(i.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const SizedBox(height: 2),
                      Text(i.sub,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF98A2B3))),
                    ],
                  ),
                ),
                Text(i.value,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: i.tint)),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: i.tint.withValues(alpha: 0.14),
                        shape: BoxShape.circle),
                    child: Icon(i.icon, size: 18, color: i.tint),
                  ),
                  const Spacer(),
                  Text(i.value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: i.tint)),
                  const SizedBox(height: 1),
                  Text(i.title,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  Text(i.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF98A2B3))),
                ],
              ),
      );

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _bar(ink),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: ink)),
                SizedBox(height: 3),
                Text(dateLine,
                    style: TextStyle(fontSize: 11, color: Color(0xFF98A2B3))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 88, child: tile(cards[0], wide: true)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: SizedBox(height: 150, child: tile(cards[1]))),
            const SizedBox(width: 14),
            Expanded(child: SizedBox(height: 150, child: tile(cards[2]))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: SizedBox(height: 150, child: tile(cards[3]))),
            const SizedBox(width: 14),
            Expanded(child: SizedBox(height: 150, child: tile(cards[4]))),
          ]),
          const SizedBox(height: 14),
          SizedBox(height: 88, child: tile(cards[5], wide: true)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14101828),
                      blurRadius: 20,
                      offset: Offset(0, 8))
                ]),
            child: Row(children: [
              for (final q in quick)
                Expanded(
                  child: Column(children: [
                    Icon(q.icon, color: q.tint, size: 24),
                    const SizedBox(height: 6),
                    Text(q.title,
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF667085))),
                  ]),
                ),
              Expanded(
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Color(0xFF2FDE9B), shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text('إضافة',
                      style: TextStyle(
                          fontSize: 10.5, color: Color(0xFF667085))),
                ]),
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}

void main() {
  final designs = <String, (Widget, Brightness)>{
    '1_soft': (soft(), Brightness.light),
    '2_outline': (outline(), Brightness.light),
    '3_dark': (dark(), Brightness.dark),
    '4_blocks': (blocks(), Brightness.light),
    '5_paper': (paper(), Brightness.light),
    '6_widgets': (widgets(), Brightness.light),
  };

  testWidgets('رندر 6 اتجاهات تصميم للرئيسية', (tester) async {
    await loadShotFonts();
    for (final e in designs.entries) {
      final (w, b) = e.value;
      final f = await shot(tester, 'home_${e.key}',
          shotApp(_base(const Color(0xFF2FDE9B), b), w),
          pixelRatio: 2);
      expect(f.lengthSync(), greaterThan(10000), reason: e.key);
    }
  });
}
