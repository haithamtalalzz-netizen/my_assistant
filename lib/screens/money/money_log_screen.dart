import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import '../../core/privacy.dart';

/// بيشتغل على المصروف ولا الدخل.
enum MoneyLogKind { spent, received }

/// **سجل الفلوس** — «صرفت إيه» أو «قبضت إيه».
///
/// مقسوم بالأيام: النهاردة · امبارح · وبعدها كل يوم باسمه، وكل مجموعة
/// معاها إجماليها. كده تعرف يوم يوم راح فين من غير ما تقعد تجمع.
///
/// شاشة واحدة للاتنين عن قصد: نفس القايمة ونفس التقسيم، الفرق بس
/// المصدر واللون — فالتعديل بيحصل فى مكان واحد.
class MoneyLogScreen extends StatefulWidget {
  final MoneyLogKind kind;
  const MoneyLogScreen({super.key, required this.kind});

  @override
  State<MoneyLogScreen> createState() => _MoneyLogScreenState();
}

/// حركة واحدة بعد ما اتوحّد شكلها (مصروف أو دخل).
class _Move {
  final int? id;
  final double amount;
  final String title;
  final String note;
  final String day;
  const _Move(this.id, this.amount, this.title, this.note, this.day);
}

class _MoneyLogScreenState extends State<MoneyLogScreen> {
  final _money = MoneyRepo();
  final _income = IncomeRepo();

  bool _loading = true;
  List<_Move> _moves = [];
  double _total = 0;

  late DateTime _from;
  late DateTime _to;

  /// الافتراضى: الشهر ده — أوسع من يوم واحد وأقرب لسؤال «راح فين».
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  bool get _isSpent => widget.kind == MoneyLogKind.spent;

  Color _tint(BuildContext c) => _isSpent
      ? Theme.of(c).colorScheme.error
      : const Color(0xFF10B981);

  Future<void> _load() async {
    final f = dayKey(_from);
    final t = dayKey(_to);
    if (_isSpent) {
      final rows = await _money.forRange(f, t);
      if (!mounted) return;
      setState(() {
        _moves = [
          for (final e in rows)
            _Move(e.id, e.amount, expenseCategoryLabel(e.category), e.note,
                e.day)
        ];
        _total = rows.fold<double>(0, (s, e) => s + e.amount);
        _loading = false;
      });
    } else {
      final rows = await _income.forRange(f, t);
      if (!mounted) return;
      setState(() {
        _moves = [
          for (final e in rows)
            _Move(e.id, e.amount, incomeSourceLabel(e.source), e.note, e.day)
        ];
        _total = rows.fold<double>(0, (s, e) => s + e.amount);
        _loading = false;
      });
    }
  }

  /// اسم مجموعة اليوم: النهاردة · امبارح · وبعدها التاريخ.
  String _dayLabel(String day) {
    final d = DateTime.tryParse(day);
    if (d == null) return day;
    final diff = dateOnly(DateTime.now()).difference(dateOnly(d)).inDays;
    if (diff == 0) return tr('النهاردة', 'Today');
    if (diff == 1) return tr('امبارح', 'Yesterday');
    return '${arWeekday(d)} · ${arShortDate(d)}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _from, end: _to),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (r == null) return;
    setState(() {
      _from = dateOnly(r.start);
      _to = dateOnly(r.end);
    });
    await _load();
  }

  Future<void> _delete(_Move m) async {
    if (m.id == null) return;
    if (!await confirmDelete(
        context,
        _isSpent
            ? tr('المصروف ده (${arMoney(m.amount.round())})',
                'this expense (${arMoney(m.amount.round())})')
            : tr('الدخل ده (${arMoney(m.amount.round())})',
                'this income (${arMoney(m.amount.round())})'))) {
      return;
    }
    if (_isSpent) {
      await _money.delete(m.id!);
    } else {
      await _income.delete(m.id!);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = _tint(context);

    // التجميع باليوم — الترتيب جاى من الاستعلام (الأحدث الأول).
    final days = <String, List<_Move>>{};
    for (final m in _moves) {
      days.putIfAbsent(m.day, () => []).add(m);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSpent
            ? tr('صرفت إيه', 'What I spent')
            : tr('قبضت إيه', 'What I received')),
        actions: [
          const PrivacyAction(),
          IconButton(
            onPressed: _pickRange,
            tooltip: tr('اختار فترة', 'Pick a period'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  AppCard(
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _isSpent
                                      ? tr('صرفت فى الفترة دى', 'Spent')
                                      : tr('قبضت فى الفترة دى', 'Received'),
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              // «←» مش فى خط Cairo فبيطلع مربّع — كلمة
                              // عربية أوضح وبتترسم أكيد.
                              Text(
                                  tr('من ${arShortDate(_from)} إلى ${arShortDate(_to)}',
                                      '${arShortDate(_from)} → ${arShortDate(_to)}'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant)),
                            ]),
                      ),
                      Text(arMoney(_total.round()),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: c)),
                    ]),
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  ),
                  if (_moves.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: EmptyHint(
                        icon: _isSpent
                            ? Icons.receipt_long_outlined
                            : Icons.south_west,
                        text: _isSpent
                            ? tr('مفيش مصاريف فى الفترة دى',
                                'Nothing spent in this period')
                            : tr('مفيش دخل فى الفترة دى',
                                'Nothing received in this period'),
                      ),
                    )
                  else
                    for (final day in days.keys) ...[
                      AppGroupHead(_dayLabel(day),
                          trail: arMoney(days[day]!
                              .fold<double>(0, (s, m) => s + m.amount)
                              .round())),
                      for (var i = 0; i < days[day]!.length; i++)
                        AppListRow(
                          title: days[day]![i].title,
                          sub: days[day]![i].note.isEmpty
                              ? null
                              : days[day]![i].note,
                          icon: _isSpent
                              ? Icons.trending_down
                              : Icons.trending_up,
                          tint: c,
                          divider: i != days[day]!.length - 1,
                          onLongPress: () => _delete(days[day]![i]),
                          trailing: Text(arMoney(days[day]![i].amount.round()),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: c)),
                        ),
                    ],
                  if (_moves.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(tr('دوس مطوّل على الحركة تمسحها',
                        'Long-press an entry to delete it'),
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
    );
  }
}
