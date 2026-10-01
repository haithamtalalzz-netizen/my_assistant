
import 'package:flutter/material.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../core/seed_demo_wardrobe.dart';
import '../../widgets/search_action.dart';
import '../../data/wardrobe_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import 'clothing_form.dart';
import 'outfit_screen.dart';
import '../../core/privacy.dart';

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
    // الزرار بيضيف من غير ما يمسح، فدوستين بيبقوا ٤٢ قطعة مكرّرة — ده حصل
    // فعلاً. لو فيه تجريبية موجودة بنسأل الأول.
    if (_demoCount > 0) {
      final again = await confirmAction(
        context,
        title: tr('ملابس تجريبية موجودة', 'Demo clothes already added'),
        message: tr(
            'عندك ${arNum(_demoCount)} قطعة تجريبية بالفعل. هشيلهم وأضيف طقم جديد بدل ما يتكرروا.',
            'You already have ${arNum(_demoCount)} demo items. They will be replaced, not duplicated.'),
        confirmLabel: tr('استبدال', 'Replace'),
      );
      if (!again || !mounted) return;
      setState(() => _demoBusy = true);
      await removeDemoWardrobe();
      if (!mounted) return;
      setState(() => _demoBusy = false);
    }
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

  /// **البطل** — «ألبس إيه النهارده؟» + سلة الغسيل.
  Widget _hero() => AppHero(
        icon: Icons.auto_awesome,
        kicker: _laundryCount > 0
            ? tr('${arNum(_laundryCount)} قطعة محتاجة غسيل',
                '${arNum(_laundryCount)} items need washing')
            : tr('خزانتك', 'Your wardrobe'),
        title: tr('ألبس إيه النهارده؟', 'What to wear today?'),
        primaryLabel: tr('اقترحلى طقم', 'Suggest an outfit'),
        primaryIcon: Icons.auto_awesome,
        onPrimary: _suggestOutfit,
        secondaryLabel: _laundryMode
            ? tr('كل الخزانة', 'All clothes')
            : tr('سلة الغسيل ${arNum(_laundryCount)}',
                'Laundry ${arNum(_laundryCount)}'),
        onSecondary: () {
          setState(() => _laundryMode = !_laundryMode);
          _load();
        },
        colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      );

  Widget _filterChip(String label, String? value) {
    final scheme = Theme.of(context).colorScheme;
    final on = _filter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _filter = value);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? scheme.primary : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: on ? scheme.primary : scheme.outlineVariant),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? scheme.onPrimary : scheme.onSurface)),
        ),
      ),
    );
  }

  /// لون وأيقونة حسب خانة اللبس — عشان القطعة اللى من غير صورة تبقى
  /// مربّع ملوّن تعرفه من شكله، مش مساحة بيضا فاضية.
  (Color, IconData) _kindStyle(String category) => switch (category) {
        'top' => (const Color(0xFF3B82F6), Icons.checkroom),
        'bottom' => (const Color(0xFF14B8A6), Icons.dry_cleaning),
        'outer' => (const Color(0xFF8B5CF6), Icons.ac_unit),
        'shoes' => (const Color(0xFFF59E0B), Icons.ice_skating),
        _ => (const Color(0xFFEC4899), Icons.watch),
      };

  Widget _placeholder(ClothingItem it, double size) {
    final (c, icon) = _kindStyle(it.category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 30, color: c),
    );
  }

  Widget _thumb(ClothingItem it, double size) {
    if (it.photo.isEmpty) return _placeholder(it, size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AppImage(it.photo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // الصورة اللى اتمسحت من برّه التطبيق كانت بتسيب فراغ أبيض.
          errorBuilder: (_, _, _) => _placeholder(it, size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('ملابسى', 'My clothes')),
        actions: [
          const PrivacyAction(),
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
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                AppPad(_hero(), top: 12, bottom: 18),
                if (_laundryMode)
                  AppPad(
                    Row(children: [
                      Expanded(
                        child: Text(
                            tr('سلة الغسيل — ${arNum(_laundryCount)} قطعة',
                                'Laundry — ${arNum(_laundryCount)} items'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
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
                    ]),
                    bottom: 8,
                  )
                else
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      children: [
                        _filterChip(tr('الكل', 'All'), null),
                        for (final c in kClothingCategories)
                          _filterChip(clothingCategoryLabel(c), c),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: EmptyHint(
                      icon: Icons.checkroom,
                      text: tr(
                          'ضيف ملابسك وصوّرها — والمساعد يقترحلك تلبيسة حسب الطقس',
                          'Add & photograph your clothes — the assistant suggests an outfit by the weather'),
                      actionLabel: (_filter == null && !_laundryMode && !_demoBusy)
                          ? tr('🧪 جرّب بملابس تجريبية', '🧪 Try with demo clothes')
                          : null,
                      onAction: _addDemoClothes,
                    ),
                  )
                else ...[
                  AppPad(AppSectionTitle(
                      _laundryMode
                          ? tr('محتاجة غسيل', 'Needs washing')
                          : tr('خزانتك', 'Your wardrobe'),
                      trailing: tr('${arNum(_items.length)} قطعة',
                          '${arNum(_items.length)} items'))),
                  AppPad(
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 146,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _card(_items[i]),
                    ),
                  ),
                ],
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
