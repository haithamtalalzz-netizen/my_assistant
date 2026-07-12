import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ar.dart';
import '../../core/calendar_sync.dart';
import '../../core/l10n.dart';
import '../../data/occasions_repo.dart';
import '../../models/models.dart';
import '../../widgets/wheel_date_picker.dart';

Map<int, String> occasionRemindOptions() => {
      0: tr('يوم المناسبة نفسه', 'On the day'),
      1: tr('قبلها بيوم', '1 day before'),
      3: tr('قبلها بـ ٣ أيام', '3 days before'),
      7: tr('قبلها بأسبوع', '1 week before'),
    };

class OccasionForm extends StatefulWidget {
  final Occasion? occasion;

  const OccasionForm({super.key, this.occasion});

  @override
  State<OccasionForm> createState() => _OccasionFormState();
}

class _OccasionFormState extends State<OccasionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _person = TextEditingController();
  int? _month;
  int? _day;
  int _remindDays = 1;

  @override
  void initState() {
    super.initState();
    final o = widget.occasion;
    if (o != null) {
      _title.text = o.title;
      _person.text = o.person;
      _month = o.month;
      _day = o.day;
      _remindDays = occasionRemindOptions().containsKey(o.remindDays)
          ? o.remindDays
          : 1;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _person.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _month == null ? now : DateTime(now.year, _month!, _day!),
      first: DateTime(now.year),
      last: DateTime(now.year, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _month = picked.month;
        _day = picked.day;
      });
    }
  }

  Future<void> _addToPhoneCalendar() async {
    final title = _title.text.trim();
    if (title.isEmpty || _month == null || _day == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اكتب العنوان واختر التاريخ الأول',
              'Enter title and pick a date first'))));
      return;
    }
    // مناسبة سنوية → تاريخها السنة دي (ولو فاتت خدها السنة الجاية).
    final now = DateTime.now();
    var date = DateTime(now.year, _month!, _day!);
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      date = DateTime(now.year + 1, _month!, _day!);
    }
    final t = _person.text.trim().isEmpty
        ? title
        : '$title — ${_person.text.trim()}';
    await CalendarSync.addEvent(title: t, start: date, allDay: true);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_month == null || _day == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اختار تاريخ المناسبة الأول',
              'Pick the occasion date first'))));
      return;
    }
    await OccasionsRepo().save(Occasion(
      id: widget.occasion?.id,
      title: _title.text.trim(),
      person: _person.text.trim(),
      month: _month!,
      day: _day!,
      remindDays: _remindDays,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.occasion == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('مناسبة جديدة', 'New occasion')
              : tr('تعديل مناسبة', 'Edit occasion')),
          actions: [
            IconButton(
              tooltip: tr('أضف لتقويم الموبايل', 'Add to phone calendar'),
              icon: const Icon(Icons.event_available_outlined),
              onPressed: _addToPhoneCalendar,
            ),
          ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText:
                      tr('المناسبة (مثلًا: عيد ميلاد)', 'Occasion (e.g. birthday)')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب اسم المناسبة', 'Enter the occasion name')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _person,
              decoration: InputDecoration(
                  labelText: tr('الشخص (اختياري — مثلًا: ماما)',
                      'Person (optional — e.g. Mom)')),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText:
                        tr('التاريخ (بيتكرر سنويًا)', 'Date (repeats yearly)')),
                child: Text(_month == null
                    ? tr('اختار الشهر واليوم', 'Pick month & day')
                    : '${arNum(_day!)} ${DateFormat('MMMM', 'ar').format(DateTime(2000, _month!))}'),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _remindDays,
              decoration:
                  InputDecoration(labelText: tr('فكرني', 'Remind me')),
              items: [
                for (final e in occasionRemindOptions().entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _remindDays = v ?? _remindDays),
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
