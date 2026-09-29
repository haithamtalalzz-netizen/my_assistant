import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/income_repo.dart';
import '../../data/money_categories.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';

/// **دخلك الثابت** — المرتب وأى دخل بيتكرّر كل شهر.
///
/// «دخلك» فى فلوسى بتفتح هنا عشان تشوف البنود اللى ضفتها وتعدّلها،
/// مش عشان تضيف واحد جديد على طول.
class RecurringIncomeScreen extends StatefulWidget {
  const RecurringIncomeScreen({super.key});

  @override
  State<RecurringIncomeScreen> createState() => _RecurringIncomeScreenState();
}

class _RecurringIncomeScreenState extends State<RecurringIncomeScreen> {
  final _repo = IncomeRepo();
  List<RecurringIncome> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.allRecurring();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _form([RecurringIncome? inc]) async {
    final amount = TextEditingController(
        text: inc == null ? '' : inc.amount.toStringAsFixed(0));
    final note = TextEditingController(text: inc?.note ?? '');
    var source = inc?.source ?? kIncomeSources.first;
    var dayOfMonth = inc?.dayOfMonth ?? 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(inc == null
              ? tr('دخل ثابت جديد', 'New recurring income')
              : tr('تعديل الدخل', 'Edit income')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in MoneyCategories.income)
                ChoiceChip(
                  label: Text(incomeSourceLabel(s)),
                  selected: source == s,
                  onSelected: (_) => setDialogState(() => source = s),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 17),
                label: Text(tr('بند جديد', 'New')),
                onPressed: () async {
                  final n = await askNewCategory(
                      context, tr('بند دخل جديد', 'New income source'));
                  if (n == null) return;
                  await MoneyCategories.addIncome(n);
                  setDialogState(() => source = n);
                },
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              autofocus: inc == null,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: tr('المبلغ', 'Amount')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: tr('ملاحظة — الفلوس دى خاصة بإيه؟',
                    'Note — what is this money for?'),
                hintText: tr('مثلًا: إيجار الشقة', 'e.g. flat rent'),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(tr('يوم القبض', 'Payday'))),
              DropdownButton<int>(
                value: dayOfMonth,
                items: [
                  for (var d = 1; d <= 28; d++)
                    DropdownMenuItem(value: d, child: Text(arNum(d))),
                ],
                onChanged: (v) =>
                    setDialogState(() => dayOfMonth = v ?? dayOfMonth),
              ),
            ]),
          ]),
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
      final value = parseNumber(amount.text);
      if (value != null && value > 0) {
        await _repo.saveRecurring(RecurringIncome(
          id: inc?.id,
          source: source,
          amount: value,
          dayOfMonth: dayOfMonth,
          note: note.text.trim(),
          lastReceivedMonth: inc?.lastReceivedMonth ?? '',
        ));
        if (mounted) await _load();
      }
    }
    amount.dispose();
    note.dispose();
  }

  Future<void> _delete(RecurringIncome i) async {
    if (!await confirmDelete(context,
        tr('دخل "${incomeSourceLabel(i.source)}"', 'income "${i.source}"'))) {
      return;
    }
    await _repo.deleteRecurring(i.id!);
    if (mounted) await _load();
  }

  Future<void> _markReceived(RecurringIncome i) async {
    await _repo.markReceived(i, now: DateTime.now());
    if (mounted) await _load();
  }

  /// الشهر الحالى بصيغة YYYY-MM — عشان نعرف اتقبض ولا لأ.
  String get _thisMonth {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _items.fold<double>(0, (t, i) => t + i.amount);
    const green = Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(title: Text(tr('دخلك الثابت', 'Recurring income'))),
      floatingActionButton: FloatingActionButton(
        heroTag: 'income_fab',
        onPressed: () => _form(),
        tooltip: tr('ضيف دخل', 'Add income'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.event_repeat,
                  text: tr('سجّل مرتبك مرة واحدة — وهفكّرك يوم القبض',
                      'Log your salary once — reminded on payday'),
                  actionLabel: tr('ضيف دخل ثابت', 'Add income'),
                  onAction: _form,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: [
                      AppCard(
                        Row(children: [
                          Expanded(
                            child: Text(
                                tr('بيجيلك كل شهر', 'Coming in every month'),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant)),
                          ),
                          Text(arMoney(total.round()),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: green)),
                        ]),
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      ),
                      AppGroupHead(tr('بنود دخلك', 'Your income'),
                          trail: arNum(_items.length)),
                      for (var i = 0; i < _items.length; i++)
                        AppListRow(
                          title: incomeSourceLabel(_items[i].source),
                          sub: _items[i].note.isNotEmpty
                              ? tr(
                                  'يوم ${arNum(_items[i].dayOfMonth)} · ${_items[i].note}',
                                  'day ${arNum(_items[i].dayOfMonth)} · ${_items[i].note}')
                              : tr('يوم ${arNum(_items[i].dayOfMonth)} من الشهر',
                                  'day ${arNum(_items[i].dayOfMonth)}'),
                          icon: Icons.payments,
                          tint: green,
                          divider: i != _items.length - 1,
                          onTap: () => _form(_items[i]),
                          onLongPress: () => _delete(_items[i]),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_items[i].lastReceivedMonth == _thisMonth)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(Icons.check_circle,
                                        size: 16, color: green),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: TextButton(
                                      onPressed: () =>
                                          _markReceived(_items[i]),
                                      style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8)),
                                      child: Text(tr('قبضته', 'Received'),
                                          style:
                                              const TextStyle(fontSize: 11.5)),
                                    ),
                                  ),
                                Text(arMoney(_items[i].amount.round()),
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900)),
                              ]),
                        ),
                      const SizedBox(height: 10),
                      Text(
                          tr('دوس على البند تعدّله · دوس مطوّل تمسحه',
                              'Tap to edit · long-press to delete'),
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
    );
  }
}
