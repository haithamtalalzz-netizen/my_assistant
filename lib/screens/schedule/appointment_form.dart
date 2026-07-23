import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:convert';

import '../../core/ar.dart';
import '../../core/calendar_sync.dart';
import '../../core/l10n.dart';
import '../../data/appointments_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/wheel_date_picker.dart';

const List<String> kApptCategories = ['شخصي', 'شغل', 'صحة', 'عيلة'];

/// عرض تصنيف الموعد بالإنجليزي مع إبقاء القيمة المخزّنة عربي.
String apptCategoryLabel(String c) => switch (c) {
      'شخصي' => tr('شخصي', 'Personal'),
      'شغل' => tr('شغل', 'Work'),
      'صحة' => tr('صحة', 'Health'),
      'عيلة' => tr('عيلة', 'Family'),
      _ => c,
    };

Map<int, String> remindOptions() => {
      15: tr('قبلها بربع ساعة', '15 min before'),
      30: tr('قبلها بنص ساعة', '30 min before'),
      60: tr('قبلها بساعة', '1 hour before'),
      180: tr('قبلها بـ ٣ ساعات', '3 hours before'),
      1440: tr('قبلها بيوم', '1 day before'),
    };

const List<String> kRepeatModes = ['none', 'daily', 'weekly', 'monthly'];

String repeatLabel(String r) => switch (r) {
      'none' => tr('مرة واحدة', 'One-time'),
      'daily' => tr('كل يوم', 'Daily'),
      'weekly' => tr('كل أسبوع', 'Weekly'),
      'monthly' => tr('كل شهر', 'Monthly'),
      _ => r,
    };

/// قوالب مواعيد جاهزة: تملأ النوع + وقت التذكير + اقتراح عنوان بضغطة.
const List<({String key, String title, String category, int remind})>
    kApptTemplates = [
  (key: 'doctor', title: 'زيارة دكتور', category: 'صحة', remind: 180),
  (key: 'work', title: 'اجتماع شغل', category: 'شغل', remind: 60),
  (key: 'family', title: 'لمّة العيلة', category: 'عيلة', remind: 1440),
  (key: 'pharmacy', title: 'الصيدلية', category: 'صحة', remind: 30),
  (key: 'gov', title: 'مصلحة حكومية', category: 'شخصي', remind: 1440),
];

String apptTemplateLabel(String key) => switch (key) {
      'doctor' => tr('دكتور', 'Doctor'),
      'work' => tr('شغل', 'Work'),
      'family' => tr('عائلة', 'Family'),
      'pharmacy' => tr('صيدلية', 'Pharmacy'),
      'gov' => tr('حكومي', 'Government'),
      _ => key,
    };

class AppointmentForm extends StatefulWidget {
  final Appointment? appointment;

  const AppointmentForm({super.key, this.appointment});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _travel = TextEditingController();
  final _location = TextEditingController();
  String _category = kApptCategories.first;
  DateTime? _date;
  TimeOfDay? _time;
  int _remind = 60;
  String _repeat = 'none';
  // وضع «تواريخ مختلفة»: كل موعد بتاريخ/وقت مستقل (لمواعيد غير منتظمة).
  bool _customMode = false;
  final List<DateTime> _customDates = [];

