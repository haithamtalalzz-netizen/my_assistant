import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/l10n.dart';

/// يفتح عجلة دوّارة لاختيار الشهر والسنة، ويرجّع أول يوم فى الشهر المختار
/// (أو null لو اتلغى). بيتقفل عند [maxMonth] (الافتراضى = الشهر الحالى).
Future<DateTime?> showMonthYearWheel(
  BuildContext context, {
  required DateTime initial,
  DateTime? maxMonth,
  int minYear = 2018,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MonthYearWheel(
      initial: initial,
      maxMonth: maxMonth ?? DateTime(DateTime.now().year, DateTime.now().month),
      minYear: minYear,
    ),
  );
}

class _MonthYearWheel extends StatefulWidget {
  final DateTime initial;
  final DateTime maxMonth;
  final int minYear;
  const _MonthYearWheel({
    required this.initial,
    required this.maxMonth,
    required this.minYear,
  });

  @override
  State<_MonthYearWheel> createState() => _MonthYearWheelState();
}

class _MonthYearWheelState extends State<_MonthYearWheel> {
  late final List<int> _years = [
    for (var y = widget.minYear; y <= widget.maxMonth.year; y++) y
  ];
  late int _monthIdx = (widget.initial.month - 1).clamp(0, 11);
  late int _yearIdx =
      (widget.initial.year - widget.minYear).clamp(0, _years.length - 1);
  late final FixedExtentScrollController _monthCtrl =
      FixedExtentScrollController(initialItem: _monthIdx);
  late final FixedExtentScrollController _yearCtrl =
      FixedExtentScrollController(initialItem: _yearIdx);

  @override
  void dispose() {
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    var chosen = DateTime(_years[_yearIdx], _monthIdx + 1);
    // ما نعديش الشهر الحالى (التقويم للأيام الماضية).
    if (chosen.isAfter(widget.maxMonth)) chosen = widget.maxMonth;
    Navigator.pop(context, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = AppState.isEnglish ? 'en' : 'ar';
    final months = [
      for (var m = 1; m <= 12; m++)
        DateFormat('MMMM', locale).format(DateTime(2000, m))
    ];
    final itemStyle = TextStyle(fontSize: 19, color: scheme.onSurface);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('إلغاء', 'Cancel')),
                ),
                Expanded(
                  child: Text(
                    tr('اختر الشهر والسنة', 'Pick month & year'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _confirm,
                  child: Text(tr('تم', 'Done'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _monthCtrl,
                      itemExtent: 40,
                      squeeze: 1.1,
                      onSelectedItemChanged: (i) => _monthIdx = i,
                      children: [
                        for (final m in months)
                          Center(child: Text(m, style: itemStyle)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _yearCtrl,
                      itemExtent: 40,
                      squeeze: 1.1,
                      onSelectedItemChanged: (i) => _yearIdx = i,
                      children: [
                        for (final y in _years)
                          Center(child: Text(arNum(y), style: itemStyle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
