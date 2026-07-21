
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_images.dart';

import '../../core/l10n.dart';
import '../../data/wardrobe_repo.dart';
import '../../models/models.dart';

class ClothingForm extends StatefulWidget {
  final ClothingItem? item;

  const ClothingForm({super.key, this.item});

  @override
  State<ClothingForm> createState() => _ClothingFormState();
}

class _ClothingFormState extends State<ClothingForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _color = TextEditingController();
  String _category = kClothingCategories.first;
  String _season = 'all';
  String _formality = 'casual';
  String _photo = '';
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    if (it != null) {
      _name.text = it.name;
      _color.text = it.color;
      _category = it.category;
      _season = it.season;
      _formality = it.formality;
      _photo = it.photo;
      _favorite = it.favorite;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final stored = await AppImages.pickAndStore(source,
        maxWidth: 1600, namePrefix: 'cloth');
    if (stored == null) return;
    if (mounted) setState(() => _photo = stored);
  }

  Future<void> _photoSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(tr('الكاميرا', 'Camera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(tr('من الصور', 'From gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await WardrobeRepo().save(ClothingItem(
      id: widget.item?.id,
      name: _name.text.trim(),
      category: _category,
      color: _color.text.trim(),
      season: _season,
      formality: _formality,
      photo: _photo,
      lastWorn: widget.item?.lastWorn,
      favorite: _favorite,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.item == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('قطعة ملابس جديدة', 'New clothing item')
              : tr('تعديل القطعة', 'Edit item'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _photoSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photo.isEmpty
                    ? Center(
                        child: Icon(Icons.add_a_photo_outlined,
                            size: 36, color: scheme.outline))
                    : AppImage(_photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.checkroom, color: scheme.outline))),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: tr('الاسم (مثلًا: قميص أزرق)',
                      'Name (e.g. blue shirt)')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب اسم', 'Enter a name')
                  : null,
            ),
            const SizedBox(height: 16),
            _chips(tr('النوع', 'Category'), kClothingCategories, _category,
                clothingCategoryLabel, (v) => setState(() => _category = v)),
            const SizedBox(height: 12),
            _chips(tr('الموسم', 'Season'), kClothingSeasons, _season,
                clothingSeasonLabel, (v) => setState(() => _season = v)),
            const SizedBox(height: 12),
            _chips(tr('المناسبة', 'Formality'), kClothingFormality, _formality,
                clothingFormalityLabel, (v) => setState(() => _formality = v)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _color,
              decoration: InputDecoration(
                  labelText: tr('اللون (اختياري)', 'Color (optional)')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
              title: Text(tr('مفضّلة', 'Favorite')),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
  }

  Widget _chips(String label, List<String> options, String selected,
      String Function(String) labelOf, void Function(String) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(labelOf(o)),
                selected: selected == o,
                onSelected: (_) => onPick(o),
              ),
          ],
        ),
      ],
    );
  }
}