  /// قوالب المستخدم الخاصة (عناوين) — محفوظة فى جدول الإعدادات كـJSON.
  static const _kCustomTplKey = 'appt_custom_templates';
  List<String> _customTemplates = [];

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    if (a != null) {
      _title.text = a.title;
      _notes.text = a.notes;
      _category = kApptCategories.contains(a.category)
          ? a.category
          : kApptCategories.first;
      _date = dateOnly(a.when);
      _time = TimeOfDay.fromDateTime(a.when);
      _remind = remindOptions().containsKey(a.remindBeforeMin)
          ? a.remindBeforeMin
          : 60;
      if (a.travelMin > 0) _travel.text = a.travelMin.toString();
      _repeat = kRepeatModes.contains(a.repeat) ? a.repeat : 'none';
      _location.text = a.location;
    }
    _loadCustomTemplates();
  }

  Future<void> _loadCustomTemplates() async {
    final raw = await SettingsRepo().get(_kCustomTplKey) ?? '[]';
    List<String> list;
    try {
      list = (jsonDecode(raw) as List).map((e) => '$e').toList();
    } on Object {
      list = []; // قيمة تالفة ما تكسرش الفورم
    }
    if (mounted) setState(() => _customTemplates = list);
  }

  Future<void> _saveCustomTemplates() =>
      SettingsRepo().set(_kCustomTplKey, jsonEncode(_customTemplates));

  /// «+» جنب القوالب السريعة: إضافة قالب باسم من اختيار المستخدم.
  Future<void> _addCustomTemplate() async {
    final c = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('قالب جديد', 'New template')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
              labelText: tr('اسم القالب', 'Template name'),
              hintText: tr('مثال: متابعة المستشفى', 'e.g. Hospital follow-up')),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    final t = title?.trim() ?? '';
    if (t.isEmpty || _customTemplates.contains(t)) return;
    setState(() => _customTemplates.add(t));
    await _saveCustomTemplates();
  }

  /// ضغطة مطوَّلة على قالب خاص = حذفه (بعد تأكيد).
  Future<void> _deleteCustomTemplate(String t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('حذف القالب؟', 'Delete template?')),
        content: Text('«$t»'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حذف', 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _customTemplates.remove(t));
    await _saveCustomTemplates();
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _travel.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _openMaps() async {
    final q = _location.text.trim();
    if (q.isEmpty) return;
    // خرائط جوجل بالبحث النصى — تفتح تطبيق الخرائط أو المتصفح.
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('مقدرش أفتح الخرائط', "Couldn't open maps"))));
    }
  }

  void _applyTemplate(
      ({String key, String title, String category, int remind}) t) {
    setState(() {
      if (_title.text.trim().isEmpty) _title.text = t.title;
      _category = kApptCategories.contains(t.category)
          ? t.category
          : _category;
      _remind = remindOptions().containsKey(t.remind) ? t.remind : _remind;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _date ?? now,
      first: now.subtract(const Duration(days: 365)),
      last: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addCustomDate() async {
    final now = DateTime.now();
    final d = await pickWheelDate(
      context,
      initial: now,
      first: now.subtract(const Duration(days: 365)),
      last: now.add(const Duration(days: 365 * 5)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (t == null) return;
    setState(() {
      _customDates.add(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      _customDates.sort();
    });
  }

  Future<void> _addToPhoneCalendar() async {
    final title = _title.text.trim();
    if (title.isEmpty || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اكتب العنوان والتاريخ والوقت الأول',
              'Enter title, date and time first'))));
      return;
    }
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    await CalendarSync.addEvent(
      title: title,
      description: _notes.text.trim(),
      start: start,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // وضع التواريخ المختلفة: موعد مستقل لكل تاريخ.
    if (_customMode) {
      if (_customDates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('ضيف تاريخ واحد على الأقل', 'Add at least one date'))));
        return;
      }
      final repo = AppointmentsRepo();
      for (final when in _customDates) {
        await repo.save(Appointment(
          title: _title.text.trim(),
          category: _category,
          when: when,
          notes: _notes.text.trim(),
          remindBeforeMin: _remind,
          travelMin: (parseNumber(_travel.text) ?? 0).round(),
          location: _location.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اختار اليوم والساعة الأول',
              'Pick the day and time first'))));
      return;
    }
    final when = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour,
        _time!.minute);
    await AppointmentsRepo().save(Appointment(
      id: widget.appointment?.id,
      title: _title.text.trim(),
      category: _category,
      when: when,
      notes: _notes.text.trim(),
      remindBeforeMin: _remind,
      done: widget.appointment?.done ?? false,
      travelMin: (parseNumber(_travel.text) ?? 0).round(),
      repeat: _repeat,
      location: _location.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.appointment == null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isNew
              ? tr('موعد جديد', 'New appointment')
              : tr('تعديل موعد', 'Edit appointment')),
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
            if (isNew) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tr('قوالب سريعة', 'Quick templates'),
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in kApptTemplates)
                    ActionChip(
                      avatar: const Icon(Icons.bolt, size: 16),
                      label: Text(apptTemplateLabel(t.key)),
                      onPressed: () => _applyTemplate(t),
                    ),
                  // قوالب المستخدم الخاصة — ضغطة تملأ العنوان،
                  // وضغطة مطوَّلة تحذف القالب
                  for (final t in _customTemplates)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onLongPress: () => _deleteCustomTemplate(t),
                      child: ActionChip(
                        avatar: const Icon(Icons.push_pin_outlined, size: 16),
                        label: Text(t),
                        onPressed: () => setState(() => _title.text = t),
                      ),
                    ),
                  // «+» لإضافة بند جديد للقوالب
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(tr('إضافة', 'Add')),
                    onPressed: _addCustomTemplate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: tr('عنوان التذكير', 'Reminder title')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr('اكتب عنوان التذكير', 'Enter a title')
                  : null,
            ),
            const SizedBox(height: 16),
            // «النوع» أُلغى من الفورم بطلب المستخدم — التصنيف بيتحدد من
            // القوالب أو بيفضل زى ما هو عند التعديل (بيتخزن عادى).
            if (isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('مواعيد بتواريخ مختلفة',
                    'Multiple different dates')),
                subtitle: Text(tr('لو المواعيد مش منتظمة — ضيف كل تاريخ ووقته',
                    'For irregular dates — add each date & time')),
                value: _customMode,
                onChanged: (v) => setState(() => _customMode = v),
              ),
            if (!_customMode) ...[
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: tr('اليوم', 'Day')),
                        child: Text(_date == null
                            ? tr('اختار اليوم', 'Pick day')
                            : arShortDate(_date!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: tr('الساعة', 'Time')),
                        child: Text(_time == null
                            ? tr('اختار الساعة', 'Pick time')
                            : arTime(DateTime(2000, 1, 1, _time!.hour,
                                _time!.minute))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_customMode) ...[
              InputDecorator(
                decoration:
                    InputDecoration(labelText: tr('التواريخ', 'Dates')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_customDates.isEmpty)
                      Text(tr('مفيش تواريخ لسه', 'No dates yet'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline)),
                    for (final dt in _customDates)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.event, size: 20),
                        title: Text('${arShortDate(dt)} — ${arTime(dt)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _customDates.remove(dt)),
                        ),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _addCustomDate,
                        icon: const Icon(Icons.add),
                        label: Text(tr('أضف تاريخ ووقت', 'Add date & time')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<int>(
              initialValue: _remind,
              decoration: InputDecoration(labelText: tr('فكرني', 'Remind me')),
              items: [
                for (final e in remindOptions().entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _remind = v ?? _remind),
            ),
            const SizedBox(height: 16),
            if (!_customMode) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tr('التكرار', 'Repeat'),
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in kRepeatModes)
                    ChoiceChip(
                      label: Text(repeatLabel(r)),
                      selected: _repeat == r,
                      onSelected: (_) => setState(() => _repeat = r),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _travel,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: tr('مدة المشوار (دقايق) — تنبيه «اتحرك دلوقتي»',
                      'Travel time (min) — "leave now" alert'),
                  helperText: tr('سيبها فاضية لو الموعد في نفس المكان',
                      'Leave empty if no travel needed')),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(
                labelText: tr('المكان (اختياري)', 'Location (optional)'),
                helperText: tr('اسم المكان أو العنوان — يفتح فى الخرائط',
                    'Place name or address — opens in Maps'),
                suffixIcon: IconButton(
                  tooltip: tr('افتح فى الخرائط', 'Open in Maps'),
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _openMaps,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: tr('ملاحظات (اختياري)', 'Notes (optional)')),
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
