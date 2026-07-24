
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _docNumber = TextEditingController();
  final _issuer = TextEditingController();
  final _owner = TextEditingController();
  final _renewCost = TextEditingController();
  DateTime? _expiry;
  DateTime? _issued;
  int _remindDays = 30;
  String _type = 'other';
  int _validYears = 0;

  @override
  void initState() {
    super.initState();
    final d = widget.doc;
    if (d != null) {
      _title.text = d.title;
      _notes.text = d.notes;
      _images.addAll(d.allImages);
      _type = kDocTypes.contains(d.type) ? d.type : 'other';
      _docNumber.text = d.docNumber;
      _issuer.text = d.issuer;
      _owner.text = d.owner;
      _validYears = d.validYears;
      if (d.renewCost > 0) _renewCost.text = d.renewCost.toStringAsFixed(0);
      _issued = d.issued == null ? null : DateTime.tryParse(d.issued!);
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
    await _suggestFromImage(stored);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _docNumber.dispose();
    _issuer.dispose();
    _owner.dispose();
    _renewCost.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final stored = await AppImages.pickAndStore(source, namePrefix: 'doc');
    if (stored == null) return;
    if (mounted) setState(() => _images.add(stored));
    await _suggestFromImage(stored);
  }

  /// بيمسح صورة من المستند (وبيشيلها من التخزين عشان ماتفضلش بلا مالك).
  Future<void> _removeImage(int i) async {
    final path = _images[i];
    setState(() => _images.removeAt(i));
    await AppImages.remove(path);
  }

  /// OCR محلى على الجهاز: بيقرا الصورة ويملى الخانات الفاضية بس.
  ///
  /// **مابيدوسش على حاجة المستخدم كتبها** — الاقتراح الغلط اللى بيتكتب
  /// فوق قيمة صح أسوأ من مفيش اقتراح. وبيقول للمستخدم اتملى إيه.
  Future<void> _suggestFromImage(String path) async {
    // القراءة محتاجة ملف على القرص — مش متاحة على الويب.
    if (kIsWeb || AppImages.isInline(path)) return;
    final text = await OcrService.recognizeFromPath(path);
    if (text == null || !mounted) return;
    final scan = scanDocument(text, DateTime.now());
    if (scan.isEmpty) return;

    final filled = <String>[];
    setState(() {
      if (_docNumber.text.trim().isEmpty && scan.number != null) {
        _docNumber.text = scan.number!;
        filled.add(tr('الرقم', 'number'));
      }
      if (_issuer.text.trim().isEmpty && scan.issuer != null) {
        _issuer.text = scan.issuer!;
        filled.add(tr('الجهة', 'issuer'));
      }
      if (_issued == null && scan.issued != null) {
        _issued = scan.issued;
        filled.add(tr('الإصدار', 'issue date'));
      }
      if (_expiry == null && scan.expiry != null) {
        _expiry = scan.expiry;
        filled.add(tr('الانتهاء', 'expiry'));
      }
    });
    if (filled.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(tr('قريت من الصورة: ${filled.join(' · ')} — راجعها',
          'Read from the photo: ${filled.join(' · ')} — please check')),
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

  /// الانتهاء المحسوب من الإصدار + المدة (نفس منطق `DocItem.computedExpiry`
  /// بس على قيم الفورم الحيّة عشان يبان قبل الحفظ).
  DateTime? get _computedExpiry {
    if (_issued == null || _validYears <= 0) return null;
    return DateTime(
        _issued!.year + _validYears, _issued!.month, _issued!.day);
  }

  Future<void> _pickIssued() async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _issued ?? now,
      first: now.subtract(const Duration(days: 365 * 40)),
      last: now,
    );
    if (picked != null) setState(() => _issued = picked);
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
      type: _type,
      docNumber: _docNumber.text.trim(),
      issuer: _issuer.text.trim(),
      owner: _owner.text.trim(),
      issued: _issued == null ? null : dayKey(_issued!),
      validYears: _validYears,
      renewCost: double.tryParse(_renewCost.text.trim()) ?? 0,
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
            // ---- النوع ----
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: tr('النوع', 'Type')),
              items: [
                for (final t in kDocTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(docTypeIcon(t), size: 18),
                      const SizedBox(width: 8),
                      Text(docTypeLabel(t)),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            // ---- الرقم والجهة ----
            TextFormField(
              controller: _docNumber,
              decoration: InputDecoration(
                labelText: tr('رقم المستند', 'Document number'),
                suffixIcon: _docNumber.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: tr('انسخ', 'Copy'),
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _docNumber.text.trim()));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(tr('اتنسخ ✓', 'Copied ✓'))));
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _issuer,
              decoration: InputDecoration(
                  labelText: tr('جهة الإصدار', 'Issued by')),
            ),
            const SizedBox(height: 16),
            // ---- لمين (مستندات العيلة) ----
            TextFormField(
              controller: _owner,
              decoration: InputDecoration(
                  labelText: tr('المستند بتاع مين؟', 'Whose document?'),
                  hintText: tr('سيبها فاضية = بتاعك', 'Leave empty = yours')),
            ),
            const SizedBox(height: 16),
            // ---- تاريخ الإصدار + مدة الصلاحية (بيحسبوا الانتهاء) ----
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickIssued,
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: tr('تاريخ الإصدار (اختيارى)',
                              'Issue date (optional)')),
                      child: Text(_issued == null
                          ? tr('من غير تاريخ', 'No date')
                          : arShortDate(_issued!)),
                    ),
                  ),
                ),
                if (_issued != null)
                  IconButton(
                    onPressed: () => setState(() => _issued = null),
                    tooltip: tr('امسح التاريخ', 'Clear date'),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _validYears,
              decoration: InputDecoration(
                  labelText: tr('مدة الصلاحية', 'Valid for')),
              items: [
                DropdownMenuItem(
                    value: 0, child: Text(tr('مش محدّدة', 'Not set'))),
                for (final y in const [1, 2, 3, 5, 7, 10])
                  DropdownMenuItem(
                      value: y,
                      child: Text(tr('${arNum(y)} سنة', '${arNum(y)} years'))),
              ],
              onChanged: (v) => setState(() => _validYears = v ?? 0),
            ),
            // التجديد التلقائى: لو فيه إصدار + مدة، الانتهاء بيتحسب لوحده.
            if (_expiry == null && _computedExpiry != null) ...[
              const SizedBox(height: 6),
              Text(
                tr('الانتهاء المحسوب: ${arShortDate(_computedExpiry!)}',
                    'Computed expiry: ${arShortDate(_computedExpiry!)}'),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            // ---- تكلفة التجديد ----
            TextFormField(
              controller: _renewCost,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: tr('تكلفة التجديد (اختيارى)',
                      'Renewal cost (optional)'),
                  hintText: tr('هتظهر لما تجدّد', 'Shown when you renew')),
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
