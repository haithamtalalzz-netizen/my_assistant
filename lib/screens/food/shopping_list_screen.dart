import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../widgets/search_action.dart';
import '../../data/meals_repo.dart';
import '../../data/money_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// قائمة تسوق: قائمة واحدة موحّدة بكل الأصناف + شريط فلتر فوق (الكل /
/// كل قائمة / أشتري لاحقاً) — كل صنف قدامه إيموجى قائمته.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

const int _kAll = -2; // فلتر «الكل»
const int _kBuyLater = -1; // فلتر «أشتري لاحقاً»

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _repo = MealsRepo();
  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  bool _loading = true;
  List<ShoppingList> _lists = [];

  /// كل الأصناف النشطة (مش المؤجّلة) + المؤجّلة على حدة.
  List<ShoppingItem> _active = [];
  List<ShoppingItem> _buyLater = [];

  /// الفلتر الحالى: _kAll / _kBuyLater / id قائمة.
  int _filter = _kAll;

  /// لما الفلتر «الكل» — القائمة اللى الإضافة بتروحلها.
  int? _addTarget;

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

  ShoppingList? _listById(int? id) {
    for (final l in _lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final lists = await _repo.shoppingLists();
      final active = await _repo.shoppingItems();
      final buyLater = await _repo.buyLaterItems();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _active = active;
        _buyLater = buyLater;
        _addTarget ??= lists.isEmpty ? null : lists.first.id;
        if (_addTarget != null && !lists.any((l) => l.id == _addTarget)) {
          _addTarget = lists.isEmpty ? null : lists.first.id;
        }
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

  /// الأصناف اللى تظهر حسب الفلتر (النشط الأول ثم المتشال).
  List<ShoppingItem> get _shown {
    final List<ShoppingItem> src;
    if (_filter == _kBuyLater) {
      src = _buyLater;
    } else if (_filter == _kAll) {
      src = _active;
    } else {
      src = [for (final i in _active) if (i.listId == _filter) i];
    }
    final list = [...src];
    list.sort((a, b) {
      if (a.checked != b.checked) return a.checked ? 1 : 0 - (b.checked ? 1 : 0);
      return 0;
    });
    return list;
  }

  double get _shownTotal =>
      _shown.where((i) => !i.checked).fold(0, (s, i) => s + i.price);

  // ---- إضافة ----

  /// القائمة اللى الإضافة بتروحلها حسب الفلتر.
  ShoppingList? get _targetList {
    if (_filter == _kBuyLater) return null;
    if (_filter == _kAll) return _listById(_addTarget);
    return _listById(_filter);
  }

  Future<void> _add() async {
    final name = _input.text.trim();
    if (name.isEmpty) {
      _inputFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(tr('اكتب اسم الصنف الأول', 'Type an item name first'))));
      return;
    }
    final buyLater = _filter == _kBuyLater;
    final list = _targetList;
    if (!buyLater && list == null) {
      // مفيش قوائم لسه — نوجّه لإنشاء واحدة.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اعمل قائمة الأول', 'Create a list first'))));
      return;
    }
    await _repo.addShoppingItem(name,
        listId: list?.id, buyLater: buyLater);
    _input.clear();
    await _load();
    if (mounted) _inputFocus.requestFocus();
  }

  Future<void> _toggleChecked(ShoppingItem item, bool checked) async {
    HapticFeedback.selectionClick();
    await _repo.setChecked(item.id!, checked);
    if (checked && item.price > 0 && mounted) {
      final log = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('تسجيل مصروف؟', 'Log expense?')),
          content: Text(tr('تحب أسجّل «${item.name}» بـ${egp(item.price)}؟',
              'Log "${item.name}" for ${egp(item.price)}?')),
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
          category: expenseCategoryForList(_listById(item.listId)?.name ?? ''),
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

  Future<void> _editItem(ShoppingItem item) async {
    final name = TextEditingController(text: item.name);
    final qty = TextEditingController(text: item.qty);
    final place = TextEditingController(text: item.place);
    final price = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(0) : '');
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

  Future<void> _manageLists() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('قوائم التسوق', 'Shopping lists'),
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final l in _lists)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(l.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(l.name),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: tr('قالب جاهز', 'Template'),
                      icon: const Icon(Icons.playlist_add, size: 18),
                      onPressed: () => _useTemplate(l),
                    ),
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
                        if (_filter == l.id) _filter = _kAll;
                        setSheet(() {});
                        if (mounted) await _load();
                      },
                    ),
                  ]),
                ),
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
        _filter = id;
        _addTarget = id;
      } else {
        await _repo.renameShoppingList(existing.id!,
            name: name.text.trim(), emoji: emoji);
      }
      if (mounted) await _load();
    }
    name.dispose();
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
              child: Text(
                  tr('قوالب → ${list.name}', 'Templates → ${list.name}'),
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
            final target = _targetList;
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
                  if (target != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.playlist_add_check),
                        label: Text(tr('ضيفهم لـ${target.name}',
                            'Add to ${target.name}')),
                        onPressed: () async {
                          final n =
                              await _repo.addStaplesToList(listId: target.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(tr('اتضاف ${arNum(n)} صنف',
                                          '${arNum(n)} items added'))));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---- البناء ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('قائمة التسوق', 'Shopping list')),
        actions: [
          searchAction(context),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'lists') _manageLists();
              if (v == 'staples') _manageStaples();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'lists',
                  child: Text(tr('🗂 إدارة القوائم', '🗂 Manage lists'))),
              PopupMenuItem(
                  value: 'staples',
                  child: Text(tr('🔁 الأساسيات', '🔁 Staples'))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filterBar(context),
                _addRow(context),
                Expanded(child: _itemsList(context)),
              ],
            ),
    );
  }

  Widget _filterBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // عدّاد الباقى لكل قائمة.
    int remainingFor(int id) =>
        _active.where((i) => i.listId == id && !i.checked).length;
    Widget chip(String label, int value, {int? badge}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ChoiceChip(
            label: Text(badge != null && badge > 0
                ? '$label (${arNum(badge)})'
                : label),
            selected: _filter == value,
            onSelected: (_) => setState(() => _filter = value),
          ),
        );
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          chip(tr('الكل', 'All'), _kAll,
              badge: _active.where((i) => !i.checked).length),
          for (final l in _lists)
            chip('${l.emoji} ${l.name}', l.id!, badge: remainingFor(l.id!)),
          chip(tr('⏳ لاحقاً', '⏳ Later'), _kBuyLater,
              badge: _buyLater.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: ActionChip(
              avatar: Icon(Icons.add, size: 16, color: scheme.primary),
              label: Text(tr('قائمة', 'List')),
              onPressed: () => _listForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addRow(BuildContext context) {
    final buyLater = _filter == _kBuyLater;
    final showListPicker = _filter == _kAll && _lists.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              focusNode: _inputFocus,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                hintText: buyLater
                    ? tr('حاجة أشتريها لاحقاً…', 'Buy later…')
                    : tr('ضيف صنف…', 'Add item…'),
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          // لما «الكل» — اختار القائمة اللى الإضافة تروحلها.
          if (showListPicker) ...[
            const SizedBox(width: 4),
            DropdownButton<int>(
              value: _addTarget,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [
                for (final l in _lists)
                  DropdownMenuItem(
                      value: l.id,
                      child: Text(l.emoji, style: const TextStyle(fontSize: 18))),
              ],
              onChanged: (v) => setState(() => _addTarget = v),
            ),
          ],
          const SizedBox(width: 4),
          IconButton.filled(
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _itemsList(BuildContext context) {
    final items = _shown;
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return _lists.isEmpty && _filter != _kBuyLater
          ? EmptyHint(
              icon: Icons.list_alt,
              actionLabel: tr('قائمة جديدة', 'New list'),
              onAction: () => _listForm(),
              text: tr('اعمل قائمة الأول (سوبرماركت/صيدلية...)',
                  'Create a list first'))
          : EmptyHint(
              icon: Icons.shopping_cart_outlined,
              text: _filter == _kBuyLater
                  ? tr('مفيش حاجة مؤجّلة', 'Nothing on your later list')
                  : tr('القائمة فاضية — ضيف أول صنف', 'Empty — add the first item'));
    }
    final done = items.where((i) => i.checked).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        if (_shownTotal > 0 || items.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(children: [
              Expanded(
                child: Text(
                    tr('${arNum(done)} من ${arNum(items.length)} اتشالت',
                        '${arNum(done)} of ${arNum(items.length)} done'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
              ),
              if (_shownTotal > 0)
                Text(tr('التقدير: ${egp(_shownTotal)}',
                    'Est: ${egp(_shownTotal)}'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
            ]),
          ),
        for (final it in items) _itemTile(context, it),
      ],
    );
  }

  String? _subtitleFor(ShoppingItem item) {
    final parts = <String>[
      if (item.qty.isNotEmpty) item.qty,
      if (item.place.isNotEmpty) '📍${item.place}',
      if (item.price > 0) egp(item.price),
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  Widget _itemTile(BuildContext context, ShoppingItem item) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = _listById(item.listId)?.emoji;
    return CheckboxListTile(
      value: item.checked,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => _toggleChecked(item, v ?? false),
      title: Row(children: [
        if (item.buyLater && item.priority == 1)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 3),
            child: Text('🔴', style: TextStyle(fontSize: 10)),
          ),
        // إيموجى القائمة قدام الصنف (يوضّح تابع لأنهى قائمة).
        if (emoji != null && (_filter == _kAll || _filter == _kBuyLater))
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
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
}
