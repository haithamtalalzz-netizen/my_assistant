
import 'package:flutter/material.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../core/seed_demo_wardrobe.dart';
import '../../widgets/search_action.dart';
import '../../data/wardrobe_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'clothing_form.dart';
import 'outfit_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final Widget? drawer;

  const WardrobeScreen({super.key, this.drawer});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _repo = WardrobeRepo();
  bool _loading = true;
  List<ClothingItem> _items = [];
  String? _filter;
  bool _laundryMode = false;
  int _laundryCount = 0;

  /// عدد القطع التجريبية الموجودة (بيظهر/بيخفى «امسح الملابس التجريبية»).
  int _demoCount = 0;
  bool _demoBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items =
        _laundryMode ? await _repo.laundry() : await _repo.all(category: _filter);
    final laundryCount = await _repo.laundryCount();
    final demoCount = await demoWardrobeCount();
    if (!mounted) return;
    setState(() {
      _items = items;
      _laundryCount = laundryCount;
      _demoCount = demoCount;
      _loading = false;
    });
  }

  /// ٢١ قطعة بصور مرسومة عشان تجرّب البند كله (فلاتر · ألبس إيه · الغسيل).
  /// بتتشال كلها من نفس القايمة من غير ما تلمس قطعة حقيقية.
  Future<void> _addDemoClothes() async {
    if (_demoBusy) return;
    setState(() => _demoBusy = true);
    try {
      final n = await seedDemoWardrobe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اتضافت ${arNum(n)} قطعة تجريبية بصورها',
              'Added ${arNum(n)} demo items with pictures'))));
    } on Exception catch (e, st) {
      logError('فشل إضافة الملابس التجريبية', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('حصلت مشكلة', 'Something went wrong'))));
      }
    } finally {
      if (mounted) {
        setState(() => _demoBusy = false);
        await _load();
      }
    }
  }

  Future<void> _removeDemoClothes() async {
    if (_demoBusy) return;
    final sure = await confirmAction(
      context,
      title: tr('مسح الملابس التجريبية', 'Remove demo clothes'),
      message: tr(
          'هتتشال ${arNum(_demoCount)} قطعة تجريبية بصورها. ملابسك اللى ضفتها بنفسك مش هتتلمس.',
          '${arNum(_demoCount)} demo items (and their pictures) will be removed. Your own items stay.'),
      confirmLabel: tr('امسح', 'Remove'),
    );
    if (!sure || !mounted) return;
    setState(() => _demoBusy = true);
    try {
      final n = await removeDemoWardrobe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اتشالت ${arNum(n)} قطعة تجريبية',
              'Removed ${arNum(n)} demo items'))));
    } on Exception catch (e, st) {
      logError('فشل مسح الملابس التجريبية', e, st);
    } finally {
      if (mounted) {
        setState(() => _demoBusy = false);
        await _load();
      }
    }
  }

  Future<void> _openForm([ClothingItem? it]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ClothingForm(item: it)));
    if (saved == true && mounted) await _load();
  }

  /// صفحة كاملة بالطقم وصوره الكبيرة (كانت شيت صغير بصور ٤٤ بكسل).
  Future<void> _suggestOutfit() async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const OutfitScreen()));
    if (changed == true && mounted) await _load();
  }

  Widget _thumb(ClothingItem it, double size) {
    if (it.photo.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.checkroom, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AppImage(it.photo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              SizedBox(width: size, height: size, child: const Icon(Icons.checkroom))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('ملابسى', 'My clothes')),
        actions: [
          searchAction(context),
          IconButton(
            onPressed: _suggestOutfit,
            tooltip: tr('إيه ألبس؟', 'What to wear?'),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: tr('سلة الغسيل', 'Laundry'),
            onPressed: () {
              setState(() => _laundryMode = !_laundryMode);
              _load();
            },
            icon: Badge(
              isLabelVisible: _laundryCount > 0,
              label: Text(arNum(_laundryCount)),
              child: Icon(_laundryMode
                  ? Icons.local_laundry_service
                  : Icons.local_laundry_service_outlined),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: tr('المزيد', 'More'),
            enabled: !_demoBusy,
            onSelected: (v) => switch (v) {
              'demo_add' => _addDemoClothes(),
              'demo_remove' => _removeDemoClothes(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'demo_add',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science_outlined),
                  title: Text(tr('ضيف ملابس تجريبية', 'Add demo clothes')),
                  subtitle: Text(
                      tr('٢١ قطعة بصور — لتجربة البند', '21 items with pictures — to try the section'),
                      style: const TextStyle(fontSize: 11)),
                ),
              ),
              if (_demoCount > 0)
                PopupMenuItem(
                  value: 'demo_remove',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_sweep_outlined,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(tr('امسح الملابس التجريبية (${arNum(_demoCount)})',
                        'Remove demo clothes (${arNum(_demoCount)})')),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_laundryMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              tr('سلة الغسيل — ${arNum(_laundryCount)} قطعة',
                                  'Laundry — ${arNum(_laundryCount)} items'),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (_laundryCount > 0)
                          TextButton.icon(
                            icon: const Icon(Icons.done_all, size: 18),
                            label: Text(tr('غسلت الكل', 'Washed all')),
                            onPressed: () async {
                              await _repo.washAll();
                              await _load();
                            },
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                        for (final c in kClothingCategories)
                          ChoiceChip(
                            label: Text(clothingCategoryLabel(c)),
                            selected: _filter == c,
                            onSelected: (_) {
                              setState(() => _filter = c);
                              _load();
                            },
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyHint(
                          icon: Icons.checkroom,
                          text: tr(
                              'ضيف ملابسك وصوّرها — والمساعد يقترحلك تلبيسة حسب الطقس',
                              'Add & photograph your clothes — the assistant suggests an outfit by the weather'),
                          // فى وضع الغسيل/الفلتر الفاضى مش هنعرض الزر — بس لما
                          // الخزانة كلها فاضية فعلاً.
                          actionLabel: (_filter == null && !_laundryMode && !_demoBusy)
                              ? tr('🧪 جرّب بملابس تجريبية', '🧪 Try with demo clothes')
                              : null,
                          onAction: _addDemoClothes)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, i) => _card(_items[i]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wardrobe_fab',
        onPressed: () => _openForm(),
        tooltip: tr('ضيف قطعة', 'Add item'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card(ClothingItem it) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openForm(it),
      onLongPress: () => _cardMenu(it),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _thumb(it, double.infinity)),
                if (it.needsWash)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: scheme.primary, shape: BoxShape.circle),
                      child: Icon(Icons.local_laundry_service,
                          size: 13, color: scheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(it.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _cardMenu(ClothingItem it) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(it.needsWash
                  ? Icons.check_circle_outline
                  : Icons.local_laundry_service_outlined),
              title: Text(it.needsWash
                  ? tr('غسلتها (شيلها من السلة)', 'Washed (remove from basket)')
                  : tr('علّمها للغسيل', 'Mark for laundry')),
              onTap: () async {
                Navigator.pop(ctx);
                await _repo.setNeedsWash(it.id!, !it.needsWash);
                await _load();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(tr('حذف', 'Delete')),
              onTap: () async {
                Navigator.pop(ctx);
                if (!await confirmDelete(
                    context, tr('"${it.name}"', '"${it.name}"'))) {
                  return;
                }
                await _repo.delete(it.id!);
                if (mounted) await _load();
              },
            ),
          ],
        ),
      ),
    );
  }
}
