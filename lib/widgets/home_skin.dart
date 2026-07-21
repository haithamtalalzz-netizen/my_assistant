/// المظهر العصرى للصفحة الرئيسية: تدرّج لونى بيتغيّر مع وقت اليوم،
/// كروت ناعمة بحواف مدوّرة وظل خفيف، وحركة بسيطة.
///
/// مفصول فى ملف لوحده عشان **يتلبّس على أى تركيب** للرئيسية — الشكل
/// (خط اليوم / بينتو / حلقة …) والمظهر محورين مستقلين، ومكسب «الشاشة
/// بقت أحلى» جايلك من المحور ده مش من ترتيب البنود.
library;

import 'package:flutter/material.dart';

const String kHomeSkinSetting = 'home_skin';

/// مراحل اليوم اللى التدرّج بيتغيّر عندها.
enum DayPhase { dawn, morning, afternoon, evening, night }

/// مرحلة اليوم من الساعة — دالة نقية عشان تتاخد عليها اختبارات.
DayPhase dayPhaseOf(DateTime now) {
  final h = now.hour;
  if (h >= 4 && h < 7) return DayPhase.dawn;
  if (h >= 7 && h < 12) return DayPhase.morning;
  if (h >= 12 && h < 17) return DayPhase.afternoon;
  if (h >= 17 && h < 20) return DayPhase.evening;
  return DayPhase.night;
}

/// ألوان تدرّج الهيدر لكل مرحلة (من الفاتح للغامق).
///
/// متعمّدة إنها **غامقة كفاية** فى كل الحالات عشان الكتابة البيضا فوقها
/// تفضل مقروءة — ده بالظبط الفخ اللى بيخلّى تدرّجات الصبح تبان مغسولة.
List<Color> dayPhaseGradient(DayPhase phase) => switch (phase) {
      DayPhase.dawn => const [Color(0xFF6A4C93), Color(0xFFE07A5F)],
      DayPhase.morning => const [Color(0xFF1D6FB8), Color(0xFF3EC7C2)],
      DayPhase.afternoon => const [Color(0xFF0F7B8A), Color(0xFF2E9E6B)],
      DayPhase.evening => const [Color(0xFFB4531F), Color(0xFF6B2D5B)],
      DayPhase.night => const [Color(0xFF16213E), Color(0xFF3A2E63)],
    };

/// كارت المظهر العصرى — حواف أنعم وظل أخف من كارت ماتيريال العادى.
/// لما [skin] تبقى false بيرجع كارت عادى، فنفس الكود يخدم المظهرين.
class SkinCard extends StatelessWidget {
  final Widget child;
  final bool skin;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final VoidCallback? onTap;

  const SkinCard({
    super.key,
    required this.child,
    required this.skin,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerLow;
    if (!skin) {
      return Card(
        margin: margin,
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: padding, child: child),
        ),
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// هيدر الرئيسية بالمظهر العصرى — تدرّج بيتغيّر مع وقت اليوم.
class SkinHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final DateTime now;
  final Widget? trailing;

  const SkinHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.now,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = dayPhaseGradient(dayPhaseOf(now));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: colors,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// علامة «تمّت» بحركة بسيطة — بتكبر وترجع لما الحالة تتغيّر.
class SkinCheck extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  final double size;

  const SkinCheck(
      {super.key, required this.done, required this.onTap, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: AnimatedScale(
        scale: done ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 180),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            key: ValueKey(done),
            size: size,
            color: done ? scheme.primary : scheme.outline,
          ),
        ),
      ),
    );
  }
}
