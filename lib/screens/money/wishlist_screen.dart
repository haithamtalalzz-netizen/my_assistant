import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/wishlist_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// قائمة الأمنيات — حاجات عايز تشتريها بأولوية وسعر.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

const _prioColors = [Colors.grey, Colors.blue, Colors.redAccent];
String _prioLabel(int p) => switch (p) {
      0 => tr('لسه', 'Someday'),
      2 => tr('نفسي فيها', 'Really want'),
      _ => tr('عادي', 'Normal'),
    };

class _WishlistScreenState extends State<WishlistScreen> {
  final _repo = WishlistRepo();
  bool _loading = true;
  List<WishItem> _items = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    final total = await _repo.pendingTotal();
    if (!mounted) return;
    setState(() {
      _items = items;
      _total = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('قائمة الأمنيات', 'Wishlist'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  if (_total > 0)
                    Card(
                      margin: EdgeInsets.zero,
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.savings_outlined,
                                color: scheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  tr('محتاج ${egp(_total)} عشان أمنياتك',
                                      'You need ${egp(_total)} for your wishes'),
                                  style: TextStyle(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    EmptyHint(
                        icon: Icons.favorite_outline,
                        text: tr('ضيف حاجة نفسك فيها بزرار +',
                            'Add something you want with +'))
                  else
                    for (final w in _items) _tile(w, scheme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('أمنية جديدة', 'New wish'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(WishItem w, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Checkbox(
          value: w.bought,
          onChanged: (v) async {
            await _repo.setBought(w.id!, v ?? false);
            await _load();
          },
        ),
        title: Text(w.name,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: w.bought ? TextDecoration.lineThrough : null,
                color: w.bought ? scheme.outline : null)),
        subtitle: Text([
          if (w.price > 0) egp(w.price),
          _prioLabel(w.priority),
          if (w.note.isNotEmpty) w.note,
        ].join('  •  ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: _prioColors[w.priority], shape: BoxShape.circle)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') await _form(w);
                if (v == 'delete') {
                  await _repo.delete(w.id!);
                  await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
        onTap: () => _form(w),
      ),
    );
  }

  Future<void> _form([WishItem? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final price = TextEditingController(
        text: item == null || item.price == 0 ? '' : item.price.toStringAsFixed(0));
    final note = TextEditingController(text: item?.note ?? '');
    var priority = item?.priority ?? 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null ? tr('أمنية جديدة', 'New wish') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: name,
                  autofocus: item == null,
                  decoration: InputDecoration(labelText: tr('الاسم', 'Name'))),
              const SizedBox(height: 8),
              TextField(
                  controller: price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: tr('السعر (ج.م)', 'Price (EGP)'))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (var p = 0; p <= 2; p++)
                    ChoiceChip(
                      label: Text(_prioLabel(p)),
                      selected: priority == p,
                      onSelected: (_) => setD(() => priority = p),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: tr('ملاحظة', 'Note'))),
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
      await _repo.save(WishItem(
        id: item?.id,
        name: name.text.trim(),
        price: double.tryParse(toEnglishDigits(price.text.trim())) ?? 0,
        priority: priority,
        note: note.text.trim(),
        bought: item?.bought ?? false,
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    price.dispose();
    note.dispose();
  }
}
