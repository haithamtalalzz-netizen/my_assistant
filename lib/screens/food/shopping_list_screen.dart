import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../widgets/search_action.dart';
import '../../data/meals_repo.dart';
import '../../data/money_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// قائمة تسوق شاملة: كل القوائم (سوبرماركت/صيدلية/ملابس/هدايا...) تحت بعض فى
/// صفحة واحدة — كل قائمة قسم قابل للطى تحته أصنافه وخانة إضافة خاصة بيه؛
/// + «أشتري لاحقاً» + كمية/مكان/سعر + ربط بالميزانية + قوالب.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

/// مفتاح قسم «أشتري لاحقاً» فى الخرائط (مش id قائمة حقيقية).
const int _buyLaterKey = -1;

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _repo = MealsRepo();
  final _settings = SettingsRepo();

  bool _loading = true;
  List<ShoppingList> _lists = [];
  Map<int, List<ShoppingItem>> _itemsByList = {};
  List<ShoppingItem> _buyLater = [];
  List<String> _aisleOrder = kShoppingCategories;

  /// خانة إضافة + تصنيفها لكل قائمة (والمفتاح -1 لـ«أشتري لاحقاً»).
  final Map<int, TextEditingController> _addCtrl = {};
  final Map<int, String> _addCat = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _addCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(int key) =>
      _addCtrl.putIfAbsent(key, TextEditingController.new);

  Future<void> _load() async {
    try {
      final lists = await _repo.shoppingLists();
      final all = await _repo.shoppingItems(); // كل النشط (مش المؤجّل)
      final byList = <int, List<ShoppingItem>>{};
      for (final it in all) {
        if (it.listId != null) {
          byList.putIfAbsent(it.listId!, () => []).add(it);
        }
      }
      final buyLater = await _repo.buyLaterItems();
      final order = orderedShoppingCategories(
          await _settings.cardOrder('shopping_aisles'));
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _itemsByList = byList;
        _buyLater = buyLater;
        _aisleOrder = order;
        _loading = false;
      });
    } on Exception catch (e, st) {
      logError('فشل تحميل قائمة التسوق', e, st);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('حصلت مشكلة فى تحميل القائمة — جرّب تقفل وتفتح',
              'Problem loading the list — try reopening'))));
    }
  }

  // ---- إضافة صنف لقائمة معيّنة ----

  Future<void> _addTo(ShoppingList? list) async {
    final key = list?.id ?? _buyLaterKey;
    final ctrl = _ctrlFor(key);
    final name = ctrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(tr('اكتب اسم الصنف الأول', 'Type an item name first'))));
      return;
    }
    final usesAisles = list?.usesAisles ?? false;
    await _repo.addShoppingItem(name,
        category: usesAisles ? (_addCat[key] ?? kShoppingCategories.first) : '',
        listId: list?.id,
        buyLater: list == null);
    ctrl.clear();
    await _load();
  }

  Future<void> _toggleChecked(ShoppingItem item, bool checked,
      ShoppingList? list) async {
    HapticFeedback.selectionClick();
    await _repo.setChecked(item.id!, checked);
    if (checked && item.price > 0 && mounted) {
      final log = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('تسجيل مصروف؟', 'Log expense?')),
          content: Text(tr(
              'تحب أسجّل «${item.name}» بـ${egp(item.price)} كمصروف؟',
              'Log "${item.name}" for ${egp(item.price)} as an expense?')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('لأ', 'No'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('سجّل', 'Log'))),
          ],
        ),
      );
      if (log == true) {
        await MoneyRepo().add(Expense(
          amount: item.price,
          category: expenseCategoryForList(list?.name ?? ''),
          note: item.name,
          day: dayKey(DateTime.now()),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('اتسجّل مصروف ✓', 'Logged as expense ✓'))));
        }
      }
    }
    await _load();
  }

  /// تعديل صنف (اسم/كمية/مكان/سعر/قائمة/تصنيف/أولوية/لاحقاً).
  Future<void> _editItem(ShoppingItem item) async {
    final name = TextEditingController(text: item.name);
    final qty = TextEditingController(text: item.qty);
    final place = TextEditingController(text: item.place);
    final price = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(0) : '');
    var cat = item.category.isEmpty ? kShoppingCategories.first : item.category;
    var listId = item.listId;
    var buyLater = item.buyLater;
    var priority = item.priority;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('تعديل الصنف', 'Edit item')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: tr('الاسم', 'Name'))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: qty,
                      decoration: InputDecoration(
                          labelText: tr('الكمية (٢ كيلو...)', 'Qty (2 kg...)'),
                          isDense: true)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                      controller: price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: tr('السعر', 'Price'), isDense: true)),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: place,
                  decoration: InputDecoration(
                      labelText: tr('مكان الشراء (اختيارى)', 'Where (optional)'),
                      isDense: true)),
              const SizedBox(height: 8),
              if (_lists.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: listId,
                  decoration: InputDecoration(labelText: tr('القائمة', 'List')),
                  items: [
                    for (final l in _lists)
                      DropdownMenuItem(
                          value: l.id, child: Text('${l.emoji} ${l.name}')),
                  ],
                  onChanged: (v) => setD(() => listId = v ?? listId),
                ),
              // التصنيف لقوائم البقالة بس.
              if (_lists.any((l) => l.id == listId && l.usesAisles)) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  decoration:
                      InputDecoration(labelText: tr('التصنيف', 'Category')),
                  items: [
                    for (final c in kShoppingCategories)
                      DropdownMenuItem(
                          value: c, child: Text(shoppingCategoryLabel(c))),
                  ],
                  onChanged: (v) => cat = v ?? cat,
                ),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: buyLater,
                title: Text(tr('أشتري لاحقاً', 'Buy later')),
                onChanged: (v) => setD(() => buyLater = v),
              ),
              if (buyLater)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: priority == 1,
                  title: Text(tr('مهم / عاجل', 'Important / urgent')),
                  onChanged: (v) => setD(() => priority = (v ?? false) ? 1 : 0),
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
      await _repo.updateShoppingItem(item.id!,
          name: name.text.trim().isEmpty ? item.name : name.text.trim(),
          category: cat,
          qty: qty.text.trim(),
          place: place.text.trim(),
          price: double.tryParse(toEnglishDigits(price.text.trim())) ?? 0,
          listId: listId,
          priority: priority,
          buyLater: buyLater);
      await _load();
    }
    name.dispose();
    qty.dispose();
    place.dispose();
    price.dispose();
  }

  // ---- إدارة القوائم ----

  Future<void> _listForm({ShoppingList? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var emoji = existing?.emoji ?? '🛒';
    var usesAisles = existing?.usesAisles ?? false;
    const emojis = ['🛒', '💊', '👕', '🔧', '📱', '🎁', '👶', '💼', '🏠', '🎨'];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(existing == null
              ? tr('قائمة جديدة', 'New list')
              : tr('تعديل القائمة', 'Edit list')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                      labelText: tr('الاسم (مثلًا: إلكترونيات)',
                          'Name (e.g. Electronics)'))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final e in emojis)
                    ChoiceChip(
                      label: Text(e, style: const TextStyle(fontSize: 18)),
                      selected: emoji == e,
                      onSelected: (_) => setD(() => emoji = e),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: usesAisles,
                title: Text(tr('تصنيف حسب ممرات السوبرماركت',
                    'Group by supermarket aisles')),
                subtitle: Text(
                    tr('خضار/بقالة/لحوم... — للبقالة بس',
                        'Produce/grocery/meat... — for groceries only'),
                    style: const TextStyle(fontSize: 11)),
                onChanged: (v) => setD(() => usesAisles = v),
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
      if (existing == null) {
        await _repo.addShoppingList(name.text.trim(),
            emoji: emoji, usesAisles: usesAisles);
      } else {
        await _repo.renameShoppingList(existing.id!,
            name: name.text.trim(), emoji: emoji, usesAisles: usesAisles);
      }
      if (mounted) await _load();
    }
    name.dispose();
  }

  Future<void> _deleteList(ShoppingList l) async {
    if (!await confirmDelete(context,
        tr('قائمة «${l.name}» وكل بنودها', '"${l.name}" and its items'))) {
      return;
    }
    await _repo.deleteShoppingList(l.id!);
    if (mounted) await _load();
  }

  Future<void> _useTemplate(ShoppingList list) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(tr('قوالب جاهزة → ${list.name}', 'Templates → ${list.name}'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final entry in kShoppingTemplates.entries)
              ListTile(
                dense: true,
                title: Text(entry.key),
                subtitle: Text('${entry.value.take(4).join('، ')}…',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.add),
                onTap: () async {
                  final n = await _repo.addTemplateToList(entry.value,
                      listId: list.id);
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
          ],
        ),
      ),
    );
  }

  Future<void> _addStaples(ShoppingList list) async {
    final n = await _repo.addStaplesToList(listId: list.id);
    if (mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(n == 0
                ? tr('مفيش أساسيات جديدة تتضاف', 'No new staples to add')
                : tr('اتضاف ${arNum(n)} صنف', '${arNum(n)} items added'))));
      }
    }
  }

  // ---- بناء الأقسام ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('قائمة التسوق', 'Shopping list')),
        actions: [
          searchAction(context),
          IconButton(
            tooltip: tr('الأساسيات المتكررة', 'Recurring staples'),
            icon: const Icon(Icons.repeat),
            onPressed: _manageStaples,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 90),
                children: [
                  for (final l in _lists) _listSection(context, l),
                  _buyLaterSection(context),
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(tr('قائمة جديدة', 'New list')),
                      onPressed: () => _listForm(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// قسم قائمة واحدة (سوبرماركت/صيدلية/...) قابل للطى.
  Widget _listSection(BuildContext context, ShoppingList l) {
    final scheme = Theme.of(context).colorScheme;
    final items = _itemsByList[l.id] ?? const [];
    final remaining = items.where((i) => !i.checked).length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Text(l.emoji, style: const TextStyle(fontSize: 22)),
        title: Text(l.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            remaining == 0
                ? (items.isEmpty
                    ? tr('فاضية', 'empty')
                    : tr('اتشالت كلها ✓', 'all done ✓'))
                : tr('${arNum(remaining)} لسه', '${arNum(remaining)} left'),
            style: TextStyle(fontSize: 12, color: scheme.outline)),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'edit':
                _listForm(existing: l);
              case 'delete':
                _deleteList(l);
              case 'templates':
                _useTemplate(l);
              case 'staples':
                _addStaples(l);
              case 'aisles':
                _editAisleOrder();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('✏ تعديل القائمة', '✏ Edit list'))),
            PopupMenuItem(
                value: 'templates',
                child: Text(tr('📋 قالب جاهز', '📋 Template'))),
            PopupMenuItem(
                value: 'staples',
                child: Text(tr('🔁 ضيف الأساسيات', '🔁 Add staples'))),
            if (l.usesAisles)
              PopupMenuItem(
                  value: 'aisles',
                  child: Text(tr('⇅ ترتيب الممرات', '⇅ Aisle order'))),
            PopupMenuItem(value: 'delete', child: Text(tr('🗑 حذف القائمة', '🗑 Delete list'))),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          _addRow(l),
          ..._itemWidgets(context, items, l),
        ],
      ),
    );
  }

  /// قسم «أشتري لاحقاً» (عبر كل القوائم).
  Widget _buyLaterSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: _buyLater.isNotEmpty,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Text('⏳', style: TextStyle(fontSize: 22)),
        title: Text(tr('أشتري لاحقاً', 'Buy later'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            _buyLater.isEmpty
                ? tr('حاجات تشتريها بعدين', 'things to buy later')
                : tr('${arNum(_buyLater.length)} حاجة', '${arNum(_buyLater.length)} items'),
            style: TextStyle(fontSize: 12, color: scheme.outline)),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          _addRow(null),
          for (final it in _buyLater) _itemTile(context, it, null),
        ],
      ),
    );
  }

  /// صف إضافة داخل قسم — خانة خاصة بالقائمة + تصنيف (للبقالة) + زر.
  Widget _addRow(ShoppingList? list) {
    final key = list?.id ?? _buyLaterKey;
    final usesAisles = list?.usesAisles ?? false;
    _addCat.putIfAbsent(key, () => kShoppingCategories.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrlFor(key),
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                hintText: list == null
                    ? tr('حاجة لاحقاً…', 'Buy later…')
                    : tr('ضيف صنف…', 'Add item…'),
              ),
              onSubmitted: (_) => _addTo(list),
            ),
          ),
          if (usesAisles) ...[
            const SizedBox(width: 4),
            DropdownButton<String>(
              value: _addCat[key],
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [
                for (final c in kShoppingCategories)
                  DropdownMenuItem(
                      value: c,
                      child: Text(shoppingCategoryLabel(c),
                          style: const TextStyle(fontSize: 11))),
              ],
              onChanged: (v) =>
                  setState(() => _addCat[key] = v ?? _addCat[key]!),
            ),
          ],
          const SizedBox(width: 4),
          IconButton.filled(
            visualDensity: VisualDensity.compact,
            onPressed: () => _addTo(list),
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }

  /// أصناف قائمة — متجمّعة بالممرات لو بقالة، وإلا مسطّحة (النشط ثم المتشال).
  List<Widget> _itemWidgets(
      BuildContext context, List<ShoppingItem> items, ShoppingList l) {
    if (items.isEmpty) return const [];
    final active = items.where((i) => !i.checked).toList();
    final done = items.where((i) => i.checked).toList();
    if (!l.usesAisles) {
      return [
        for (final it in active) _itemTile(context, it, l),
        for (final it in done) _itemTile(context, it, l),
      ];
    }
    final scheme = Theme.of(context).colorScheme;
    final byCat = <String, List<ShoppingItem>>{};
    for (final it in active) {
      byCat.putIfAbsent(it.category.isEmpty ? 'أخرى' : it.category, () => [])
          .add(it);
    }
    final order = [
      ..._aisleOrder,
      ...byCat.keys.where((k) => !_aisleOrder.contains(k)),
    ];
    final out = <Widget>[];
    for (final cat in order) {
      final list = byCat[cat];
      if (list == null || list.isEmpty) continue;
      out.add(Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(shoppingCategoryLabel(cat),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.primary)),
      ));
      for (final it in list) {
        out.add(_itemTile(context, it, l));
      }
    }
    for (final it in done) {
      out.add(_itemTile(context, it, l));
    }
    return out;
  }

  String? _subtitleFor(ShoppingItem item) {
    final parts = <String>[
      if (item.qty.isNotEmpty) item.qty,
      if (item.place.isNotEmpty) '📍${item.place}',
      if (item.price > 0) egp(item.price),
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  Widget _itemTile(BuildContext context, ShoppingItem item, ShoppingList? l) {
    final scheme = Theme.of(context).colorScheme;
    return CheckboxListTile(
      value: item.checked,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => _toggleChecked(item, v ?? false, l),
      title: Row(children: [
        if (item.buyLater && item.priority == 1)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 4),
            child: Text('🔴', style: TextStyle(fontSize: 10)),
          ),
        Flexible(
          child: Text(item.name,
              style: item.checked
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: scheme.outline)
                  : null),
        ),
      ]),
      subtitle: _subtitleFor(item) == null ? null : Text(_subtitleFor(item)!),
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _editItem(item),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await _repo.deleteShoppingItem(item.id!);
              await _load();
            },
          ),
        ],
      ),
    );
  }

  // ---- الأساسيات وترتيب الممرات (شيتات مشتركة) ----

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
                      tr('حاجات بتشتريها كل شهر — ضيفها لأى قائمة من زرها ⋮',
                          'Add them to any list from its ⋮ menu'),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx).colorScheme.outline)),
                  const SizedBox(height: 8),
                  ...list.map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
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
                          autocorrect: false,
                          enableSuggestions: false,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

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
              const SizedBox(height: 8),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
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
                  child: Text(tr('الافتراضى', 'Default')),
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
}
