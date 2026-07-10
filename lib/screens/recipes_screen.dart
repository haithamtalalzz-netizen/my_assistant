import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/l10n.dart';
import '../data/recipes_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _repo = RecipesRepo();
  bool _loading = true;
  List<Recipe> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _form([Recipe? r]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => _RecipeForm(recipe: r)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _open(Recipe r) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text(r.name,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (r.photo.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(r.photo),
                    height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
            if (r.ingredients.isNotEmpty) ...[
              Text(tr('المقادير', 'Ingredients'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(r.ingredients),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final n = await _repo.addIngredientsToShopping(r);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr('اتضاف $n للتسوق',
                            'Added $n to shopping'))));
                  }
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(tr('ضيف المقادير للتسوق', 'Add to shopping')),
              ),
            ],
            if (r.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(tr('الطريقة', 'Steps'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(r.steps),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('دفتر الوصفات', 'Recipes'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.restaurant_menu_outlined,
                  text: tr('احفظ وصفات البيت — بمقاديرها وصورتها + ضيفها للتسوق بضغطة',
                      'Save home recipes — ingredients, photo + add to shopping in a tap'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final r = _items[i];
                    return InkWell(
                      onTap: () => _open(r),
                      onLongPress: () async {
                        if (!await confirmDelete(
                            context, tr('«${r.name}»', '"${r.name}"'))) {
                          return;
                        }
                        await _repo.delete(r.id!);
                        if (mounted) await _load();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: r.photo.isEmpty
                                  ? Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(Icons.restaurant, size: 32),
                                    )
                                  : Image.file(File(r.photo), fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recipe_fab',
        onPressed: () => _form(),
        tooltip: tr('وصفة جديدة', 'New recipe'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecipeForm extends StatefulWidget {
  final Recipe? recipe;

  const _RecipeForm({this.recipe});

  @override
  State<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<_RecipeForm> {
  final _name = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  String _photo = '';

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    if (r != null) {
      _name.text = r.name;
      _ingredients.text = r.ingredients;
      _steps.text = r.steps;
      _photo = r.photo;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'recipe_images'));
    await imagesDir.create(recursive: true);
    final dest = p.join(imagesDir.path,
        'rec_${DateTime.now().microsecondsSinceEpoch}${p.extension(picked.path)}');
    await File(picked.path).copy(dest);
    if (mounted) setState(() => _photo = dest);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    await RecipesRepo().save(Recipe(
      id: widget.recipe?.id,
      name: _name.text.trim(),
      photo: _photo,
      ingredients: _ingredients.text.trim(),
      steps: _steps.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recipe == null
              ? tr('وصفة جديدة', 'New recipe')
              : tr('تعديل الوصفة', 'Edit recipe'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: _pickPhoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photo.isEmpty
                  ? Center(
                      child: Icon(Icons.add_a_photo_outlined,
                          size: 32, color: scheme.outline))
                  : Image.file(File(_photo), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(
                labelText: tr('اسم الأكلة', 'Recipe name'),
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ingredients,
            maxLines: 5,
            decoration: InputDecoration(
                labelText: tr('المقادير (كل مقدار في سطر)',
                    'Ingredients (one per line)'),
                alignLabelWithHint: true,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _steps,
            maxLines: 6,
            decoration: InputDecoration(
                labelText: tr('الطريقة', 'Steps'),
                alignLabelWithHint: true,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
  }
}
