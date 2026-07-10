import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/assets_repo.dart';
import '../../data/debts_repo.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';

/// أموالي الخارجية — الأصول اللي مش سايلة (دهب/عقار/استثمار...) + صافي الثروة
/// = المحافظ + الأصول + اللي ليك − اللي عليك.
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _repo = AssetsRepo();
  bool _loading = true;
  List<Asset> _items = [];
  double _assetsTotal = 0;
  double _walletsTotal = 0;
  double _owedToMe = 0;
  double _iOwe = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    final walletsTotal = await WalletsRepo().totalBalance();
    final (owedToMe, iOwe) = await DebtsRepo().totals();
    if (!mounted) return;
    setState(() {
      _items = items;
      _assetsTotal = items.fold<double>(0, (s, e) => s + e.value);
      _walletsTotal = walletsTotal;
      _owedToMe = owedToMe;
      _iOwe = iOwe;
      _loading = false;
    });
  }

  double get _netWorth => _walletsTotal + _assetsTotal + _owedToMe - _iOwe;

  Future<void> _assetForm([Asset? a]) async {
    final name = TextEditingController(text: a?.name ?? '');
    final value = TextEditingController(
        text: a == null ? '' : a.value.toStringAsFixed(0));
    final note = TextEditingController(text: a?.note ?? '');
    var type = a?.type ?? kAssetTypes.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(a == null
              ? tr('أصل جديد', 'New asset')
              : tr('تعديل', 'Edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: a == null,
                  decoration: InputDecoration(
                      labelText: tr('الاسم (دهب أمي، شقة...)',
                          'Name (gold, flat...)')),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in kAssetTypes)
                      ChoiceChip(
                        label: Text(
                            '${assetTypeEmoji(t)} ${assetTypeLabel(t)}'),
                        selected: type == t,
                        onSelected: (_) => setD(() => type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: tr('القيمة التقديرية (ج.م)',
                          'Estimated value (EGP)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                      labelText: tr('ملاحظة (اختياري)', 'Note (optional)')),
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
    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.save(Asset(
        id: a?.id,
        name: name.text.trim(),
        type: type,
        value: parseNumber(value.text) ?? 0,
        note: note.text.trim(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    value.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('أموالي الخارجية', 'My assets')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              children: [
                // ---- بطاقة صافي الثروة ----
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(tr('صافي ثروتك', 'Net worth'),
                            style: TextStyle(
                                color: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.8))),
                        Text(egp(_netWorth),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer)),
                        const SizedBox(height: 10),
                        _breakdownRow(
                            tr('في المحافظ', 'In wallets'), _walletsTotal),
                        _breakdownRow(tr('أصول خارجية', 'Assets'), _assetsTotal),
                        if (_owedToMe > 0)
                          _breakdownRow(tr('ليك عند الناس', 'Owed to you'),
                              _owedToMe),
                        if (_iOwe > 0)
                          _breakdownRow(
                              tr('عليك للناس', 'You owe'), -_iOwe),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyHint(
                      icon: Icons.diamond_outlined,
                      text: tr(
                          'ضيف أصولك (دهب، عقار، شهادات) عشان تعرف صافي ثروتك',
                          'Add your assets (gold, property, certificates) to see net worth'),
                    ),
                  )
                else
                  for (final a in _items)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        leading: Text(assetTypeEmoji(a.type),
                            style: const TextStyle(fontSize: 24)),
                        title: Text(a.name),
                        subtitle: Text(a.note.isEmpty
                            ? assetTypeLabel(a.type)
                            : '${assetTypeLabel(a.type)} • ${a.note}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(egp(a.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await _assetForm(a);
                                } else if (v == 'delete') {
                                  if (!await confirmDelete(context,
                                      tr('أصل «${a.name}»',
                                          'asset "${a.name}"'))) {
                                    return;
                                  }
                                  await _repo.delete(a.id!);
                                  if (mounted) await _load();
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: 'edit',
                                    child: Text(tr('تعديل', 'Edit'))),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text(tr('حذف', 'Delete'))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'assets_fab',
        onPressed: () => _assetForm(),
        tooltip: tr('أصل جديد', 'New asset'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _breakdownRow(String label, double amount) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color:
                        scheme.onPrimaryContainer.withValues(alpha: 0.85))),
          ),
          const SizedBox(width: 8),
          Text(egp(amount),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: amount < 0
                      ? scheme.error
                      : scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}
