// طقم الريديزاين — كل بند بيتبنى منه، بالتلات مظاهر.
//
// ليه طقم واحد: لو كل بند اتصمّم لوحده التطبيق يطلع مفكّك — شاشة شكلها
// كده وشاشة شكلها كده. هنا الشكل **قيمة** (`RdLook`) والقطع بتتلوّن منها،
// فاختيار المستخدم لشكل بيتطبّق على البنود كلها بسطر واحد.
//
// مصايد اتلاقت قبل كده والطقم ده بيتفاداها:
//  - علامة الصح والزائد والنار مش موجودين فى خط Cairo → مربّعات. أيقونات بدلهم.
//  - Icons.trending_up عليها matchTextDirection فبتتعكس فى RTL وتقرا «نازل».
//  - التطبيق بيعرض أرقام لاتينية، فالموك لازم يطابق الواقع.
import 'package:flutter/material.dart';

class RdLook {
  final String name;
  final String note;
  final Color bg, surface, ink, mute, line, accent, accent2, onAccent;
  final double radius;
  final bool tinted; // كل قسم بلونه الباهى
  final bool dark;
  const RdLook({
    required this.name,
    required this.note,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.mute,
    required this.line,
    required this.accent,
    required this.accent2,
    required this.onAccent,
    required this.radius,
    required this.tinted,
    required this.dark,
  });

  List<BoxShadow> get shadow => dark
      ? const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))
        ]
      : const [
          BoxShadow(
              color: Color(0x12142A4A), blurRadius: 18, offset: Offset(0, 7))
        ];

  /// خلفية باهية من لون — للمظهر الملوّن، وحلّ وسط فى الباقى.
  Color tint(Color c) => dark
      ? Color.alphaBlend(c.withValues(alpha: 0.16), surface)
      : Color.alphaBlend(c.withValues(alpha: 0.10), Colors.white);
}

const rdClean = RdLook(
  name: 'نضيف وواسع',
  note: 'أبيض · مسافات · لون واحد',
  bg: Color(0xFFF6F7FA),
  surface: Colors.white,
  ink: Color(0xFF0F172A),
  mute: Color(0xFF7A8699),
  line: Color(0xFFE8EBF1),
  accent: Color(0xFF4F46E5),
  accent2: Color(0xFF6366F1),
  onAccent: Colors.white,
  radius: 18,
  tinted: false,
  dark: false,
);

const rdFriendly = RdLook(
  name: 'ملوّن وودّى',
  note: 'كل حاجة بلونها · حروف كبيرة',
  bg: Color(0xFFFFFCF7),
  surface: Colors.white,
  ink: Color(0xFF17232E),
  mute: Color(0xFF77838F),
  line: Color(0xFFF0E9DF),
  accent: Color(0xFF12B981),
  accent2: Color(0xFF34D399),
  onAccent: Colors.white,
  radius: 26,
  tinted: true,
  dark: false,
);

const rdFocus = RdLook(
  name: 'غامق ومركّز',
  note: 'حاجة واحدة قدّامك · أرقام كبيرة',
  bg: Color(0xFF0A1020),
  surface: Color(0xFF161E33),
  ink: Color(0xFFF2F5FA),
  mute: Color(0xFF93A1BC),
  line: Color(0xFF26314C),
  accent: Color(0xFF22D3EE),
  accent2: Color(0xFF38BDF8),
  onAccent: Color(0xFF07101E),
  radius: 20,
  tinted: false,
  dark: true,
);

ThemeData rdTheme(RdLook k) => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: k.dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: k.bg,
      colorScheme: ColorScheme.fromSeed(
          seedColor: k.accent,
          brightness: k.dark ? Brightness.dark : Brightness.light),
    );

/// 🔴 نصّ لاتينى جوّه جملة عربية بيتقلب: «O+» بتطلع «+O» ورقم التليفون
/// «0100 123 4567» بيطلع «4567 123 0100» لإن الـbidi بيعيد ترتيب
/// المجموعات. العزل (U+2066 … U+2069) بيثبّت اتجاهه.
String ltr(String s) => '\u2066$s\u2069';

// ————————————————— قطع —————————————————

