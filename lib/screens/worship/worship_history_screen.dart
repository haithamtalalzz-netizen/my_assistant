import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../data/worship_repo.dart';
import '../../widgets/month_year_wheel.dart';

/// تقويم/سجل العبادات — ترجع للأيام الماضية تشوف صلّيت إيه وقريت قرآن أدّ إيه.
class WorshipHistoryScreen extends StatefulWidget {
  const WorshipHistoryScreen({super.key});

  @override
  State<WorshipHistoryScreen> createState() => _WorshipHistoryScreenState();
}

class _WorshipHistoryScreenState extends State<WorshipHistoryScreen> {
  final _repo = WorshipRepo();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _active = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await _repo.worshipDaysInMonth(_month.year, _month.month);
    if (mounted) setState(() => _active = a);
  }

  void _shift(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  /// دوسة على الشهر/السنة → عجلة دوّارة لاختيار التاريخ.
  Future<void> _pickMonthYear() async {
    final picked = await showMonthYearWheel(context, initial: _month);
    if (picked == null || !mounted) return;
    setState(() => _month = DateTime(picked.year, picked.month));
    _load();
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openDay(DateTime day) async {
    final r = await _repo.dayReport(day);
    if (!mounted) return;
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (!r.hasAny)
              Text(tr('لا يوجد نشاط عبادى مسجّل فى هذا اليوم',
                  'No worship logged on this day'))
            else ...[
              _row('🕌', tr('الصلوات', 'Prayers'),
                  '${arNum(r.prayers.length)}/5 · ${r.prayers.map(prayerNameLabel).join('، ')}'),
              _row(
                  '📿',
                  tr('الأذكار', 'Adhkar'),
                  r.dhikr.isEmpty
                      ? tr('لا شىء', '—')
                      : [
                          if (r.dhikr.contains('morning')) tr('الصباح', 'Morning'),
                          if (r.dhikr.contains('evening')) tr('المساء', 'Evening'),
                        ].join('، ')),
              _row('🤲', tr('سنن ونوافل', 'Sunnah'), arNum(r.sunnah)),
              _row('🌙', tr('الصيام', 'Fasting'),
                  r.fasted ? tr('صام ✓', 'Fasted ✓') : tr('لا', 'No')),
              _row('📖', tr('قراءة القرآن', 'Quran read'),
                  tr('${arNum(r.quranPages)} صفحة', '${arNum(r.quranPages)} pages')),
              _row('✨', tr('الوِرد', 'Wird'),
                  tr('${arNum(r.wird)} ذِكر', '${arNum(r.wird)} dhikr')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String emoji, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            SizedBox(width: 110, child: Text(label)),
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
    final locale = AppState.isEnglish ? 'en' : 'ar';
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // السبت أول العمود (weekday: السبت=6 فى Dart).
    final lead = (first.weekday - 6 + 7) % 7;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(tr('سجل العبادات', 'Worship history'))),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: InkWell(
                  onTap: _pickMonthYear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('MMMM y', locale).format(_month),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down,
                            color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed:
                      _month.isBefore(DateTime(today.year, today.month))
                          ? () => _shift(1)
                          : null,
                  icon: const Icon(Icons.chevron_right)),
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
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 2)
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
                                color: scheme.primary, shape: BoxShape.circle),
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
