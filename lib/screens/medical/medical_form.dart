import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/medical_repo.dart';
import '../../data/money_repo.dart';
import '../../models/models.dart';
import '../../widgets/wheel_date_picker.dart';

/// تخصصات طبية شائعة (اختيار سريع — المستخدم يقدر يكتب أي تخصص).
const List<String> kMedicalSpecialties = [
  'باطنة',
  'قلب',
  'عظام',
  'أسنان',
  'جلدية',
  'عيون',
  'أنف وأذن',
  'مخ وأعصاب',
  'مسالك',
  'نسا وتوليد',
  'أطفال',
  'غدد وسكر',
  'صدر',
  'جهاز هضمي',
  'كلى',
  'نفسية',
  'جراحة',
];

class MedicalForm extends StatefulWidget {
  final MedicalRecord? record;

  const MedicalForm({super.key, this.record});

  @override
  State<MedicalForm> createState() => _MedicalFormState();
}

class _MedicalFormState extends State<MedicalForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _provider = TextEditingController();
  final _specialty = TextEditingController();
  final _result = TextEditingController();
  final _cost = TextEditingController();

  String _type = kMedicalTypes.first;
  DateTime _date = DateTime.now();
  final List<String> _photos = [];
  bool _logCost = true;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _type = r.type;
      _date = DateTime.tryParse(r.day) ?? DateTime.now();
      _title.text = r.title;
      _provider.text = r.provider;
      _specialty.text = r.specialty;
      _result.text = r.result;
      _cost.text = r.cost > 0 ? r.cost.toStringAsFixed(0) : '';
      _photos.addAll(r.photos);
      _logCost = false; // التعديل مايعيدش تسجيل المصروف
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _provider.dispose();
    _specialty.dispose();
    _result.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<String?> _copyToApp(XFile src) async =>
      AppImages.storeXFile(src, namePrefix: 'med');

  Future<void> _addFromCamera() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 2200, imageQuality: 85);
    if (picked == null) return;
    final dest = await _copyToApp(picked);
    if (dest != null && mounted) setState(() => _photos.add(dest));
  }

  Future<void> _addFromGallery() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 2200, imageQuality: 85);
    for (final x in picked) {
      final dest = await _copyToApp(x);
      if (dest != null) _photos.add(dest);
    }
    if (mounted) setState(() {});
  }

  Future<void> _photoSourceSheet() async {
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
                _addFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(tr('من الصور', 'From gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _addFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _date,
      first: now.subtract(const Duration(days: 365 * 20)),
      last: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cost = parseNumber(_cost.text) ?? 0;
    await MedicalRepo().save(MedicalRecord(
      id: widget.record?.id,
      type: _type,
      day: dayKey(_date),
      title: _title.text.trim(),
      provider: _provider.text.trim(),
      specialty: _specialty.text.trim(),
      result: _result.text.trim(),
      cost: cost,
      photos: _photos,
    ));
    // التكلفة تتسجّل مصروف «صحة» (لو مفعّل والمبلغ موجود).
    if (_logCost && cost > 0) {
      await MoneyRepo().add(Expense(
        amount: cost,
        category: 'صحة',
        note: _title.text.trim(),
        day: dayKey(_date),
      ));
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.record == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('سجل طبي جديد', 'New medical record')
              : tr('تعديل السجل', 'Edit record'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in kMedicalTypes)
                  ChoiceChip(
                    label: Text(medicalTypeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(labelText: tr('التاريخ', 'Date')),
                child: Text(arFullDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: tr('العنوان (مثلًا: زيارة دكتور القلب / صورة دم)',
                      'Title (e.g. cardiology visit / blood test)')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب عنوان', 'Enter a title')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _provider,
              decoration: InputDecoration(
                  labelText: tr('الطبيب / المكان (اختياري)',
                      'Doctor / place (optional)')),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(tr('التخصص', 'Specialty'),
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in kMedicalSpecialties)
                  ChoiceChip(
                    label: Text(s),
                    selected: _specialty.text == s,
                    onSelected: (_) => setState(() => _specialty.text = s),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _specialty,
              decoration: InputDecoration(
                  labelText:
                      tr('أو اكتب تخصص تاني', 'Or type another specialty')),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _result,
              maxLines: 4,
              decoration: InputDecoration(
                  labelText: tr('النتيجة / التشخيص / الملاحظات',
                      'Result / diagnosis / notes'),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('التكلفة (ج.م، اختياري)', 'Cost (EGP, optional)')),
            ),
            if (widget.record == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _logCost,
                onChanged: (v) => setState(() => _logCost = v ?? true),
                title: Text(tr('سجّل التكلفة كمصروف «صحة»',
                    'Log the cost as a "Health" expense')),
              ),
            const SizedBox(height: 8),
            Text(tr('المرفقات (روشتة / تقرير / أشعة)',
                'Attachments (prescription / report / scan)'),
                style: TextStyle(color: scheme.outline)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  _photoThumb(context, i),
                InkWell(
                  onTap: _photoSourceSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_a_photo_outlined,
                        color: scheme.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
  }

  Widget _photoThumb(BuildContext context, int i) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AppImage(_photos[i],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const SizedBox(width: 80, height: 80, child: Icon(Icons.broken_image_outlined))),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            color: Colors.black54,
            onPressed: () => setState(() => _photos.removeAt(i)),
          ),
        ),
      ],
    );
  }
}
