import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/wardrobe_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'clothing_form.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all(category: _filter);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openForm([ClothingItem? it]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ClothingForm(item: it)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _suggestOutfit() async {
    var formality = 'casual';
    Map<String, ClothingItem?> outfit =
        await _repo.suggestOutfit(formality: formality);
    final aiOn = await WardrobeRepo.aiAvailable();
    String? aiText;
    var aiLoading = false;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('إيه ألبس النهارده؟', 'What should I wear today?'),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  tr('حسب طقس النهارده وخزانتك — والأقل لبسًا مؤخرًا',
                      "Based on today's weather, your wardrobe & least-recently-worn"),
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.outline, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final f in kClothingFormality)
                    ChoiceChip(
                      label: Text(clothingFormalityLabel(f)),
                      selected: formality == f,
                      onSelected: (_) async {
                        formality = f;
                        outfit = await _repo.suggestOutfit(formality: f);
                        setSheet(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (outfit.values.every((v) => v == null))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      tr('مفيش قطع كفاية للمناسبة دي — ضيف ملابس الأول',
                          'Not enough items for this — add clothes first')),
                )
              else
                for (final entry in outfit.entries)
                  if (entry.value != null)
                    _outfitRow(ctx, entry.key, entry.value!),
              const SizedBox(height: 12),
              if (outfit.values.any((v) => v != null))
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      for (final it in outfit.values) {
                        if (it != null) await _repo.markWorn(it.id!);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) await _load();
                    },
                    icon: const Icon(Icons.check),
                    label: Text(tr('لبستها ✓', 'Wearing this ✓')),
                  ),
                ),
              if (aiOn) ...[
                const Divider(height: 20),
                if (aiText != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(aiText!,
                        style: TextStyle(
                            color:
                                Theme.of(ctx).colorScheme.onSecondaryContainer,
                            height: 1.5)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: aiLoading
                        ? null
                        : () async {
                            setSheet(() => aiLoading = true);
                            final text =
                                await _repo.geminiOutfit(formality: formality);
                            setSheet(() {
                              aiText = text ??
                                  tr('معرفتش أجيب اقتراح دلوقتي',
                                      "Couldn't get a suggestion now");
                              aiLoading = false;
                            });
                          },
                    icon: aiLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(tr('رأي المساعد الذكي ✨',
                        "Ask the AI stylist ✨")),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _outfitRow(BuildContext ctx, String slot, ClothingItem it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _thumb(it, 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clothingCategoryLabel(slot),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(ctx).colorScheme.outline)),
                Text(it.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: Image.file(File(it.photo),
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
        title: Text(tr('خزانة الملابس', 'Wardrobe')),
        actions: [
          IconButton(
            onPressed: _suggestOutfit,
            tooltip: tr('إيه ألبس؟', 'What to wear?'),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                              'Add & photograph your clothes — the assistant suggests an outfit by the weather'))
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
    return InkWell(
      onTap: () => _openForm(it),
      onLongPress: () async {
        if (!await confirmDelete(context, tr('"${it.name}"', '"${it.name}"'))) {
          return;
        }
        await _repo.delete(it.id!);
        if (mounted) await _load();
      },
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _thumb(it, double.infinity)),
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
}
