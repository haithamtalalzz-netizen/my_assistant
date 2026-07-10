import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/social_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _repo = SocialRepo();
  bool _loading = true;
  List<SocialObligation> _items = [];
  List<({String person, double net})> _balance = [];
  String? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all(direction: _filter);
    final balance = await _repo.perPersonBalance();
    if (!mounted) return;
    setState(() {
      _items = items;
      _balance = balance;
      _loading = false;
    });
  }

  Future<void> _form([SocialObligation? o]) async {
    final person = TextEditingController(text: o?.person ?? '');
    final amount =
        TextEditingController(text: o?.amount == null ? '' : o!.amount!.toStringAsFixed(0));
    final occasion = TextEditingController(text: o?.occasion ?? '');
    var type = o?.type ?? kSocialTypes.first;
    var direction = o?.direction ?? kSocialDirections.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(o == null
              ? tr('واجب اجتماعي جديد', 'New social obligation')
              : tr('تعديل', 'Edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: person,
                  autofocus: o == null,
                  decoration: InputDecoration(
                      labelText: tr('الشخص', 'Person')),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final d in kSocialDirections)
                      ChoiceChip(
                        label: Text(socialDirectionLabel(d)),
                        selected: direction == d,
                        onSelected: (_) => setD(() => direction = d),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in kSocialTypes)
                      ChoiceChip(
                        label: Text(socialTypeLabel(t)),
                        selected: type == t,
                        onSelected: (_) => setD(() => type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: tr('المبلغ (اختياري)', 'Amount (optional)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: occasion,
                  decoration: InputDecoration(
                      labelText: tr('المناسبة (فرح، عيد...)',
                          'Occasion (wedding, Eid...)')),
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
    if (saved == true && person.text.trim().isNotEmpty) {
      await _repo.save(SocialObligation(
        id: o?.id,
        person: person.text.trim(),
        type: type,
        direction: direction,
        amount: parseNumber(amount.text),
        occasion: occasion.text.trim(),
        day: o?.day ?? dayKey(DateTime.now()),
        reciprocated: o?.reciprocated ?? false,
      ));
      if (mounted) await _load();
    }
    person.dispose();
    amount.dispose();
    occasion.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('الواجبات الاجتماعية', 'Social ledger'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_balance.isNotEmpty) _balanceCard(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text(tr('الكل', 'All')),
                        selected: _filter == null,
                        onSelected: (_) {
                          setState(() => _filter = null);
                          _load();
                        },
                      ),
                      for (final d in kSocialDirections)
                        ChoiceChip(
                          label: Text(socialDirectionLabel(d)),
                          selected: _filter == d,
                          onSelected: (_) {
                            setState(() => _filter = d);
                            _load();
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyHint(
                          icon: Icons.volunteer_activism_outlined,
                          text: tr(
                              'سجّل النقوط والعزومات والعيديات — واعرف مين لسه مردتلوش',
                              'Log gift money, invites & Eidiya — know who to reciprocate'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                            itemCount: _items.length,
                            itemBuilder: (context, i) => _tile(context, _items[i]),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'social_fab',
        onPressed: () => _form(),
        tooltip: tr('جديد', 'New'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _balanceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // موجب = إداك أكتر → مطلوب منك ترد.
    final owe = _balance.where((b) => b.net > 0).toList();
    if (owe.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('مطلوب منك ترد لـ:', 'You should reciprocate:'),
                style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...owe.take(5).map((b) => Text(
                '• ${b.person}: ${egp(b.net)}',
                style: TextStyle(color: scheme.onTertiaryContainer))),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, SocialObligation o) {
    final scheme = Theme.of(context).colorScheme;
    final received = o.direction == 'received';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(
            received ? Icons.south_west : Icons.north_east,
            color: received ? Colors.green : Colors.deepOrange),
        title: Text(o.person),
        subtitle: Text([
          socialTypeLabel(o.type),
          if (o.occasion.isNotEmpty) o.occasion,
          arShortDate(DateTime.parse(o.day)),
          if (o.reciprocated) tr('تم الرد ✓', 'Reciprocated ✓'),
        ].join(' • ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (o.amount != null)
              Text(egp(o.amount!),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: received ? Colors.green : scheme.onSurface)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await _form(o);
                } else if (v == 'recip') {
                  await _repo.setReciprocated(o.id!, !o.reciprocated);
                  if (mounted) await _load();
                } else if (v == 'delete') {
                  if (!await confirmDelete(context,
                      tr('واجب "${o.person}"', 'obligation "${o.person}"'))) {
                    return;
                  }
                  await _repo.delete(o.id!);
                  if (mounted) await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'recip',
                    child: Text(o.reciprocated
                        ? tr('شيل علامة الرد', 'Unmark reciprocated')
                        : tr('علّم اترد', 'Mark reciprocated'))),
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
