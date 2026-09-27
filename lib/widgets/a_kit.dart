// طقم شكل «يومك أولاً» — القطع اللى كل شاشة بتتبنى منها.
//
// القاعدة اللى بينى عليها الشكل: **أول حاجة عينك تقع عليها هى اللى تعملها**.
// فكل شاشة بتبدأ بـ[AppHero] (اللى جاى/المطلوب دلوقتى + زرار تنفيذ)، وبعديها
// التفاصيل فى [AppCard] (خط زمنى أو قايمة).
//
// **كل الألوان من `Theme.of(context).colorScheme`** — مش ثابتة — عشان الوضع
// الداكن ولون الهوية اللى المستخدم بيختاره من الإعدادات يفضلوا شغّالين.
import 'package:flutter/material.dart';

/// ظل الكارت — خفيف فى الفاتح، ومعدوم فى الداكن (الظل مابيبانش على أسود،
/// والحدّ هو اللى بيفصل).
List<BoxShadow> appCardShadow(BuildContext context, {bool small = false}) {
  if (Theme.of(context).brightness == Brightness.dark) return const [];
  return [
    BoxShadow(
      color: const Color(0xFF0B1B33).withValues(alpha: small ? 0.05 : 0.06),
      blurRadius: small ? 12 : 16,
      offset: Offset(0, small ? 4 : 6),
    ),
  ];
}

/// كارت أبيض بحواف مدوّرة — وعاء أى قايمة فى الشكل الجديد.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard(this.child,
      {super.key, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: appCardShadow(context),
      ),
      child: child,
    );
  }
}

/// عنوان قسم + نص صغير على الشمال.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const AppSectionTitle(this.title, {super.key, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface)),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing!,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: onTrailingTap == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: onTrailingTap == null
                        ? scheme.onSurfaceVariant
                        : scheme.primary)),
          ),
      ]),
    );
  }
}

/// **البطل** — أهم حاجة فى الشاشة دلوقتى + زرار تنفيذ مباشر.
///
/// [colors] بتحدد تدرّج الخلفية؛ لو null بياخد لون الهوية من الثيم، فالكارت
/// بيتغيّر مع اختيار المستخدم أوتوماتيك.
class AppHero extends StatelessWidget {
  final IconData icon;
  final String kicker;
  final String title;
  final String? trailingBig;
  final String? trailingSmall;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? extra;
  final List<Color>? colors;

  const AppHero({
    super.key,
    required this.icon,
    required this.kicker,
    required this.title,
    this.trailingBig,
    this.trailingSmall,
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.extra,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = colors ??
        [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.28)!];
    // لون نص الأزرار جوّه الزرار الأبيض = أغمق درجة من التدرّج عشان التباين
    // يفضل مقروء مهما كان لون الهوية.
    final onWhite = Color.lerp(base.first, Colors.black, 0.25)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft, colors: base),
        boxShadow: [
          BoxShadow(
              color: base.first.withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kicker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            ]),
          ),
          if (trailingBig != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(trailingBig!,
                  style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              if (trailingSmall != null)
                Text(trailingSmall!,
                    style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ]),
        ]),
        if (extra != null) ...[const SizedBox(height: 14), extra!],
        if (primaryLabel != null) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _heroButton(
                label: primaryLabel!,
                icon: primaryIcon,
                onTap: onPrimary,
                filled: true,
                color: onWhite,
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _heroButton(
                    label: secondaryLabel!,
                    onTap: onSecondary,
                    filled: false,
                    color: Colors.white),
              ),
            ],
          ]),
        ],
      ]),
    );
  }

  Widget _heroButton({
    required String label,
    required bool filled,
    required Color color,
    IconData? icon,
    VoidCallback? onTap,
  }) =>
      Material(
        color: filled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: filled
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
          ),
        ),
      );
}

/// شريط تقدّم أبيض بنص تحته — بيتحط فى [AppHero.extra].
class AppHeroBar extends StatelessWidget {
  final double value;
  final String label;
  const AppHeroBar(this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(label,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9))),
        ],
      );
}

/// سطر فى خط زمنى: نقطة + خط واصل + عنوان + وقت.
class AppTimelineRow extends StatelessWidget {
  final String time;
  final String title;
  final String sub;
  final Color tint;
  final bool done;
  final bool last;
  final VoidCallback? onTap;

  /// إخفاء نقطة الخط — بيتستخدم لما يكون فيه دايرة «تمّ» قابلة للضغط
  /// مكانها، عشان مايبانش دايرتين جنب بعض.
  final bool showDot;

  const AppTimelineRow({
    super.key,
    required this.time,
    required this.title,
    this.sub = '',
    required this.tint,
    this.done = false,
    this.last = false,
    this.onTap,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            if (showDot)
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                    color: done ? scheme.primary : scheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: done ? scheme.primary : tint, width: 2.4)),
              )
            else
              const SizedBox(width: 2, height: 16),
            if (!last)
              Expanded(
                  child: Container(
                      width: 2,
                      color: scheme.outlineVariant.withValues(alpha: 0.8))),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: done ? muted : scheme.onSurface,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null)),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: muted)),
                        ],
                      ]),
                ),
                Text(time,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: done ? muted : tint)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// سطر قايمة: أيقونة (أو مربّع اختيار) + عنوان + وصف + حاجة على الشمال.
class AppListRow extends StatelessWidget {
  final String title;
  final String? sub;
  final IconData? icon;
  final Color? tint;
  final bool check;
  final bool checked;
  final Widget? trailing;
  final bool divider;
  final VoidCallback? onTap;
  final VoidCallback? onCheck;
  final VoidCallback? onLongPress;

  const AppListRow({
    super.key,
    required this.title,
    this.sub,
    this.icon,
    this.tint,
    this.check = false,
    this.checked = false,
    this.trailing,
    this.divider = true,
    this.onTap,
    this.onCheck,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = tint ?? scheme.primary;
    final muted = scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: divider
            ? BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                        width: 1)))
            : null,
        child: Row(children: [
          if (check)
            GestureDetector(
              onTap: onCheck,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                    checked
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 21,
                    color: checked ? scheme.primary : scheme.outline),
              ),
            )
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: c),
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
                          color: checked ? muted : scheme.onSurface,
                          decoration:
                              checked ? TextDecoration.lineThrough : null)),
                  if (sub != null && sub!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: muted)),
                  ],
                ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// شريحة رقم صغيرة — بتتحط فى شريط أفقى («أرقامك»).
class AppStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final VoidCallback? onTap;
  const AppStatChip(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      required this.tint,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: appCardShadow(context, small: true)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: tint),
              const SizedBox(height: 8),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10.5, color: scheme.onSurfaceVariant)),
            ]),
      ),
    );
  }
}

/// مربّع بند جوّه هَب («فلوسى»/«صحتى»/«تطوّرى»).
class AppHubTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final String? sub;
  final int badge;
  final VoidCallback? onTap;
  const AppHubTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.tint,
      this.sub,
      this.badge = 0,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text('$badge',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onError)),
                ),
            ]),
            const Spacer(),
            // سطرين: أسماء زى «الديون والسلف» بتتقصّ على سطر واحد.
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            if (sub != null && sub!.isNotEmpty)
              Text(sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

/// حشو أفقى موحّد لمحتوى الشاشات فى الشكل الجديد.
class AppPad extends StatelessWidget {
  final Widget child;
  final double top;
  final double bottom;
  const AppPad(this.child, {super.key, this.top = 0, this.bottom = 0});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(18, top, 18, bottom),
        child: child,
      );
}