Text rdT(String s, RdLook k,
        {double size = 13,
        Color? color,
        FontWeight w = FontWeight.w600,
        TextAlign? align,
        int? maxLines,
        double? height}) =>
    Text(s,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: size,
            color: color ?? k.ink,
            fontWeight: w,
            height: height));

Widget rdTop(RdLook k, String title, {bool back = false, int badge = 4}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(children: [
        Icon(back ? Icons.arrow_forward : Icons.menu, color: k.ink, size: 24),
        const SizedBox(width: 13),
        Expanded(
            child: rdT(title, k, size: 19, w: FontWeight.w800, maxLines: 1)),
        if (badge > 0)
          Stack(clipBehavior: Clip.none, children: [
            Icon(Icons.notifications_none, color: k.ink, size: 22),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
      ]),
    );

Widget rdCard(RdLook k, Widget child,
        {EdgeInsets padding = const EdgeInsets.all(15), Color? tint}) =>
    Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tint != null && k.tinted ? k.tint(tint) : k.surface,
        borderRadius: BorderRadius.circular(k.radius),
        border: Border.all(
            color: tint != null && k.tinted
                ? tint.withValues(alpha: 0.22)
                : k.line),
        boxShadow: k.tinted ? null : k.shadow,
      ),
      child: child,
    );

Widget rdSection(RdLook k, String title, {String? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 9, top: 18),
      child: Row(children: [
        Expanded(
            child: rdT(title, k, size: 15, w: FontWeight.w800, maxLines: 1)),
        if (trailing != null)
          rdT(trailing, k, size: 11.5, color: k.accent, w: FontWeight.w700),
      ]),
    );

/// بطل: «اللى جاى دلوقتى» بلون متدرّج.
Widget rdHero(
  RdLook k, {
  required IconData icon,
  required String kicker,
  required String title,
  String? sub,
  required String big,
  required String bigSub,
  String? primary,
  IconData primaryIcon = Icons.check,
  String? secondary,
  List<Color>? colors,
}) {
  final c = colors ?? [k.accent, k.accent2];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: c, begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(k.radius + 4),
      boxShadow: [
        BoxShadow(
            color: c.first.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 9))
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kicker,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.25)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(big,
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)),
          Text(bigSub,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
      if (sub != null) ...[
        const SizedBox(height: 9),
        Text(sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600)),
      ],
      if (primary != null) ...[
        const SizedBox(height: 13),
        Row(children: [
          Expanded(
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(primaryIcon, size: 16, color: c.first),
                const SizedBox(width: 5),
                Text(primary,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: c.first,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(width: 9),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.5))),
              child: Text(secondary,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ],
    ]),
  );
}

/// سطر فى قايمة: أيقونة ملوّنة + عنوان + تحته وصف + حاجة على الشمال.
Widget rdRow(
  RdLook k, {
  required IconData icon,
  required Color tint,
  required String title,
  String? sub,
  String? trail,
  bool done = false,
  bool circle = true,
  bool box = false,
  bool check = true, // سطر معلومة (وزن · ضغط · فئة مصروف) مالوش «خلصت»
}) {
  final row = Row(children: [
    Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: k.tint(tint),
        borderRadius: BorderRadius.circular(circle ? 19 : 12),
      ),
      child: Icon(icon, size: 19, color: tint),
    ),
    const SizedBox(width: 11),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13.5,
                color: done ? k.mute : k.ink,
                fontWeight: FontWeight.w700,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: k.mute)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          rdT(sub, k, size: 11, color: k.mute, w: FontWeight.w600, maxLines: 1),
        ],
      ]),
    ),
    if (trail != null) ...[
      const SizedBox(width: 6),
      rdT(trail, k, size: 11.5, color: k.mute, w: FontWeight.w700),
    ],
    const SizedBox(width: 8),
    if (check)
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? k.accent : Colors.transparent,
          border: Border.all(color: done ? k.accent : k.line, width: 1.6),
        ),
        child: Icon(Icons.check,
            size: 15, color: done ? k.onAccent : Colors.transparent),
      )
    else
      Icon(Icons.chevron_left, size: 20, color: k.mute),
  ]);
  if (box) return Padding(padding: const EdgeInsets.only(bottom: 9), child: rdCard(k, row, padding: const EdgeInsets.all(11), tint: tint));
  return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: row);
}

