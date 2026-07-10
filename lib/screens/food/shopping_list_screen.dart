import 'package:flutter/material.dart';

import '../../core/l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.where((i) => i.checked).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('قائمة التسوق', 'Shopping list')),
        actions: [
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
