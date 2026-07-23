
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
  final List<String> _images = [];
  DateTime? _expiry;
  int _remindDays = 30;

  @override
  void initState() {
    super.initState();
    final d = widget.doc;
    if (d != null) {
      _title.text = d.title;
      _notes.text = d.notes;
      _images.addAll(d.allImages);
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
    if (mounted) setState(() => _images.add(stored));
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
    if (mounted) setState(() => _images.add(stored));
    await _suggestExpiryFromImage(stored);
  }

  /// بيمسح صورة من المستند (وبيشيلها من التخزين عشان ماتفضلش بلا مالك).
  Future<void> _removeImage(int i) async {
    final path = _images[i];
    setState(() => _images.removeAt(i));
    await AppImages.remove(path);
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
      imagePath: _images.isEmpty ? '' : _images.first,
      images: List<String>.from(_images),
      expiry: _expiry == null ? null : dayKey(_expiry!),
      remindDays: _remindDays,
      notes: _notes.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  /// صورة واحدة فى الشريط + زرار مسح، ومطوّلة بتخليها الغلاف.
  Widget _photoTile(ColorScheme scheme, int i) {
    final isCover = i == 0;
    return GestureDetector(
      onLongPress: isCover
          ? null
          : () => setState(() {
                final p = _images.removeAt(i);
                _images.insert(0, p);
              }),
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isCover
                  ? Border.all(color: scheme.primary, width: 2)
                  : null,
            ),
            child: AppImage(
              _images[i],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 32, color: scheme.outline),
              ),
            ),
          ),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: InkWell(
              onTap: () => _removeImage(i),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.black54,
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          if (isCover)
            PositionedDirectional(
              bottom: 4,
              start: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tr('الغلاف', 'Cover'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addPhotoTile(ColorScheme scheme) => InkWell(
        onTap: _showImageSourceSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 130,
          height: 150,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 32, color: scheme.outline),
              const SizedBox(height: 6),
              Text(
                  _images.isEmpty
                      ? tr('صوّر المستند', 'Snap the document')
                      : tr('صورة كمان', 'Add another'),
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ],
          ),
        ),
      );

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
            // شريط الصور — أول صورة هى الغلاف، وزرار ＋ فى الآخر.
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  if (i == _images.length) return _addPhotoTile(scheme);
                  return _photoTile(scheme, i);
                },
              ),
            ),
            if (_images.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                tr('أول صورة هى الغلاف — اضغط مطوّل على أى صورة تخليها الغلاف',
                    'The first photo is the cover — long-press any photo to make it the cover'),
                style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
            ],
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