/// مربّع هَب — للشاشات اللى فيها بنود جوّاها.
Widget rdTile(RdLook k, IconData icon, String label, Color tint,
        {String? value}) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: k.tinted ? k.tint(tint) : k.surface,
        borderRadius: BorderRadius.circular(k.radius),
        border:
            Border.all(color: k.tinted ? tint.withValues(alpha: 0.22) : k.line),
        boxShadow: k.tinted ? null : k.shadow,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: k.tinted ? Colors.white : k.tint(tint),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(height: 9),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: k.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.25)),
            if (value != null) ...[
              const SizedBox(height: 2),
              rdT(value, k,
                  size: 11, color: k.mute, w: FontWeight.w600, maxLines: 1),
            ],
          ]),
    );

/// شريحة رقم صغيرة.
Widget rdStat(RdLook k, IconData icon, String value, String label, Color tint) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: k.tinted ? k.tint(tint) : k.surface,
          borderRadius: BorderRadius.circular(k.radius - 2),
          border: Border.all(
              color: k.tinted ? tint.withValues(alpha: 0.22) : k.line),
          boxShadow: k.tinted ? null : k.shadow,
        ),
        child: Column(children: [
          Icon(icon, size: 17, color: tint),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 16, color: k.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, color: k.mute, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

Widget rdBar(RdLook k, double v, String label, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: rdT(label, k,
                  size: 11.5, color: k.mute, w: FontWeight.w700, maxLines: 1)),
          rdT('${(v * 100).round()}%', k,
              size: 11.5, color: color ?? k.accent, w: FontWeight.w800),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 7,
            backgroundColor: k.line,
            valueColor: AlwaysStoppedAnimation(color ?? k.accent),
          ),
        ),
      ],
    );

Widget rdChips(RdLook k, List<String> labels, {int active = 0}) => Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: i == active ? k.accent : k.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: i == active ? k.accent : k.line),
            ),
            child: Text(labels[i],
                style: TextStyle(
                    fontSize: 11.5,
                    color: i == active ? k.onAccent : k.mute,
                    fontWeight: FontWeight.w700)),
          ),
          if (i != labels.length - 1) const SizedBox(width: 7),
        ]
      ],
    );

/// جسم موبايل واحد (مقاس 360×760) — بيتحطّ جوّه الثلاثية.
/// 🔴 لازم Theme + Material حوالين كل موبايل: من غيرهم مافيش
/// DefaultTextStyle، فـ`TextStyle` الفاضية بتاخد الخط الافتراضى (مالوش
/// عربى) وكل الكلام يطلع **مربّعات** والصورة تكذب عليك.
Widget rdPhone(RdLook k, {required List<Widget> children, Widget? fab}) =>
    Theme(
      data: rdTheme(k),
      child: Material(
        color: k.bg,
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'Cairo', color: k.ink, fontSize: 13),
          child: _rdPhoneBody(k, children, fab),
        ),
      ),
    );

Widget _rdPhoneBody(RdLook k, List<Widget> children, Widget? fab) =>
    Container(
      width: 360,
      height: 760,
      color: k.bg,
      child: Stack(children: [
        // زى الشاشة الحقيقية: اللى مايبانش بيروح تحت الطيّة مش بيطلع «مقصوص».
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(children: [
            const SizedBox(height: 6),
            ...children,
            const SizedBox(height: 24),
          ]),
        ),
        if (fab != null) Positioned(left: 16, bottom: 18, child: fab),
      ]),
    );

Widget rdFab(RdLook k, {IconData icon = Icons.add}) => Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [k.accent, k.accent2]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: k.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 7))
        ],
      ),
      child: Icon(icon, color: k.onAccent, size: 25),
    );

Widget rdPad(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

/// ثلاثية: التلات اختيارات جانب بعض بأرقام كبيرة — دى اللى تتبعت له.
Widget rdTriptych(List<(String, String, Widget)> options) => Material(
      color: const Color(0xFFEEF1F6),
      child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            Column(children: [
              Container(
                width: 360,
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('${i + 1}  ·  ${options[i].$1}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(options[i].$2,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: Color(0xFF9CA8BD),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: options[i].$3,
              ),
            ]),
            if (i != options.length - 1) const SizedBox(width: 18),
          ]
        ],
      ),
    ));
