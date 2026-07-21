
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/ocr.dart';
import '../../data/docs_repo.dart';
import '../../models/models.dart';
import '../../widgets/wheel_date_picker.dart';

const List<int> kRemindDaysOptions = [7, 15, 30, 60, 90];

class DocForm extends StatefulWidget {
  final DocItem? doc;

  /// صورة جاية من «مشاركة» تطبيق تاني — بتتنسخ لمجلد الصور تلقائيًا.
  final String? sharedImagePath;

  const DocForm({super.key, this.doc, this.sharedImagePath});

  @override
  State<DocForm> createState() => _DocFormState();
}

class _DocFormState extends State<DocForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String _imagePath = '';
  DateTime? _expiry;
  int _remindDays = 30;

  @override
  void initState() {
    super.initState();
    final d = widget.doc;
    if (d != null) {
      _title.text = d.title;
      _notes.text = d.notes;
      _imagePath = d.imagePath;
      _expiry = d.expiry == null ? null : DateTime.parse(d.expiry!);
      _remindDays =
          kRemindDaysOptions.contains(d.remindDays) ? d.remindDays : 30;
    }
    if (widget.sharedImagePath != null) {
      _importShared(widget.sharedImagePath!);
    }
  }

  Future<void> _importShared(String source) async {
    final stored = await AppImages.storeXFile(XFile(source), namePrefix: 'doc');
    if (stored == null) return; // الصورة المشاركة ممكن تكون اتمسحت
    if (mounted) setState(() => _imagePath = stored);
    await _suggestExpiryFromImage(stored);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final stored = await AppImages.pickAndStore(source, namePrefix: 'doc');
    if (stored == null) return;
    if (mounted) setState(() => _imagePath = stored);
    await _suggestExpiryFromImage(stored);
  }

  /// OCR محلي: لو لقى تاريخ مستقبلي في الصورة يقترحه كتاريخ انتهاء.
  Future<void> _suggestExpiryFromImage(String path) async {
    if (_expiry != null) return;
    // قراءة التاريخ من الصورة محتاجة ملف على القرص — مش متاحة على الويب.
    if (kIsWeb || AppImages.isInline(path)) return;
    final text = await OcrService.recognizeFromPath(path);
    if (text == null || !mounted) return;
    final suggested = bestExpiryDate(text, DateTime.now());
    if (suggested == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text(tr('لقيت تاريخ في الصورة: ${arShortDate(suggested)}',
          'Found a date in the image: ${arShortDate(suggested)}')),
      action: SnackBarAction(
        label: tr('استخدمه كانتهاء', 'Use as expiry'),
        onPressed: () {
          if (mounted) setState(() => _expiry = suggested);
        },
      ),
    ));
  }

  Future<void> _showImageSourceSheet() async {
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

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _expiry ?? now,
      first: now.subtract(const Duration(days: 365 * 5)),
      last: now.add(const Duration(days: 365 * 15)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await DocsRepo().save(DocItem(
      id: widget.doc?.id,
      title: _title.text.trim(),
      imagePath: _imagePath,
      expiry: _expiry == null ? null : dayKey(_expiry!),
      remindDays: _remindDays,
      notes: _notes.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.doc == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('مستند جديد', 'New document')
              : tr('تعديل مستند', 'Edit document'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _showImageSourceSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagePath.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 36, color: scheme.outline),
                          const SizedBox(height: 8),
                          Text(tr('صور المستند أو اختاره من الصور',
                              'Snap the document or pick from gallery'),
                              style: TextStyle(color: scheme.outline)),
                        ],
                      )
                    : AppImage(_imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 36, color: scheme.outline),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: tr('اسم المستند (مثلًا: رخصة السواقة)',
                      "Document name (e.g. driver's license)")),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب اسم المستند', 'Enter the document name')
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickExpiry,
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: tr('تاريخ الانتهاء (اختياري)',
                              'Expiry date (optional)')),
                      child: Text(_expiry == null
                          ? tr('من غير تاريخ', 'No date')
                          : arShortDate(_expiry!)),
                    ),
                  ),
                ),
                if (_expiry != null)
                  IconButton(
                    onPressed: () => setState(() => _expiry = null),
                    tooltip: tr('امسح التاريخ', 'Clear date'),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _remindDays,
              decoration: InputDecoration(
                  labelText:
                      tr('فكرني قبل الانتهاء بـ', 'Remind me before expiry by')),
              items: [
                for (final d in kRemindDaysOptions)
                  DropdownMenuItem(
                      value: d,
                      child: Text(tr('${arNum(d)} يوم', '${arNum(d)} days'))),
              ],
              onChanged: (v) => setState(() => _remindDays = v ?? _remindDays),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration:
                  InputDecoration(labelText: tr('ملاحظات (اختياري)', 'Notes (optional)')),
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
  }
}
