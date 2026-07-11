import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/meals_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _repo = MealsRepo();
  final _input = TextEditingController();
  bool _loading = true;
  List<ShoppingItem> _items = [];

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
    // اللي لسه ماتشالش فوق، المتشال تحت.
    items.sort((a, b) {
      if (a.checked == b.checked) return 0;
      return a.checked ? 1 : -1;
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    await _repo.addShoppingItem(name);
    _input.clear();
    await _load();
  }

  Widget _progressHeader(BuildContext context, int checked) {
    final total = _items.length;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              checked == total
                  ? tr('اشتريت كل حاجة ✓', 'Got everything ✓')
                  : tr('${arNum(checked)} من ${arNum(total)} اتشالت',
                      '${arNum(checked)} of ${arNum(total)} in cart'),
              style: TextStyle(fontSize: 12.5, color: scheme.outline)),
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
                      const SizedBox(width: 8),
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
                          children: [
                            for (final item in _items)
                              CheckboxListTile(
                                value: item.checked,
                                onChanged: (v) async {
                                  HapticFeedback.selectionClick();
                                  await _repo.setChecked(
                                      item.id!, v ?? false);
                                  await _load();
                                },
                                title: Text(
                                  item.name,
                                  style: item.checked
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough)
                                      : null,
                                ),
                                secondary: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: tr('حذف', 'Delete'),
                                  onPressed: () async {
                                    await _repo
                                        .deleteShoppingItem(item.id!);
                                    await _load();
                                  },
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
