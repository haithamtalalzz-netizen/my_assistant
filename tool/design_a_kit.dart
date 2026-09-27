// طقم بناء شكل «يومك أولاً» (الشكل اللى اختاره المستخدم).
//
// كل شاشة بتتبنى من نفس القطع دى — وده مقصود: لو الشكل اتقبل، الطقم ده
// بيتحوّل لودجتس حقيقية فى `lib/widgets/`، فالشاشات كلها تفضل متسقة
// ومايبقاش فيه شاشة «شكلها غريب».
//
// القطع: شريط علوى · بطل (اللى جاى دلوقتى) · عنوان قسم · كارت أبيض ·
// سطر فى خط زمنى · سطر قايمة · شريحة رقم · مربّع هَب · شريط تقدّم.
import 'package:flutter/material.dart';

// ————— الألوان —————
const aInk = Color(0xFF111827);
const aMuted = Color(0xFF8A93A5);
const aAccent = Color(0xFF16B57E);
const aAccentLight = Color(0xFF2FDE9B);
const aBg = Color(0xFFF6F8FA);
const aLine = Color(0xFFE6EAF0);

ThemeData aTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: aBg,
      colorScheme: ColorScheme.fromSeed(seedColor: aAccentLight),
    );

const _shadow = [
  BoxShadow(color: Color(0x0F0B1B33), blurRadius: 16, offset: Offset(0, 6))
];
const _shadowSm = [
  BoxShadow(color: Color(0x0D0B1B33), blurRadius: 12, offset: Offset(0, 4))
];

/// شريط علوى: ☰ + العنوان + جرس + بحث. [back] بيحطّ سهم رجوع بدل ☰.
Widget aTopBar(String title, {bool back = false, int badge = 5}) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(children: [
        Icon(back ? Icons.arrow_forward : Icons.menu, color: aInk, size: 25),
        const SizedBox(width: 14),
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: aInk)),
        const Spacer(),
        if (badge > 0)
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.notifications_none, color: aInk, size: 23),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        const SizedBox(width: 14),
        const Icon(Icons.search, color: aInk, size: 23),
      ]),
    );

/// **البطل** — أهم حاجة فى الشاشة: اللى جاى/المطلوب دلوقتى + زرار تنفيذ.
/// ده قلب الشكل: أول حاجة عينك تقع عليها هى اللى تعملها.
Widget aHero({
  required IconData icon,
  required String kicker,
  required String title,
  String? trailingBig,
  String? trailingSmall,
  String? primary,
  IconData? primaryIcon,
  String? secondary,
  Widget? extra,
  List<Color> colors = const [Color(0xFF16B57E), Color(0xFF0E8C74)],
}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: colors),
        boxShadow: [
          BoxShadow(
              color: colors.first.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10))
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
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kicker,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85))),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
            if (trailingBig != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(trailingBig,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (trailingSmall != null)
                  Text(trailingSmall,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
              ]),
          ]),
          if (extra != null) ...[const SizedBox(height: 14), extra],
          if (primary != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (primaryIcon != null) ...[
                          Icon(primaryIcon, size: 16, color: colors.first),
                          const SizedBox(width: 5),
                        ],
                        Text(primary,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.first)),
                      ]),
                ),
              ),
              if (secondary != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55))),
                    child: Text(secondary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );

/// شريط تقدّم أبيض جوّه البطل.
Widget aHeroBar(double value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              color: Colors.white),
        ),
        const SizedBox(height: 7),
        Text(label,
            style: TextStyle(
                fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9))),
      ],
    );

/// عنوان قسم + نص صغير على الشمال.
Widget aSection(String title, {String? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: aInk)),
        const Spacer(),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11.5, color: aMuted)),
      ]),
    );

/// كارت أبيض بحواف مدوّرة — وعاء أى قايمة.
Widget aCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) =>
    Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _shadow),
      child: child,
    );

/// سطر فى خط زمنى (نقطة + خط واصل + عنوان + وقت).
Widget aTimelineRow({
  required String time,
  required String title,
  required String sub,
  required Color tint,
  bool done = false,
  bool last = false,
}) =>
    IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
                color: done ? aAccent : Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: done ? aAccent : tint, width: 2.4)),
          ),
          if (!last) Expanded(child: Container(width: 2, color: aLine)),
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
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: done ? aMuted : aInk,
                            decoration:
                                done ? TextDecoration.lineThrough : null)),
                    const SizedBox(height: 1),
                    Text(sub,
                        style: const TextStyle(fontSize: 11, color: aMuted)),
                  ],
                ),
              ),
              Text(time,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: done ? aMuted : tint)),
            ]),
          ),
        ),
      ]),
    );

/// سطر قايمة عادى (أيقونة/مربّع اختيار + عنوان + وصف + حاجة على الشمال).
Widget aListRow({
  required String title,
  String? sub,
  IconData? icon,
  Color tint = aAccent,
  bool check = false,
  bool checked = false,
  Widget? trailing,
  bool divider = true,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: aLine, width: 1)))
          : null,
      child: Row(children: [
        if (check)
          Icon(checked ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 21, color: checked ? aAccent : const Color(0xFFCBD3DE))
        else if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: tint),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: checked ? aMuted : aInk,
                      decoration:
                          checked ? TextDecoration.lineThrough : null)),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: aMuted)),
              ],
            ],
          ),
        ),
        ?trailing,
      ]),
    );

/// شريحة رقم صغيرة (بتتحط فى شريط أفقى تحت «أرقامك»).
Widget aStatChip(IconData icon, String value, String label, Color tint) =>
    Container(
      width: 108,
      margin: const EdgeInsetsDirectional.only(end: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _shadowSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: tint),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: aInk)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: aMuted)),
        ],
      ),
    );

/// مربّع هَب (بند جوّه مجموعة زى «فلوسى»/«صحتى»).
Widget aHubTile(IconData icon, String label, Color tint,
        {String? sub, int badge = 0}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _shadowSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 20, color: tint),
            ),
            const Spacer(),
            if (badge > 0)
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
          ]),
          const Spacer(),
          // سطرين: «الديون والسلف» و«تحليلات العادات» كانوا بيتقصّوا.
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: aInk)),
          if (sub != null)
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: aMuted)),
        ],
      ),
    );

/// زرار عائم.
Widget aFab({IconData icon = Icons.add}) => Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: aAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: aAccent.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );

/// شرائح فلترة أفقية.
Widget aChips(List<String> labels, {int active = 0}) => SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          for (var i = 0; i < labels.length; i++)
            Container(
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == active ? aAccent : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: i == active ? aAccent : aLine),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: i == active ? Colors.white : aInk)),
            ),
        ],
      ),
    );

/// هيكل شاشة: شريط + محتوى بتمرير + زرار عائم اختيارى.
Widget aScreen({
  required String title,
  required List<Widget> children,
  bool back = false,
  bool fab = true,
  IconData fabIcon = Icons.add,
  Widget? bottom,
}) =>
    Scaffold(
      backgroundColor: aBg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [aTopBar(title, back: back), ...children],
        ),
      ),
      floatingActionButton: fab ? aFab(icon: fabIcon) : null,
      bottomNavigationBar: bottom,
    );

/// حشو أفقى موحّد للمحتوى.
Widget aPad(Widget child, {double top = 0, double bottom = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(18, top, 18, bottom),
      child: child,
    );
