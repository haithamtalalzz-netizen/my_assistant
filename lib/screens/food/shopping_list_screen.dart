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

/// قائمة تسوق شاملة: قوائم متعددة (سوبرماركت/صيدلية/ملابس...) + كمية ومكان
/// وأولوية لكل صنف + «أشتري لاحقاً» + قوالب جاهزة + ربط بالميزانية.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _repo = MealsRepo();
  final _settings = SettingsRepo();
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  bool _loading = true;
  List<ShoppingList> _lists = [];

  /// null = تبويب «أشتري لاحقاً»؛ غير كده id القائمة النشطة.
  int? _activeListId;
  bool _buyLaterTab = false;

  List<ShoppingItem> _items = [];
  String _addCat = kShoppingCategories.first;
  double _total = 0;
  List<String> _aisleOrder = kShoppingCategories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  ShoppingList? get _activeList {
    for (final l in _lists) {
      if (l.id == _activeListId) return l;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final lists = await _repo.shoppingLists();
      // أول تحميل: اختار أول قائمة.
      if (_activeListId == null && !_buyLaterTab && lists.isNotEmpty) {
        _activeListId = lists.first.id;
      }
      // لو القائمة النشطة اتمسحت.
      if (!_buyLaterTab &&
          _activeListId != null &&
          !lists.any((l) => l.id == _activeListId)) {
        _activeListId = lists.isEmpty ? null : lists.first.id;
      }
      final items = _buyLaterTab
          ? await _repo.buyLaterItems()
          : await _repo.shoppingItems(listId: _activeListId);
      logInfo('تسوق: _load قائمة=$_activeListId لاحقاً=$_buyLaterTab '
          'قوائم=${lists.length} → ${items.length} صنف');
      final total =
          _buyLaterTab ? 0.0 : await _repo.shoppingTotal(listId: _activeListId);
      final order = orderedShoppingCategories(
          await _settings.cardOrder('shopping_aisles'));
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _items = items;
        _total = total;
        _aisleOrder = order;
        _loading = false;
      });
    } on Exception catch (e, st) {
      // مايتركش الشاشة معلّقة على لودينج لو استعلام فشل — بيتسجّل ويظهر تنبيه.
      logError('فشل تحميل قائمة التسوق', e, st);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('حصلت مشكلة فى تحميل القائمة — جرّب تقفل وتفتح',
              'Problem loading the list — try reopening'))));
    }
  }

  void _selectList(int? id, {bool buyLater = false}) {
    logInfo('تسوق: _selectList id=$id لاحقاً=$buyLater');
    setState(() {
      _buyLaterTab = buyLater;
      _activeListId = id;
      _loading = true;
    });
    _load();
  }

  Future<void> _add() async {
    final name = _input.text.trim();
    logInfo('تسوق: _add النص="$name" قائمة=$_activeListId لاحقاً=$_buyLaterTab');
    if (name.isEmpty) {
      // بدل ما الزرار يعمل حاجة صامتة (فيبان مش شغّال) — نوجّه المستخدم
      // ونرجّع التركيز للخانة عشان يكتب.
      _inputFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(tr('اكتب اسم الصنف فى الخانة الأول',
              'Type an item name in the field first'))));
      return;
    }
    await _repo.addShoppingItem(name,
        category: _addCat, listId: _activeListId, buyLater: _buyLaterTab);
    _input.clear();
    await _load();
    // نسيب التركيز فى الخانة عشان تكتب الصنف اللى بعده على طول.
    if (mounted) _inputFocus.requestFocus();
  }

  /// تعديل/إضافة صنف بكل الحقول (اسم/كمية/تصنيف/مكان/سعر/أولوية/لاحقاً/قائمة).
  Future<void> _editItem(ShoppingItem item) async {
    final name = TextEditingController(text: item.name);
    final qty = TextEditingController(text: item.qty);
    final place = TextEditingController(text: item.place);
    final price = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(0) : '');
    var cat = item.category.isEmpty ? kShoppingCategories.first : item.category;
    var listId = item.listId ?? _activeListId;
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
              if (_lists.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: listId,
                  decoration:
                      InputDecoration(labelText: tr('القائمة', 'List')),
                  items: [
                    for (final l in _lists)
                      DropdownMenuItem(
                          value: l.id, child: Text('${l.emoji} ${l.name}')),
                  ],
                  onChanged: (v) => listId = v ?? listId,
                ),
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

  /// تشييل صنف — ولو ليه سعر يسأل يسجّله مصروف (ربط الميزانية).
  Future<void> _toggleChecked(ShoppingItem item, bool checked) async {
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
        final listName = _activeList?.name ?? '';
        await MoneyRepo().add(Expense(
          amount: item.price,
          category: expenseCategoryForList(listName),
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

  // ---- إدارة القوائم ----

  Future<void> _manageLists() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => FutureBuilder<List<ShoppingList>>(
          future: _repo.shoppingLists(),
          builder: (_, snap) {
            final lists = snap.data ?? _lists;
            return Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('قوائم التسوق', 'Shopping lists'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...lists.map((l) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(l.emoji,
                            style: const TextStyle(fontSize: 20)),
                        title: Text(l.name),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () async {
                              await _listForm(existing: l);
                              setSheet(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () async {
                              if (!await confirmDelete(ctx,
                                  tr('قائمة «${l.name}» وكل بنودها',
                                      '"${l.name}" and its items'))) {
                                return;
                              }
                              await _repo.deleteShoppingList(l.id!);
                              if (_activeListId == l.id) _activeListId = null;
                              setSheet(() {});
                              if (mounted) await _load();
                            },
                          ),
                        ]),
                      )),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(tr('قائمة جديدة', 'New list')),
                    onPressed: () async {
                      await _listForm();
                      setSheet(() {});
                      if (mounted) await _load();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _listForm({ShoppingList? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var emoji = existing?.emoji ?? '🛒';
    const emojis = ['🛒', '💊', '👕', '🔧', '📱', '🎁', '👶', '💼', '🏠', '🎨'];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existing == null
              ? tr('قائمة جديدة', 'New list')
              : tr('تعديل القائمة', 'Edit list')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  autofocus: true,
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
        final id =
            await _repo.addShoppingList(name.text.trim(), emoji: emoji);
        _activeListId = id;
        _buyLaterTab = false;
      } else {
        await _repo.renameShoppingList(existing.id!,
            name: name.text.trim(), emoji: emoji);
      }
    }
    name.dispose();
  }

  /// قوالب جاهزة → تضيف مجموعة أصناف للقائمة النشطة بضغطة.
  Future<void> _useTemplate() async {
    logInfo('تسوق: _useTemplate قائمة=$_activeListId');
    if (_activeListId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(tr('قوالب جاهزة', 'Templates'),
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
                      listId: _activeListId);
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
                      tr('حاجات بتشتريها كل شهر — أضفها للقائمة الحالية بضغطة',
                          'Things you buy monthly — add to the current list'),
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
                      label: Text(
                          tr('أضف الأساسيات للقائمة', 'Add staples to list')),
                      onPressed: () async {
                        final n =
                            await _repo.addStaplesToList(listId: _activeListId);
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

  /// شريط تبويبات القوائم (+ «أشتري لاحقاً» + زر إدارة).
  Widget _listTabs() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final l in _lists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: ChoiceChip(
                label: Text('${l.emoji} ${l.name}'),
                selected: !_buyLaterTab && _activeListId == l.id,
                onSelected: (_) => _selectList(l.id),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: ChoiceChip(
              label: Text(tr('⏳ أشتري لاحقاً', '⏳ Buy later')),
              selected: _buyLaterTab,
              onSelected: (_) => _selectList(null, buyLater: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
            child: ActionChip(
              avatar: Icon(Icons.tune, size: 16, color: scheme.primary),
              label: Text(tr('القوائم', 'Lists')),
              onPressed: _manageLists,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _groupedList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // «أشتري لاحقاً»: قائمة مسطّحة بالأولوية، من غير تجميع بالتصنيف.
    if (_buyLaterTab) {
      return [for (final it in _items) _itemTile(it, scheme)];
    }
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

  /// سطر تحت العنوان: الكمية + المكان + الأولوية.
  String? _subtitleFor(ShoppingItem item) {
    final parts = <String>[
      if (item.qty.isNotEmpty) item.qty,
      if (item.place.isNotEmpty) '📍${item.place}',
      if (item.price > 0) egp(item.price),
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  Widget _itemTile(ShoppingItem item, ColorScheme scheme) => CheckboxListTile(
        value: item.checked,
        dense: true,
        onChanged: (v) => _toggleChecked(item, v ?? false),
        title: Row(children: [
          if (_buyLaterTab && item.priority == 1)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 4),
              child: Text('🔴', style: TextStyle(fontSize: 11)),
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('قائمة التسوق', 'Shopping list')),
        actions: [
          searchAction(context),
          if (!_buyLaterTab) ...[
            PopupMenuButton<String>(
              tooltip: tr('المزيد', 'More'),
              onSelected: (v) {
                logInfo('تسوق: المزيد اختار=$v');
                switch (v) {
                  case 'templates':
                    _useTemplate();
                  case 'staples':
                    _manageStaples();
                  case 'aisles':
                    _editAisleOrder();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'templates',
                    child: Text(tr('📋 قوالب جاهزة', '📋 Templates'))),
                PopupMenuItem(
                    value: 'staples',
                    child: Text(tr('🔁 الأساسيات', '🔁 Staples'))),
                PopupMenuItem(
                    value: 'aisles',
                    child: Text(tr('⇅ ترتيب الممرات', '⇅ Aisle order'))),
              ],
            ),
          ],
          if (checkedCount > 0 && !_buyLaterTab)
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
                _listTabs(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _inputFocus,
                          // إيقاف الاقتراحات/التصحيح بيمنع «النص المعلّق» فى
                          // كيبورد سامسونج/العربى اللى كان بيخلّى الخانة تتقرا
                          // فاضية وقت الضغط على «+».
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                              labelText: _buyLaterTab
                                  ? tr('حاجة أشتريها لاحقاً',
                                      'Something to buy later')
                                  : tr('ضيف صنف (مثلًا: رز، زيت...)',
                                      'Add item (e.g. rice, oil...)')),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      if (!_buyLaterTab) ...[
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
                      ],
                      const SizedBox(width: 6),
                      IconButton.filled(
                          onPressed: _lists.isEmpty && !_buyLaterTab
                              ? null
                              : _add,
                          icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                if (_items.isNotEmpty && !_buyLaterTab)
                  _progressHeader(context, checkedCount),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyHint(
                          icon: Icons.shopping_cart_outlined,
                          text: _buyLaterTab
                              ? tr('مفيش حاجة مؤجّلة — أى حاجة نفسك تشتريها بعدين ضيفها هنا',
                                  'Nothing on your buy-later list yet')
                              : _lists.isEmpty
                                  ? tr('اعمل قائمة الأول من زر «القوائم»',
                                      'Create a list first via "Lists"')
                                  : tr('القائمة فاضية — ضيف أول صنف',
                                      'List is empty — add the first item'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: _groupedList(context),
                        ),
                ),
              ],
            ),
      floatingActionButton: _lists.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                await _listForm();
                await _load();
              },
              icon: const Icon(Icons.add),
              label: Text(tr('قائمة جديدة', 'New list')),
              backgroundColor: scheme.primaryContainer,
            )
          : null,
    );
  }
}
