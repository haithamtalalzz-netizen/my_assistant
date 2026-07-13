import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/l10n.dart';

/// صف واحد فى ملخّص اليوم: إيموجى + عنوان + قيمة.
class HistoryRow {
  final String emoji;
  final String label;
  final String value;
  const HistoryRow(this.emoji, this.label, this.value);
}

/// تقويم شهرى عام قابل لإعادة الاستخدام لأى بند (فلوس، صحة، …).
///
/// [activeDays] بترجّع مفاتيح الأيام (YYYY-MM-DD) اللى فيها نشاط فى الشهر ده —
/// عشان نحط عليها نقطة. [dayReport] بترجّع صفوف ملخّص يوم معيّن (فاضية = مفيش
/// نشاط). كده أى صفحة كروت تقدر يبقى ليها تقويم بسطر واحد.
class HistoryCalendar extends StatefulWidget {
  final String title;
  final Future<Set<String>> Function(int year, int month) activeDays;
  final Future<List<HistoryRow>> Function(DateTime day) dayReport;
  final String emptyText;
  final Color? accent;

  const HistoryCalendar({
    super.key,
    required this.title,
    required this.activeDays,
    required this.dayReport,
    this.emptyText = '',
    this.accent,
  });

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _active = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await widget.activeDays(_month.year, _month.month);
    if (mounted) setState(() => _active = a);
  }

  void _shift(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openDay(DateTime day) async {
    final rows = await widget.dayReport(day);
    if (!mounted) return;
    final empty = widget.emptyText.isEmpty
        ? tr('لا يوجد نشاط مسجّل فى هذا اليوم', 'No activity logged on this day')
        : widget.emptyText;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(arFullDate(day),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text(empty)
            else
              for (final r in rows) _row(r.emoji, r.label, r.value),
          ],
        ),
      ),
    );
  }

  Widget _row(String emoji, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            SizedBox(width: 120, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final locale = AppState.isEnglish ? 'en' : 'ar';
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // السبت أول العمود (السبت = 6 فى Dart).
    final lead = (first.weekday - 6 + 7) % 7;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_right)),
              Expanded(
                child: Center(
                  child: Text(DateFormat('MMMM y', locale).format(_month),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              IconButton(
                  onPressed: _month.isBefore(DateTime(today.year, today.month))
                      ? () => _shift(1)
                      : null,
                  icon: const Icon(Icons.chevron_left)),
            ],
          ),
          Row(
            children: [
              for (final d in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 0.9),
              itemCount: lead + daysInMonth,
              itemBuilder: (_, i) {
                if (i < lead) return const SizedBox.shrink();
                final dayNum = i - lead + 1;
                final date = DateTime(_month.year, _month.month, dayNum);
                final active = _active.contains(_key(date));
                final isToday = _key(date) == _key(today);
                final future = date.isAfter(today);
                return InkWell(
                  onTap: future ? null : () => _openDay(date),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: active
                          ? accent.withValues(alpha: 0.20)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: accent, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(arNum(dayNum),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: future
                                    ? scheme.onSurfaceVariant
                                        .withValues(alpha: 0.4)
                                    : scheme.onSurface)),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
