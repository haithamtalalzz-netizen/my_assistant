import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/meds_repo.dart';
import '../../data/pharmacy_repo.dart';
import '../../models/models.dart';

/// أنواع الأدوية ووحداتها (قيم عربية مخزّنة).
const List<String> kMedForms = [
  'أقراص',
  'كبسولات',
  'شراب',
  'فوار',
  'كريم',
  'مرهم',
  'حقن',
  'قطرة',
  'بخاخ',
  'لبوس',
  'أخرى',
];

const List<String> kMedUnits = [
  'علبة',
  'شريط',
  'قرص',
  'عبوة',
  'قطعة',
  'سرنجة',
  'زجاجة',
  'أنبوبة',
  'كيس',
  'أخرى',
];

class MedForm extends StatefulWidget {
  final Medication? medication;

  /// اسم مبدئي (لما نيجي من صيدلية البيت مثلًا).
  final String? initialName;

  const MedForm({super.key, this.medication, this.initialName});

  @override
  State<MedForm> createState() => _MedFormState();
}

class _MedFormState extends State<MedForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();
  final List<String> _times = [];
  String? _form;
  String? _unit;
  bool _addToPharmacy = false;

  /// null = مستمر، -1 = سيب الكورس الحالي زي ما هو، غير كده عدد أيام.
  int? _courseDays;

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    if (m != null) {
      _name.text = m.name;
      _dosage.text = m.dosage;
      _notes.text = m.notes;
      _times.addAll(m.times);
      if (m.endDate != null) _courseDays = -1;
      if (m.form.isNotEmpty) _form = m.form;
      if (m.unit.isNotEmpty) _unit = m.unit;
    } else if (widget.initialName != null) {
      _name.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    if (_times.length >= MedsRepo.maxSlots) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(tr('أقصى عدد جرعات في اليوم ${arNum(MedsRepo.maxSlots)}',
                  'Max ${arNum(MedsRepo.maxSlots)} doses per day'))));
      return;
    }
    final picked = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked == null) return;
    final slot =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_times.contains(slot)) return;
    setState(() {
      _times.add(slot);
      _times.sort();
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('ضيف وقت جرعة واحد على الأقل',
              'Add at least one dose time'))));
      return;
    }
    final String? endDate;
    if (_courseDays == -1) {
      endDate = widget.medication?.endDate;
    } else if (_courseDays == null) {
      endDate = null;
    } else {
      endDate = dayKey(
          DateTime.now().add(Duration(days: _courseDays! - 1)));
    }
    await MedsRepo().save(Medication(
      id: widget.medication?.id,
      name: _name.text.trim(),
      dosage: _dosage.text.trim(),
      times: List.of(_times),
      notes: _notes.text.trim(),
      active: widget.medication?.active ?? true,
      endDate: endDate,
      form: _form ?? '',
      unit: _unit ?? '',
    ));
    // ربط: يضيفه لصيدلية البيت كمان لو مختار.
    if (_addToPharmacy && widget.medication == null) {
      await PharmacyRepo()
          .save(PharmacyItem(name: _name.text.trim(), quantity: 1));
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.medication == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('دواء جديد', 'New medication')
              : tr('تعديل دواء', 'Edit medication'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: tr('اسم الدواء', 'Medication name')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب اسم الدواء', 'Enter the name')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosage,
              decoration: InputDecoration(
                  labelText: tr('الجرعة (مثلًا: قرص واحد بعد الأكل)',
                      'Dose (e.g. one pill after meals)')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _form,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: tr('النوع', 'Form')),
                    items: [
                      for (final f in kMedForms)
                        DropdownMenuItem(value: f, child: Text(f)),
                    ],
                    onChanged: (v) => setState(() => _form = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: tr('الوحدة', 'Unit')),
                    items: [
                      for (final u in kMedUnits)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => _unit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                  labelText: tr('أوقات الجرعات اليومية', 'Daily dose times')),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in _times)
                    Chip(
                      label: Text(arTimeOfSlot(t)),
                      onDeleted: () => setState(() => _times.remove(t)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(tr('أضف وقت', 'Add time')),
                    onPressed: _addTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _courseDays,
              decoration: InputDecoration(
                  labelText: tr('مدة الكورس — بيقف لوحده لما يخلص',
                      'Course length — auto-stops when done')),
              items: [
                if (widget.medication?.endDate != null)
                  DropdownMenuItem(
                      value: -1,
                      child: Text(tr(
                          'زي ما هو (ينتهي ${arShortDate(DateTime.parse(widget.medication!.endDate!))})',
                          'Keep as is (ends ${arShortDate(DateTime.parse(widget.medication!.endDate!))})'))),
                DropdownMenuItem(
                    value: null,
                    child: Text(tr('مستمر (من غير نهاية)', 'Ongoing (no end)'))),
                for (final d in const [3, 5, 7, 10, 14])
                  DropdownMenuItem(
                      value: d,
                      child: Text(tr('${arNum(d)} أيام من النهارده',
                          '${arNum(d)} days from today'))),
              ],
              onChanged: (v) => setState(() => _courseDays = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: tr('ملاحظات (اختياري)', 'Notes (optional)')),
            ),
            if (widget.medication == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _addToPharmacy,
                onChanged: (v) => setState(() => _addToPharmacy = v ?? false),
                title: Text(tr('أضفه لصيدلية البيت كمان',
                    'Also add to home pharmacy')),
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
