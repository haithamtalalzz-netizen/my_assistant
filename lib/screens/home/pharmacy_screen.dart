import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/pharmacy_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/wheel_date_picker.dart';
import '../schedule/med_form.dart';

/// صف دفعة قابل للتعديل داخل الفورم (كمية + صلاحية).
class _BatchEdit {
  final TextEditingController qty;
  DateTime? exp;
  _BatchEdit(this.qty, this.exp);
}

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _repo = PharmacyRepo();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<PharmacyItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.search(_searchCtrl.text);
    // الأقرب انتهاءً (والمنتهي) الأول؛ اللي من غير صلاحية في الآخر.
    items.sort((a, b) {
      if (a.expiry == null && b.expiry == null) return 0;
      if (a.expiry == null) return 1;
      if (b.expiry == null) return -1;
      return a.expiry!.compareTo(b.expiry!);
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// عدد المنتهي + القريب من الانتهاء (خلال ٦٠ يوم).
  ({int expired, int soon}) _expiryCounts() {
    final now = DateTime.now();
    var expired = 0, soon = 0;
    for (final it in _items) {
      final exp = it.expiry == null ? null : DateTime.tryParse(it.expiry!);
      if (exp == null) continue;
      if (exp.isBefore(now)) {
        expired++;
      } else if (exp.difference(now).inDays <= 60) {
        soon++;
      }
    }
    return (expired: expired, soon: soon);
  }

  Future<void> _form([PharmacyItem? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final notes = TextEditingController(text: item?.notes ?? '');
    // دفعات: كل كمية بصلاحية مستقلة.
    final batches = <_BatchEdit>[];
    if (item != null) {
      final existing = await _repo.batchesFor(item.id!);
      if (existing.isNotEmpty) {
        for (final b in existing) {
          batches.add(_BatchEdit(
              TextEditingController(text: b.quantity.toString()),
              b.expiry == null ? null : DateTime.tryParse(b.expiry!)));
        }
      } else {
        batches.add(_BatchEdit(
            TextEditingController(text: item.quantity.toString()),
            item.expiry == null ? null : DateTime.tryParse(item.expiry!)));
      }
    } else {
      batches.add(_BatchEdit(TextEditingController(text: '1'), null));
    }
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null
              ? tr('دوا جديد', 'New medicine')
              : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: item == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (مثلًا: بانادول)',
                        'Name (e.g. Panadol)')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                decoration: InputDecoration(
                    labelText: tr('ملاحظة (لإيه؟)', 'Note (what for?)')),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tr('الكميات والصلاحيات', 'Quantities & expiry'),
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              for (var i = 0; i < batches.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: batches[i].qty,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: tr('عدد', 'Qty')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await pickWheelDate(
                              ctx,
                              initial: batches[i].exp ?? now,
                              first: DateTime(now.year - 1),
                              last: DateTime(now.year + 15),
                            );
                            if (picked != null) {
                              setD(() => batches[i].exp = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                                labelText: tr('صلاحية', 'Expiry')),
                            child: Text(batches[i].exp == null
                                ? tr('بدون', 'None')
                                : arShortDate(batches[i].exp!)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: batches.length == 1
                            ? null
                            : () => setD(() => batches.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setD(() => batches
                      .add(_BatchEdit(TextEditingController(text: '1'), null))),
                  icon: const Icon(Icons.add),
                  label: Text(tr('أضف دفعة بصلاحية مختلفة', 'Add batch')),
                ),
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
    if (saved == true && name.text.trim().isNotEmpty) {
      final list = [
        for (final b in batches)
          PharmacyBatch(
              itemId: 0,
              quantity: int.tryParse(b.qty.text.trim()) ?? 1,
              expiry: b.exp == null ? null : dayKey(b.exp!)),
      ];
      final totalQty = list.fold<int>(0, (s, b) => s + b.quantity);
      final expiries = list.map((b) => b.expiry).whereType<String>().toList()
        ..sort();
      final nearest = expiries.isEmpty ? null : expiries.first;
      final id = await _repo.save(PharmacyItem(
        id: item?.id,
        name: name.text.trim(),
        quantity: totalQty,
        expiry: nearest,
        notes: notes.text.trim(),
      ));
      await _repo.replaceBatches(id, list);
      if (mounted) await _load();
    }
    name.dispose();
    notes.dispose();
    for (final b in batches) {
      b.qty.dispose();
    }
  }

  Widget _expiryBanner(BuildContext context) {
    final c = _expiryCounts();
    if (c.expired == 0 && c.soon == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final parts = [
      if (c.expired > 0) tr('${arNum(c.expired)} منتهي', '${arNum(c.expired)} expired'),
      if (c.soon > 0)
        tr('${arNum(c.soon)} قربت تنتهي', '${arNum(c.soon)} expiring soon'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.expired > 0
            ? scheme.errorContainer
            : scheme.tertiary.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: c.expired > 0 ? scheme.onErrorContainer : scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(parts.join(' • '),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c.expired > 0 ? scheme.onErrorContainer : null)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(tr('صيدلية البيت', 'Home pharmacy'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('عندك بانادول؟ دوّر...', 'Got Panadol? Search...'),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          if (!_loading && _searchCtrl.text.isEmpty) _expiryBanner(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyHint(
                        icon: Icons.medication_outlined,
                        actionLabel: _searchCtrl.text.isEmpty
                            ? tr('ضيف دوا', 'Add medicine')
                            : null,
                        onAction:
                            _searchCtrl.text.isEmpty ? () => _form() : null,
                        text: _searchCtrl.text.isEmpty
                            ? tr('سجّل أدوية البيت وصلاحيتها — تعرف عندك إيه وتتنبّه قبل ما تخلص',
                                'Log home meds & expiry — know what you have and get alerts')
                            : tr('مش موجود عندك', "You don't have it"))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          final exp = it.expiry == null
                              ? null
                              : DateTime.tryParse(it.expiry!);
                          final expired = exp != null && exp.isBefore(now);
                          final soon = exp != null &&
                              !expired &&
                              exp.difference(now).inDays <= 60;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              leading: Icon(Icons.medication,
                                  color: expired
                                      ? scheme.error
                                      : scheme.primary),
                              title: Text(
                                  '${it.name}  ×${arNum(it.quantity)}'),
                              subtitle: Text([
                                if (it.notes.isNotEmpty) it.notes,
                                if (exp != null)
                                  expired
                                      ? tr('منتهي ${arShortDate(exp)}',
                                          'Expired ${arShortDate(exp)}')
                                      : tr('صلاحية ${arShortDate(exp)}',
                                          'Expires ${arShortDate(exp)}'),
                              ].join(' • ')),
                              subtitleTextStyle: expired
                                  ? TextStyle(color: scheme.error)
                                  : soon
                                      ? const TextStyle(color: Colors.orange)
                                      : null,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await _form(it);
                                  } else if (v == 'tomeds') {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                MedForm(initialName: it.name)));
                                    if (mounted) await _load();
                                  } else if (v == 'delete') {
                                    await _repo.delete(it.id!);
                                    if (mounted) await _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(tr('تعديل', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'tomeds',
                                      child: Text(tr('أضفه لجدول الأدوية',
                                          'Add to med schedule'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(tr('حذف', 'Delete'))),
                                ],
                              ),
                              onTap: () => _form(it),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pharmacy_fab',
        onPressed: () => _form(),
        tooltip: tr('دوا جديد', 'New medicine'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
