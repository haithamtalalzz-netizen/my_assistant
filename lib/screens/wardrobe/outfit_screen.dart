import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/app_images.dart';
import '../../core/l10n.dart';
import '../../data/settings_repo.dart';
import '../../data/wardrobe_repo.dart';
import '../../models/models.dart';

/// «ألبس إيه النهارده؟» — صفحة كاملة بتعرض **الطقم كله بصوره الكبيرة**،
/// قطعة لكل فئة من الملابس.
///
/// كانت شيت صغير بصور ٤٤ بكسل؛ الطقم حاجة بصرية بطبعه — لازم تشوف
/// القطع مع بعض بحجم يخلّيك تحكم عليها.
class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  final _repo = WardrobeRepo();
  String _formality = 'casual';
  Map<String, ClothingItem?> _outfit = {};
  bool _loading = true;
  bool _aiOn = false;
  String? _aiText;
  bool _aiLoading = false;

  /// اتغيّرت حاجة (لبس طقم) → الشاشة اللى ورا محتاجة تعيد التحميل.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final outfit = await _repo.suggestOutfit(formality: _formality);
    final aiOn = await WardrobeRepo.aiAvailable();
    if (!mounted) return;
    setState(() {
      _outfit = outfit;
      _aiOn = aiOn;
      _loading = false;
    });
  }

  Future<void> _setFormality(String f) async {
    setState(() {
      _formality = f;
      _loading = true;
      _aiText = null;
    });
    await _load();
  }

  Future<void> _wearIt() async {
    for (final it in _outfit.values) {
      if (it != null) await _repo.markWorn(it.id!);
    }
    _changed = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('تمام، لبستها ✓', 'Nice — marked as worn ✓'))));
    // بعد ما اتلبست، «الأقل لبسًا» اتغيّر — نجيب اقتراح جديد.
    await _load();
  }

  Future<void> _askAi() async {
    setState(() => _aiLoading = true);
    final text = await _repo.geminiOutfit(formality: _formality);
    if (!mounted) return;
    setState(() {
      _aiText = text ??
          tr('معرفتش أجيب اقتراح دلوقتي', "Couldn't get a suggestion now");
      _aiLoading = false;
    });
  }

  // ---- الإطلالات المحفوظة (تخزين JSON فى الإعدادات، بلا هجرة) ----
  static const _kSaved = 'wardrobe_saved_outfits';

  Future<List<Map<String, dynamic>>> _readSaved() async {
    final raw = await SettingsRepo().get(_kSaved) ?? '';
    if (raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } on FormatException {
      return [];
    }
  }

  Future<void> _saveOutfit() async {
    final picked =
        _outfit.values.whereType<ClothingItem>().toList();
    if (picked.isEmpty) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('احفظ الإطلالة', 'Save this look')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              hintText: tr('اسم الإطلالة (شغل، مناسبة…)',
                  'Look name (work, event…)')),
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
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return;
    final list = await _readSaved();
    list.add({
      'name': name.isEmpty
          ? clothingFormalityLabel(_formality)
          : name,
      'formality': _formality,
      'items': [
        for (final it in picked) {'id': it.id, 'name': it.name},
      ],
    });
    await SettingsRepo().set(_kSaved, jsonEncode(list));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتحفظت الإطلالة 🔖', 'Look saved 🔖'))));
  }

  Future<void> _openSaved() async {
    final list = await _readSaved();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                children: [
                  Text(tr('إطلالاتى المحفوظة', 'My saved looks'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                          tr('مفيش إطلالات محفوظة. اعمل طقم واضغط 🔖 حفظ.',
                              'No saved looks yet. Build one and tap 🔖 Save.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  for (var i = 0; i < list.length; i++)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.checkroom),
                        title: Text(list[i]['name']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text([
                          for (final it in (list[i]['items'] as List))
                            (it as Map)['name']?.toString() ?? ''
                        ].where((s) => s.isNotEmpty).join(' · ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: tr('لبستها', 'Wear it'),
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () async {
                                for (final it
                                    in (list[i]['items'] as List)) {
                                  final id = (it as Map)['id'];
                                  if (id is int) await _repo.markWorn(id);
                                }
                                _changed = true;
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(tr('لبستها ✓',
                                              'Marked as worn ✓'))));
                                }
                              },
                            ),
                            IconButton(
                              tooltip: tr('حذف', 'Delete'),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                list.removeAt(i);
                                await SettingsRepo()
                                    .set(_kSaved, jsonEncode(list));
                                setSheet(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = _outfit.entries.where((e) => e.value != null).toList();
    final missing = _outfit.entries.where((e) => e.value == null).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('ألبس إيه النهارده؟', 'What to wear today?')),
          actions: [
            IconButton(
              tooltip: tr('إطلالاتى المحفوظة', 'Saved looks'),
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: _openSaved,
            ),
            IconButton(
              tooltip: tr('اقترح غيره', 'Suggest another'),
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    tr('حسب طقس النهارده وخزانتك — والأقل لبسًا مؤخرًا',
                        "Based on today's weather, your wardrobe & least-recently-worn"),
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in kClothingFormality)
                        ChoiceChip(
                          label: Text(clothingFormalityLabel(f)),
                          selected: _formality == f,
                          onSelected: (_) => _setFormality(f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (picked.isEmpty)
                    _emptyState(context)
                  else ...[
                    // الطقم — بلاطتين فى الصف بصور كبيرة.
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: picked.length,
                      itemBuilder: (_, i) =>
                          _pieceCard(context, picked[i].key, picked[i].value!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _wearIt,
                              icon: const Icon(Icons.check),
                              label: Text(tr('لبستها ✓', 'Wearing this ✓')),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _saveOutfit,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: Text(tr('احفظ', 'Save')),
                          ),
                        ),
                      ],
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // شفافية: الفئة اللى ملقيناش ليها قطعة مناسبة.
                      Text(
                        tr(
                            'مفيش قطعة مناسبة فى: ${missing.map((e) => clothingCategoryLabel(e.key)).join(' · ')}',
                            'Nothing suitable in: ${missing.map((e) => clothingCategoryLabel(e.key)).join(' · ')}'),
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                  if (_aiOn) ...[
                    const Divider(height: 32),
                    if (_aiText != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_aiText!,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                height: 1.5)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _aiLoading ? null : _askAi,
                        icon: _aiLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                            tr('رأى المساعد الذكى ✨', 'Ask the AI stylist ✨')),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// قطعة واحدة من الطقم — صورة كبيرة + الفئة + الاسم واللون.
  Widget _pieceCard(BuildContext context, String slot, ClothingItem it) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: it.photo.isEmpty
                // مفيش صورة — أيقونة كبيرة على خلفية هادية بدل مربع فاضى.
                ? Container(
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(Icons.checkroom,
                        size: 52, color: scheme.outline),
                  )
                : AppImage(
                    it.photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.checkroom,
                          size: 52, color: scheme.outline),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clothingCategoryLabel(slot),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
                const SizedBox(height: 2),
                Text(it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                if (it.color.trim().isNotEmpty)
                  Text(it.color,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('👕', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              tr('مفيش قطع كفاية للمناسبة دى — ضيف ملابس الأول',
                  'Not enough items for this — add clothes first'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
}
