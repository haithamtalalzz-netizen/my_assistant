import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/warranty_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';
import '../../widgets/wheel_date_picker.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final _repo = WarrantyRepo();
  bool _loading = true;
  List<Warranty> _items = [];

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

  Future<String?> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'warranty_images'));
    await imagesDir.create(recursive: true);
    final dest = p.join(imagesDir.path,
        'war_${DateTime.now().microsecondsSinceEpoch}${p.extension(picked.path)}');
    await File(picked.path).copy(dest);
    return dest;
  }

  Future<void> _form([Warranty? w]) async {
    final name = TextEditingController(text: w?.itemName ?? '');
    final months =
        TextEditingController(text: (w?.warrantyMonths ?? 12).toString());
    var purchase = w?.purchaseDate == null
        ? DateTime.now()
        : DateTime.tryParse(w!.purchaseDate) ?? DateTime.now();
    var photo = w?.photo ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(w == null
              ? tr('ضمان جديد', 'New warranty')
              : tr('تعديل', 'Edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: w == null,
                  decoration: InputDecoration(
                      labelText: tr('الجهاز (مثلًا: تلاجة)',
                          'Item (e.g. fridge)')),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await pickWheelDate(
                      ctx,
                      initial: purchase,
                      first: DateTime(DateTime.now().year - 15),
                      last: DateTime.now(),
                    );
                    if (picked != null) setD(() => purchase = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: tr('تاريخ الشراء', 'Purchase date')),
                    child: Text(arShortDate(purchase)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: months,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: tr('مدة الضمان (شهور)', 'Warranty (months)')),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (photo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(photo),
                              width: 44, height: 44, fit: BoxFit.cover),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final dest = await _pickPhoto();
                        if (dest != null) setD(() => photo = dest);
                      },
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(tr('صورة الفاتورة', 'Receipt photo')),
                    ),
                  ],
                ),
              ],
            ),
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
      await _repo.save(Warranty(
        id: w?.id,
        itemName: name.text.trim(),
        purchaseDate: dayKey(purchase),
        warrantyMonths: int.tryParse(months.text.trim()) ?? 12,
        photo: photo,
      ));
      if (mounted) await _load();
    }
    name.dispose();
    months.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('أرشيف الضمانات', 'Warranty archive')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.verified_outlined,
                  text: tr(
                      'سجّل أجهزتك وفواتيرها ومدة الضمان — وهنبّهك قبل ما يخلص',
                      'Log devices, receipts & warranty period — get alerted before it ends'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final w = _items[i];
                      final exp = w.expiry;
                      final expired = exp.isBefore(now);
                      final daysLeft = exp.difference(now).inDays;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          leading: w.photo.isEmpty
                              ? Icon(Icons.verified,
                                  color: expired ? scheme.error : Colors.green)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(File(w.photo),
                                      width: 44, height: 44, fit: BoxFit.cover),
                                ),
                          title: Text(w.itemName),
                          subtitle: Text(expired
                              ? tr('الضمان انتهى ${arShortDate(exp)}',
                                  'Warranty ended ${arShortDate(exp)}')
                              : tr('الضمان لحد ${arShortDate(exp)} (${arNum(daysLeft)} يوم)',
                                  'Covered until ${arShortDate(exp)} (${arNum(daysLeft)} days)')),
                          subtitleTextStyle:
                              expired ? TextStyle(color: scheme.error) : null,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await _form(w);
                              } else if (v == 'delete') {
                                if (!await confirmDelete(context,
                                    tr('ضمان "${w.itemName}"',
                                        'warranty "${w.itemName}"'))) {
                                  return;
                                }
                                await _repo.delete(w.id!);
                                if (mounted) await _load();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(tr('حذف', 'Delete'))),
                            ],
                          ),
                          onTap: () => _form(w),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'warranty_fab',
        onPressed: () => _form(),
        tooltip: tr('ضمان جديد', 'New warranty'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
