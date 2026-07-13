import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/subscriptions_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// الاشتراكات الدورية — نتفليكس/جيم/إنترنت + تنبيه التجديد + إجمالى شهرى.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _repo = SubscriptionsRepo();
  bool _loading = true;
  List<Subscription> _subs = [];
  double _monthly = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subs = await _repo.all();
    final monthly = await _repo.monthlyTotal();
    if (!mounted) return;
    setState(() {
      _subs = subs;
      _monthly = monthly;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الاشتراكات', 'Subscriptions'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    color: scheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(tr('التكلفة الشهرية', 'Monthly cost'),
                              style: TextStyle(color: scheme.onPrimaryContainer)),
                          const SizedBox(height: 4),
                          Text(egp(_monthly),
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onPrimaryContainer)),
                          Text(
                              tr('≈ ${egp(_monthly * 12)} سنويًا',
                                  '≈ ${egp(_monthly * 12)} / year'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onPrimaryContainer
                                      .withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_subs.isEmpty)
                    EmptyHint(
                        icon: Icons.subscriptions_outlined,
                        text: tr('مفيش اشتراكات — ضيف بزرار +',
                            'No subscriptions — add one with +'))
                  else
                    for (final s in _subs) _subTile(s, scheme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('اشتراك جديد', 'New subscription'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _subTile(Subscription s, ColorScheme scheme) {
    final cycle = s.cycle == 'yearly' ? tr('سنوى', 'Yearly') : tr('شهرى', 'Monthly');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Switch(
          value: s.active,
          onChanged: (v) async {
            await _repo.setActive(s.id!, v);
            await _load();
          },
        ),
        title: Text(s.name,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: s.active ? null : scheme.outline)),
        subtitle: Text(
            '${egp(s.amount)} · $cycle · ${tr('يوم', 'day')} ${arNum(s.dayOfMonth)}'
            '${s.category.isEmpty ? '' : ' · ${subscriptionCategoryLabel(s.category)}'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _form(s);
            if (v == 'delete') {
              if (!mounted) return;
              if (await confirmDelete(
                  context, tr('اشتراك "${s.name}"', 'subscription "${s.name}"'))) {
                await _repo.delete(s.id!);
                if (mounted) await _load();
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _form(s),
      ),
    );
  }

  Future<void> _form([Subscription? sub]) async {
    final name = TextEditingController(text: sub?.name ?? '');
    final amount =
        TextEditingController(text: sub == null ? '' : sub.amount.toStringAsFixed(0));
    var cycle = sub?.cycle ?? 'monthly';
    var dayOfMonth = sub?.dayOfMonth ?? 1;
    var category = sub?.category ?? kSubscriptionCategories.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(sub == null
              ? tr('اشتراك جديد', 'New subscription')
              : tr('تعديل اشتراك', 'Edit subscription')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                autofocus: sub == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (نتفليكس، جيم…)', 'Name (Netflix, gym…)')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(tr('شهرى', 'Monthly')),
                    selected: cycle == 'monthly',
                    onSelected: (_) => setD(() => cycle = 'monthly'),
                  ),
                  ChoiceChip(
                    label: Text(tr('سنوى', 'Yearly')),
                    selected: cycle == 'yearly',
                    onSelected: (_) => setD(() => cycle = 'yearly'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(tr('يوم التجديد', 'Renewal day'))),
                  DropdownButton<int>(
                    value: dayOfMonth,
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text(arNum(d))),
                    ],
                    onChanged: (v) => setD(() => dayOfMonth = v ?? dayOfMonth),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: tr('الفئة', 'Category')),
                items: [
                  for (final c in kSubscriptionCategories)
                    DropdownMenuItem(
                        value: c, child: Text(subscriptionCategoryLabel(c))),
                ],
                onChanged: (v) => category = v ?? category,
              ),
            ],
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
      final v = parseNumber(amount.text);
      if (name.text.trim().isNotEmpty && v != null && v > 0) {
        await _repo.save(Subscription(
          id: sub?.id,
          name: name.text.trim(),
          amount: v,
          cycle: cycle,
          dayOfMonth: dayOfMonth,
          category: category,
          active: sub?.active ?? true,
          notes: sub?.notes ?? '',
          lastPaidMonth: sub?.lastPaidMonth ?? '',
          createdAt: sub?.createdAt ?? DateTime.now().toIso8601String(),
        ));
        if (mounted) await _load();
      }
    }
    name.dispose();
    amount.dispose();
  }
}
