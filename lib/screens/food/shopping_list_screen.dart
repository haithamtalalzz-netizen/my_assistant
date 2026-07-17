import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/meals_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _repo = MealsRepo();
  final _settings = SettingsRepo();
  final _input = TextEditingController();
  bool _loading = true;
  List<ShoppingItem> _items = [];
  String _addCat = kShoppingCategories.first;
  double _total = 0;

  /// ترتيب الممرات المحفوظ (ترتيب سوبرماركت المستخدم).
  List<String> _aisleOrder = kShoppingCategories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.shoppingItems();
    final total = await _repo.shoppingTotal();
    final order =
        orderedShoppingCategories(await _settings.cardOrder('shopping_aisles'));
    if (!mounted) return;
    setState(() {
      _items = items;
      _total = total;
      _aisleOrder = order;
      _loading = false;
    });
  }

  /// ترتيب الممرات: يسحب المستخدم التصنيفات لترتيب سوبرماركت بتاعه، وتتحفظ.
  Future<void> _editAisleOrder() async {
    final order = List<String>.from(_aisleOrder);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('ترتيب ممرات السوبرماركت', 'Supermarket aisle order'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  tr('رتّب التصنيفات زى ما بتمشى فى السوبر — القائمة هتتبع ترتيبك',
                      'Order categories to match your store — the list will follow'),
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(ctx).colorScheme.outline)),
              const SizedBox(height: 8),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
                  buildDefaultDragHandles: true,
                  // onReorderItem بيظبط الـindex لوحده (بعكس onReorder المهجورة).
                  onReorderItem: (oldI, newI) => setSheet(() {
                    order.insert(newI, order.removeAt(oldI));
                  }),
                  children: [
                    for (final c in order)
                      ListTile(
                        key: ValueKey(c),
                        dense: true,
                        leading: const Icon(Icons.drag_handle),
                        title: Text(shoppingCategoryLabel(c)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(
                  onPressed: () async {
                    await _settings.set('order.shopping_aisles', '');
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) await _load();
                  },
                  child: Text(tr('الترتيب الافتراضى', 'Default order')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    await _settings.setCardOrder('shopping_aisles', order);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) await _load();
                  },
                  child: Text(tr('حفظ', 'Save')),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add() async {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    await _repo.addShoppingItem(name, category: _addCat);
    _input.clear();
    await _load();
  }

  /// تعديل صنف: الاسم + التصنيف + السعر.
  Future<void> _editItem(ShoppingItem item) async {
    final name = TextEditingController(text: item.name);
    final price =
        TextEditingController(text: item.price > 0 ? item.price.toStringAsFixed(0) : '');
    var cat = item.category.isEmpty ? kShoppingCategories.first : item.category;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('تعديل الصنف', 'Edit item')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: tr('الاسم', 'Name'))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: cat,
                decoration: InputDecoration(labelText: tr('التصنيف', 'Category')),
                items: [
                  for (final c in kShoppingCategories)
                    DropdownMenuItem(
                        value: c, child: Text(shoppingCategoryLabel(c))),
                ],
                onChanged: (v) => cat = v ?? cat,
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: tr('السعر (ج.م)', 'Price (EGP)'))),
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
      await _repo.updateShoppingItem(item.id!,
          name: name.text.trim().isEmpty ? item.name : name.text.trim(),
          category: cat,
          price: double.tryParse(toEnglishDigits(price.text.trim())) ?? 0);
      await _load();
    }
    name.dispose();
    price.dispose();
  }

  Future<void> _manageStaples() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => FutureBuilder<List<ShoppingStaple>>(
          future: _repo.staples(),
          builder: (_, snap) {
            final list = snap.data ?? const <ShoppingStaple>[];
            final nameCtrl = TextEditingController();
            return Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('الأساسيات المتكررة', 'Recurring staples'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      tr('حاجات بتشتريها كل شهر — أضفها للقائمة بضغطة',
                          'Things you buy monthly — add them with one tap'),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx).colorScheme.outline)),
                  const SizedBox(height: 8),
                  ...list.map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        subtitle: s.category.isEmpty
                            ? null
                            : Text(shoppingCategoryLabel(s.category)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () async {
                            await _repo.deleteStaple(s.id!);
                            setSheet(() {});
                          },
                        ),
                      )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                              hintText: tr('أساسي جديد', 'New staple')),
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          await _repo.addStaple(nameCtrl.text.trim());
                          setSheet(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.playlist_add_check),
                      label: Text(tr('أضف الأساسيات للقائمة',
                          'Add staples to list')),
                      onPressed: () async {
                        final n = await _repo.addStaplesToList();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          await _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(tr('اتضاف ${arNum(n)} صنف',
                                    '${arNum(n)} items added'))));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _groupedList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _items.where((i) => !i.checked).toList();
    final done = _items.where((i) => i.checked).toList();
    final byCat = <String, List<ShoppingItem>>{};
    for (final it in active) {
      byCat
          .putIfAbsent(it.category.isEmpty ? 'أخرى' : it.category, () => [])
          .add(it);
    }
    final order = [
      ..._aisleOrder,
      ...byCat.keys.where((k) => !_aisleOrder.contains(k)),
    ];
    final widgets = <Widget>[];
    for (final cat in order) {
      final list = byCat[cat];
      if (list == null || list.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(shoppingCategoryLabel(cat),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary)),
      ));
      for (final it in list) {
        widgets.add(_itemTile(it, scheme));
      }
    }
    if (done.isNotEmpty) {
      widgets.add(const Divider(height: 20));
      for (final it in done) {
        widgets.add(_itemTile(it, scheme));
      }
    }
    return widgets;
  }

  Widget _itemTile(ShoppingItem item, ColorScheme scheme) => CheckboxListTile(
        value: item.checked,
        dense: true,
        onChanged: (v) async {
          HapticFeedback.selectionClick();
          await _repo.setChecked(item.id!, v ?? false);
          await _load();
        },
        title: Text(item.name,
            style: item.checked
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: scheme.outline)
                : null),
        subtitle: item.price > 0 ? Text(egp(item.price)) : null,
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: tr('تعديل', 'Edit'),
              onPressed: () => _editItem(item),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              tooltip: tr('حذف', 'Delete'),
              onPressed: () async {
                await _repo.deleteShoppingItem(item.id!);
                await _load();
              },
            ),
          ],
        ),
      );

  Widget _progressHeader(BuildContext context, int checked) {
    final total = _items.length;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    checked == total
                        ? tr('اشتريت كل حاجة ✓', 'Got everything ✓')
                        : tr('${arNum(checked)} من ${arNum(total)} اتشالت',
                            '${arNum(checked)} of ${arNum(total)} in cart'),
                    style: TextStyle(fontSize: 12.5, color: scheme.outline)),
              ),
              if (_total > 0)
                Text(tr('التقدير: ${egp(_total)}', 'Est: ${egp(_total)}'),
                    style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.primary,
                        fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : checked / total,
              minHeight: 6,
              color: checked == total ? Colors.green : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.where((i) => i.checked).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('قائمة التسوق', 'Shopping list')),
        actions: [
          searchAction(context),
          IconButton(
            tooltip: tr('ترتيب الممرات', 'Aisle order'),
            icon: const Icon(Icons.reorder),
            onPressed: _editAisleOrder,
          ),
          IconButton(
            tooltip: tr('الأساسيات', 'Staples'),
            icon: const Icon(Icons.repeat),
            onPressed: _manageStaples,
          ),
          if (checkedCount > 0)
            TextButton(
              onPressed: () async {
                await _repo.clearChecked();
                await _load();
              },
              child: Text(tr('امسح المتشال', 'Clear checked')),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration: InputDecoration(
                              labelText: tr('ضيف صنف (مثلًا: رز، زيت...)',
                                  'Add item (e.g. rice, oil...)')),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _addCat,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final c in kShoppingCategories)
                            DropdownMenuItem(
                                value: c,
                                child: Text(shoppingCategoryLabel(c),
                                    style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) =>
                            setState(() => _addCat = v ?? _addCat),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                          onPressed: _add, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                if (_items.isNotEmpty) _progressHeader(context, checkedCount),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyHint(
                          icon: Icons.shopping_cart_outlined,
                          text: tr('القائمة فاضية — ضيف أول صنف',
                              'List is empty — add the first item'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: _groupedList(context),
                        ),
                ),
              ],
            ),
    );
  }
}
