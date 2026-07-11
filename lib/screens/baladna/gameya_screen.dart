import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/gameya_repo.dart';
import '../../data/money_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';
import '../../widgets/wheel_date_picker.dart';

class GameyaScreen extends StatefulWidget {
  const GameyaScreen({super.key});

  @override
  State<GameyaScreen> createState() => _GameyaScreenState();
}

class _GameyaScreenState extends State<GameyaScreen> {
  final _repo = GameyaRepo();
  bool _loading = true;
  List<Gameya> _list = [];
  Map<int, Set<String>> _paid = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.all();
    final paid = <int, Set<String>>{};
    for (final g in list) {
      paid[g.id!] = await _repo.paidMonths(g.id!);
    }
    if (!mounted) return;
    setState(() {
      _list = list;
      _paid = paid;
      _loading = false;
    });
  }

  String _thisMonthKey() {
    final n = DateTime.now();
    return MoneyRepo.monthPrefix(n.year, n.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('الجمعيات', "Gam'iyas")),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _list.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.groups_outlined,
                          text:
                              tr('مفيش جمعيات — سجل جمعيتك وهنتابع القسط ودورك',
                                  "No gam'iyas — add yours and we'll track the installment & your turn")),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      children: [
                        _summary(context),
                        for (final g in _sorted()) _card(context, g),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'gameya_fab',
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: Text(tr('جمعية جديدة', "New gam'iya")),
      ),
    );
  }

  /// النشطة الأول، وجواها اللي دورها الشهر ده أو لسه ماادفعتش القسط يطلع فوق.
  List<Gameya> _sorted() {
    final now = DateTime.now();
    int rank(Gameya g) {
      if (!g.isActive(now)) return 3;
      final turn = g.monthsUntilMyTurn(now);
      final unpaid = !(_paid[g.id!] ?? const {}).contains(_thisMonthKey());
      if (turn == 0) return 0; // دورك الشهر ده
      if (unpaid) return 1; // مستحق قسط
      return 2;
    }

    final list = List.of(_list);
    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }

  /// كارت علوي: كام جمعية مستحق قسطها الشهر ده + تنبيه دورك.
  Widget _summary(BuildContext context) {
    final now = DateTime.now();
    final active = _list.where((g) => g.isActive(now)).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final unpaid = active
        .where((g) => !(_paid[g.id!] ?? const {}).contains(_thisMonthKey()))
        .length;
    final myTurn = active.where((g) => g.monthsUntilMyTurn(now) == 0).toList();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.groups_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unpaid == 0
                      ? tr('كل أقساط الشهر اتدفعت ✓',
                          'All installments paid this month ✓')
                      : tr('${arNum(unpaid)} جمعية مستحق قسطها الشهر ده',
                          '${arNum(unpaid)} installment(s) due this month'),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: unpaid == 0 ? Colors.green : scheme.error),
                ),
              ),
            ]),
            if (myTurn.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                  tr('🎉 دورك الشهر ده في: ${myTurn.map((g) => g.name).join('، ')}',
                      '🎉 Your turn this month: ${myTurn.map((g) => g.name).join(', ')}'),
                  style: TextStyle(color: scheme.primary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Gameya g) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final idx = g.monthIndex(now);
    final active = g.isActive(now);
    final paidThisMonth = (_paid[g.id!] ?? const {}).contains(_thisMonthKey());
    final turnMonths = g.monthsUntilMyTurn(now);
    final progress = active ? idx / g.totalMonths : (idx > g.totalMonths ? 1.0 : 0.0);

    final String status;
    if (!active && idx < 1) {
      status = tr(
          'بتبدأ ${DateFormat('MMMM', 'ar').format(DateTime.parse('${g.startMonth}-01'))}',
          'Starts ${DateFormat('MMMM', 'en').format(DateTime.parse('${g.startMonth}-01'))}');
    } else if (!active) {
      status = tr('خلصت', 'Finished');
    } else if (turnMonths == 0) {
      status = tr('دورك الشهر ده — بتقبض ${egp(g.payout)}! 🎉',
          'Your turn this month — you collect ${egp(g.payout)}! 🎉');
    } else if (turnMonths > 0) {
      status = tr('فاضل ${arNum(turnMonths)} شهور على دورك',
          '${arNum(turnMonths)} months until your turn');
    } else {
      status = tr('قبضت دورك — باقي ${arNum(g.totalMonths - idx + 1)} شهور دفع',
          'You collected — ${arNum(g.totalMonths - idx + 1)} months of payments left');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(g.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await _form(g);
                      case 'delete':
                        if (!await confirmDelete(
                            context, tr('الجمعية "${g.name}"', "gam'iya \"${g.name}\""))) {
                          return;
                        }
                        await _repo.delete(g.id!);
                        if (mounted) await _load();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                    PopupMenuItem(
                        value: 'delete', child: Text(tr('حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            Text(
                tr('القسط ${egp(g.amount)} • ${arNum(g.totalMonths)} شهور • دورك الشهر ${arNum(g.myTurn)}',
                    'Installment ${egp(g.amount)} • ${arNum(g.totalMonths)} months • your turn month ${arNum(g.myTurn)}'),
                style: TextStyle(color: scheme.outline, fontSize: 13)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(status,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: turnMonths == 0 && active
                        ? scheme.primary
                        : null)),
            if (active) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        paidThisMonth
                            ? tr('قسط الشهر ده اتدفع ✓', "This month's installment paid ✓")
                            : tr('لسه ماادفعتش قسط الشهر ده',
                                "This month's installment not paid yet"),
                        style: TextStyle(
                            color: paidThisMonth
                                ? scheme.primary
                                : scheme.error)),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await _repo.setPaid(
                          g.id!, _thisMonthKey(), !paidThisMonth,
                          amount: paidThisMonth ? null : g.amount);
                      if (mounted) await _load();
                    },
                    child: Text(paidThisMonth
                        ? tr('إلغاء', 'Undo')
                        : tr('دفعت القسط', 'Paid installment')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _form([Gameya? g]) async {
    final name = TextEditingController(text: g?.name ?? '');
    final amount = TextEditingController(
        text: g == null ? '' : g.amount.toStringAsFixed(0));
    final total = TextEditingController(
        text: g == null ? '' : g.totalMonths.toString());
    final turn = TextEditingController(
        text: g == null ? '' : g.myTurn.toString());
    var day = g?.dayOfMonth ?? 1;
    var start = g == null
        ? DateTime(DateTime.now().year, DateTime.now().month)
        : DateTime.parse('${g.startMonth}-01');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(g == null
              ? tr('جمعية جديدة', "New gam'iya")
              : tr('تعديل جمعية', "Edit gam'iya")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: g == null,
                  decoration: InputDecoration(
                      labelText: tr('الاسم (جمعية الشغل، العيلة...)',
                          'Name (work, family...)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText:
                          tr('القسط الشهري (ج.م)', 'Monthly installment (EGP)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: total,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: tr('عدد الشهور (= عدد الأعضاء)',
                          'Number of months (= members)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: turn,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: tr('دورك في الشهر رقم كام؟',
                          'Your turn is in which month?')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child:
                            Text(tr('يوم دفع القسط', 'Installment day'))),
                    DropdownButton<int>(
                      value: day,
                      items: [
                        for (var d = 1; d <= 28; d++)
                          DropdownMenuItem(value: d, child: Text(arNum(d))),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => day = v ?? day),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text(tr('شهر البداية', 'Start month'))),
                    TextButton(
                      onPressed: () async {
                        final picked = await pickWheelDate(
                          ctx,
                          initial: start,
                          first: DateTime(2023),
                          last: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() =>
                              start = DateTime(picked.year, picked.month));
                        }
                      },
                      child: Text(DateFormat('MMMM y', 'ar').format(start)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      final amountV = parseNumber(amount.text);
      final totalV = int.tryParse(toEnglishDigits(total.text));
      final turnV = int.tryParse(toEnglishDigits(turn.text));
      if (name.text.trim().isNotEmpty &&
          amountV != null &&
          amountV > 0 &&
          totalV != null &&
          totalV > 0 &&
          turnV != null &&
          turnV >= 1 &&
          turnV <= totalV) {
        await _repo.save(Gameya(
          id: g?.id,
          name: name.text.trim(),
          amount: amountV,
          dayOfMonth: day,
          totalMonths: totalV,
          myTurn: turnV,
          startMonth: MoneyRepo.monthPrefix(start.year, start.month),
        ));
        if (mounted) await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('راجع البيانات — دورك لازم يكون بين ١ وعدد الشهور',
                'Check the data — your turn must be between 1 and months'))));
      }
    }
    name.dispose();
    amount.dispose();
    total.dispose();
    turn.dispose();
  }
}
