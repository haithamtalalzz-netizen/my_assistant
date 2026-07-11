import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../core/month_report.dart';
import '../data/day_log_repo.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = DayLogRepo();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  Set<String> _activeDays = {};
  // أنواع الأحداث المخفية في فلتر التقويم.
  final Set<String> _hiddenKinds = {};

  static const Map<String, String> _kindLabels = {
    'appointment': 'مواعيد',
    'expense': 'مصروفات',
    'income': 'دخل',
    'meal': 'وجبات',
    'med': 'أدوية',
    'habit': 'عادات',
    'workout': 'تمرين',
    'gym': 'جيم',
    'measurement': 'قياسات',
    'medical': 'طبي',
    'meter': 'عدادات',
    'social': 'اجتماعي',
    'health': 'صحة',
  };

  Future<void> _openFilter() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('عرض الأنواع', 'Show types')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in _kindLabels.entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(e.value),
                  value: !_hiddenKinds.contains(e.key),
                  onChanged: (v) => setD(() {
                    if (v == true) {
                      _hiddenKinds.remove(e.key);
                    } else {
                      _hiddenKinds.add(e.key);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('تمام', 'Done'))),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await _repo.daysWithActivity(_month.year, _month.month);
    if (!mounted) return;
    setState(() {
      _activeDays = active;
      _loading = false;
    });
  }

  void _shift(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  Future<void> _exportMonth() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('بجهّز ملف الشهر...', 'Preparing month file...'))));
    try {
      await MonthReport.generateAndShare(_month.year, _month.month);
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('حصلت مشكلة في التصدير', 'Export failed'))));
      }
    }
  }

  /// منتقي الشهر والسنة — تدوس على العنوان فتختار على طول (زي طارة).
  Future<void> _pickMonth() async {
    final locale = AppState.isEnglish ? 'en' : 'ar';
    final now = DateTime.now();
    var year = _month.year;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Directionality(
          textDirection:
              AppState.isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اختيار السنة.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          onPressed: () => setD(() => year--),
                          icon: const Icon(Icons.chevron_right)),
                      Text(arNum(year),
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                          onPressed:
                              year >= now.year ? null : () => setD(() => year++),
                          icon: const Icon(Icons.chevron_left)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // شبكة الشهور.
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 2.1,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (var m = 1; m <= 12; m++)
                        _monthChip(ctx, scheme, year, m, now, locale),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tr('إلغاء', 'Cancel'))),
            ],
          ),
        ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _month = picked;
        _loading = true;
      });
      _load();
    }
  }

  Widget _monthChip(BuildContext ctx, ColorScheme scheme, int year, int m,
      DateTime now, String locale) {
    final disabled = year == now.year && m > now.month;
    final selected = year == _month.year && m == _month.month;
    final label = DateFormat('MMM', locale).format(DateTime(year, m));
    return Material(
      color: selected
          ? scheme.primary
          : disabled
              ? Colors.transparent
              : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled ? null : () => Navigator.pop(ctx, DateTime(year, m)),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? scheme.onPrimary
                      : disabled
                          ? scheme.outline.withValues(alpha: 0.4)
                          : scheme.onSurface)),
        ),
      ),
    );
  }

  /// عمود اليوم في شبكة تبدأ بالسبت (Dart weekday: إثنين=1..أحد=7، سبت=6).
  int _col(int weekday) => (weekday - 6 + 7) % 7;

  IconData _iconFor(String kind) => switch (kind) {
        'appointment' => Icons.event,
        'expense' => Icons.account_balance_wallet_outlined,
        'income' => Icons.south_west,
        'meal' => Icons.restaurant_outlined,
        'med' => Icons.medication_outlined,
        'habit' => Icons.task_alt,
        'workout' => Icons.fitness_center,
        'gym' => Icons.fitness_center,
        'measurement' => Icons.monitor_heart_outlined,
        'medical' => Icons.medical_information_outlined,
        'meter' => Icons.speed_outlined,
        'social' => Icons.volunteer_activism_outlined,
        'health' => Icons.favorite_outline,
        _ => Icons.circle,
      };

  Color _colorFor(String kind, ColorScheme s) => switch (kind) {
        'expense' => s.error,
        'income' => Colors.green,
        'appointment' => s.primary,
        'health' => Colors.teal,
        _ => s.onSurfaceVariant,
      };

  Future<void> _openDay(DateTime date) async {
    final key = dayKey(date);
    final all = await _repo.forDay(key);
    final events =
        all.where((e) => !_hiddenKinds.contains(e.kind)).toList();
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(arFullDate(date),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Text(tr('مفيش نشاط اليوم ده', 'No activity that day'),
                            style: TextStyle(color: scheme.outline)))
                    : ListView.builder(
                        controller: controller,
                        itemCount: events.length,
                        itemBuilder: (ctx, i) {
                          final e = events[i];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(_iconFor(e.kind),
                                size: 20, color: _colorFor(e.kind, scheme)),
                            title: Text(e.text),
                            trailing: e.time == null
                                ? null
                                : Text(e.time!,
                                    style: TextStyle(color: scheme.outline)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('تقويم النتيجة', 'Activity calendar')),
        actions: [
          searchAction(context),
          if (!(_month.year == DateTime.now().year &&
              _month.month == DateTime.now().month))
            IconButton(
              tooltip: tr('ارجع للشهر الحالي', 'Jump to this month'),
              icon: const Icon(Icons.today_outlined),
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  _month = DateTime(now.year, now.month);
                  _loading = true;
                });
                _load();
              },
            ),
          IconButton(
            tooltip: tr('فلتر الأنواع', 'Filter types'),
            icon: Icon(_hiddenKinds.isEmpty
                ? Icons.filter_list
                : Icons.filter_list_alt),
            onPressed: _openFilter,
          ),
          IconButton(
            tooltip: tr('تصدير الشهر PDF', 'Export month PDF'),
            icon: const Icon(Icons.ios_share),
            onPressed: _exportMonth,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _monthNav(context),
                _summaryStrip(context),
                _weekdayHeader(context),
                Expanded(child: _grid(context)),
                _legend(context),
              ],
            ),
    );
  }

  /// شريط ملخص الشهر: كام يوم فيه نشاط من إجمالي أيام الشهر + شريط تقدّم.
  Widget _summaryStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final active = _activeDays.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 16,
                  color: active > 0 ? Colors.deepOrange : scheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    tr('نشطت ${arNum(active)} يوم من ${arNum(daysInMonth)} الشهر ده',
                        'Active ${arNum(active)} of ${arNum(daysInMonth)} days this month'),
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: daysInMonth == 0 ? 0 : active / daysInMonth,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNav(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_right)),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(arMonth(_month),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 22),
                ],
              ),
            ),
          ),
          IconButton(
              onPressed: isCurrent ? null : () => _shift(1),
              icon: const Icon(Icons.chevron_left)),
        ],
      ),
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    final labels = [
      tr('س', 'Sa'), tr('ح', 'Su'), tr('ن', 'Mo'), tr('ث', 'Tu'),
      tr('ر', 'We'), tr('خ', 'Th'), tr('ج', 'Fr'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
              child: Center(
                child: Text(l,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.outline)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = dateOnly(DateTime.now());
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstCol = _col(DateTime(_month.year, _month.month, 1).weekday);
    final cells = <Widget?>[
      for (var i = 0; i < firstCol; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        _dayCell(context, DateTime(_month.year, _month.month, d), now, scheme),
    ];
    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.all(8),
      children: [for (final c in cells) c ?? const SizedBox.shrink()],
    );
  }

  Widget _dayCell(
      BuildContext context, DateTime date, DateTime today, ColorScheme scheme) {
    final key = dayKey(date);
    final active = _activeDays.contains(key);
    final isToday = dateOnly(date) == today;
    return InkWell(
      onTap: () => _openDay(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(arNum(date.day),
                style: TextStyle(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? scheme.onPrimaryContainer : null)),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? scheme.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Text(tr('يوم فيه نشاط — اضغط تشوف التفاصيل',
              'Day with activity — tap to see details'),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
