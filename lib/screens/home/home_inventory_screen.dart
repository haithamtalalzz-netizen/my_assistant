import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/home_inventory_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// جرد ممتلكات البيت — أشياءك وقيمتها بصورة اختيارية (للتأمين/الطوارئ).
class HomeInventoryScreen extends StatefulWidget {
  const HomeInventoryScreen({super.key});

  @override
  State<HomeInventoryScreen> createState() => _HomeInventoryScreenState();
}

class _HomeInventoryScreenState extends State<HomeInventoryScreen> {
  final _repo = HomeInventoryRepo();
  bool _loading = true;
  List<HomeInventoryItem> _items = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    final total = await _repo.totalValue();
    if (!mounted) return;
    setState(() {
      _items = items;
      _total = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('جرد الممتلكات', 'Home inventory'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    color: scheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(tr('إجمالي قيمة الممتلكات', 'Total inventory value'),
                              style: TextStyle(color: scheme.onPrimaryContainer)),
                          const SizedBox(height: 4),
                          Text(egp(_total),
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onPrimaryContainer)),
                          Text(
                              tr('${arNum(_items.length)} عنصر', '${arNum(_items.length)} items'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onPrimaryContainer
                                      .withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    EmptyHint(
                        icon: Icons.inventory_2_outlined,
                        text: tr('سجّل أجهزتك وأثاثك وقيمتهم — يفيدك وقت التأمين أو الطوارئ',
                            'Log your appliances & furniture with values — useful for insurance/emergencies'))
                  else
                    for (final it in _items) _tile(it, scheme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('عنصر جديد', 'New item'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(HomeInventoryItem it, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: it.photo.isNotEmpty && !kIsWeb && File(it.photo).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(it.photo),
                    width: 44, height: 44, fit: BoxFit.cover))
            : CircleAvatar(
                backgroundColor: scheme.surfaceContainerHighest,
                child: const Icon(Icons.chair_outlined)),
        title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (it.category.isNotEmpty) inventoryCategoryLabel(it.category),
          if (it.location.isNotEmpty) it.location,
          if (it.note.isNotEmpty) it.note,
        ].join('  •  ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (it.value > 0)
              Text(egp(it.value),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') await _form(it);
                if (v == 'delete') {
                  if (!mounted) return;
                  if (await confirmDelete(context, tr('"${it.name}"', '"${it.name}"'))) {
                    await _repo.delete(it.id!);
                    if (mounted) await _load();
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
        onTap: () => _form(it),
      ),
    );
  }

  Future<void> _form([HomeInventoryItem? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final value = TextEditingController(
        text: item == null || item.value == 0 ? '' : item.value.toStringAsFixed(0));
    final location = TextEditingController(text: item?.location ?? '');
    final note = TextEditingController(text: item?.note ?? '');
    var category = item?.category ?? kInventoryCategories.first;
    var photo = item?.photo ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null ? tr('عنصر جديد', 'New item') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: name,
                  autofocus: item == null,
                  decoration: InputDecoration(
                      labelText: tr('الاسم (تلاجة، لابتوب…)', 'Name (fridge, laptop…)'))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: tr('الفئة', 'Category')),
                items: [
                  for (final c in kInventoryCategories)
                    DropdownMenuItem(
                        value: c, child: Text(inventoryCategoryLabel(c))),
                ],
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: tr('القيمة التقريبية (ج.م)', 'Approx. value (EGP)'))),
              const SizedBox(height: 8),
              TextField(
                  controller: location,
                  decoration: InputDecoration(
                      labelText: tr('المكان (المطبخ، الأوضة…)', 'Location'))),
              const SizedBox(height: 8),
              TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: tr('ملاحظة', 'Note'))),
              if (!kIsWeb) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (photo.isNotEmpty && File(photo).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(photo),
                            width: 48, height: 48, fit: BoxFit.cover),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(photo.isEmpty
                          ? tr('صورة (اختيارى)', 'Photo (optional)')
                          : tr('غيّر الصورة', 'Change photo')),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                            source: ImageSource.camera, maxWidth: 1400);
                        if (picked != null) setD(() => photo = picked.path);
                      },
                    ),
                  ],
                ),
              ],
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
      await _repo.save(HomeInventoryItem(
        id: item?.id,
        name: name.text.trim(),
        category: category,
        value: double.tryParse(toEnglishDigits(value.text.trim())) ?? 0,
        location: location.text.trim(),
        note: note.text.trim(),
        photo: photo,
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    value.dispose();
    location.dispose();
    note.dispose();
  }
}
