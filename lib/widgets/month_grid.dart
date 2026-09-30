import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';

/// شبكة شهر بنقط على الأيام المشغولة.
///
/// ليه شبكة مش قايمة: القايمة بتقول «اللى جاى»، والشبكة بتقول **الشهر
/// كله مرة واحدة** — تشوف الأسبوع الزحمة والأسبوع الفاضى من نظرة، وتدوس
/// على يوم بعينه من غير ما تفضل تنزل.
///
/// الأسبوع بيبدأ **السبت** (زى التقويم المصرى)، وده اللى بيحدّد مكان
/// أول يوم فى الشهر: من غير الإزاحة دى التقويم بيكدب على طول الشهر.
class MonthGrid extends StatelessWidget {
  /// أى شهر معروض (اليوم فيه مالهوش لازمة).
  final DateTime month;

  /// اليوم المختار.
  final DateTime selected;

  /// عدد الحاجات فى كل يوم — المفتاح `dayKey`. الصفر = مافيش نقط.
  final Map<String, int> counts;

  final void Function(DateTime day) onSelect;
  final void Function(DateTime month) onMonthChange;

  /// أقصى عدد نقط تحت اليوم (الزيادة بتتلم فى آخر نقطة).
  final int maxDots;

  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.counts,
    required this.onSelect,
    required this.onMonthChange,
    this.maxDots = 3,
  });

  /// رقم العمود ليوم — السبت = 0.
  static int columnOf(DateTime d) => (d.weekday - DateTime.saturday) % 7;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = columnOf(first);
    final rows = ((lead + daysInMonth) / 7).ceil();
    final today = dateOnly(DateTime.now());

    Widget cell(int slot) {
      final dayNum = slot - lead + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        return const Expanded(child: SizedBox(height: 40));
      }
      final d = DateTime(month.year, month.month, dayNum);
      final isSel = d == dateOnly(selected);
      final isToday = d == today;
      final n = counts[dayKey(d)] ?? 0;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(d),
          child: Column(children: [
            Container(
              height: 30,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              decoration: BoxDecoration(
                color: isSel ? scheme.primary : null,
                borderRadius: BorderRadius.circular(11),
                border: !isSel && isToday
                    ? Border.all(color: scheme.primary, width: 1.4)
                    : null,
              ),
              child: Text(arNum(dayNum),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel || isToday
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSel ? scheme.onPrimary : scheme.onSurface)),
            ),
            SizedBox(
              height: 7,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < (n > maxDots ? maxDots : n); i++)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                        color: isSel ? scheme.onPrimary : scheme.primary,
                        shape: BoxShape.circle),
                  ),
              ]),
            ),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: [
        Row(children: [
          IconButton(
            // 🔴 chevron_right/left بيتقلبوا تحت RTL، فالسهم اللى على
            // اليمين هو اللى بيرجّع للشهر اللى فات فعلاً.
            icon: const Icon(Icons.chevron_right, size: 22),
            tooltip: tr('الشهر اللى فات', 'Previous month'),
            onPressed: () =>
                onMonthChange(DateTime(month.year, month.month - 1, 1)),
          ),
          Expanded(
            child: Text(arMonth(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            tooltip: tr('الشهر الجاى', 'Next month'),
            onPressed: () =>
                onMonthChange(DateTime(month.year, month.month + 1, 1)),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          for (final d in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
            Expanded(
              child: Text(d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant)),
            ),
        ]),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(children: [for (var c = 0; c < 7; c++) cell(r * 7 + c)]),
      ]),
    );
  }
}
