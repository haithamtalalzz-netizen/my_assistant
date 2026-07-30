import 'package:flutter/material.dart';

import '../core/adhan_custom.dart';
import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/note_reminders_repo.dart';

/// شيت ضبط تذكير لملاحظة: التاريخ + الوقت + التكرار + نوع الرنين + صوت مخصّص.
/// بيرجّع التذكير بعد الحفظ، أو `_removed` لو المستخدم شال التذكير، أو null.
Future<Object?> showNoteReminderSheet(
  BuildContext context, {
  required int noteId,
  NoteReminder? existing,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ReminderSheet(noteId: noteId, existing: existing),
  );
}

/// إشارة إن المستخدم شال التذكير.
class ReminderRemoved {
  const ReminderRemoved();
}

class _ReminderSheet extends StatefulWidget {
  final int noteId;
  final NoteReminder? existing;
  const _ReminderSheet({required this.noteId, this.existing});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  late NoteRepeat _repeat;
  late bool _alarm;
  String _soundUri = '';
  String _soundChannel = '';
  String _soundLabel = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final t = e?.time ?? DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(t.year, t.month, t.day);
    _time = TimeOfDay(hour: t.hour, minute: t.minute);
    _repeat = e?.repeat ?? NoteRepeat.once;
    _alarm = e?.alarm ?? true;
    _soundUri = e?.soundUri ?? '';
    _soundChannel = e?.soundChannel ?? '';
    _soundLabel = e?.soundLabel ?? '';
  }

  DateTime get _when => DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickSound() async {
    final s = await AdhanCustom.pickSound();
    if (s == null) return;
    setState(() {
      _soundUri = s.uri;
      _soundChannel = s.channel;
      _soundLabel = s.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final past = _repeat == NoteRepeat.once && _when.isBefore(DateTime.now());
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.alarm, color: scheme.primary),
              const SizedBox(width: 8),
              Text(tr('تذكير بالملاحظة', 'Note reminder'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            // التاريخ + الوقت
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(arShortDate(_date)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(arTime(
                      DateTime(2000, 1, 1, _time.hour, _time.minute))),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(tr('التكرار', 'Repeat'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: Text(tr('مرة واحدة', 'Once')),
                selected: _repeat == NoteRepeat.once,
                onSelected: (_) => setState(() => _repeat = NoteRepeat.once),
              ),
              ChoiceChip(
                label: Text(tr('كل يوم', 'Daily')),
                selected: _repeat == NoteRepeat.daily,
                onSelected: (_) => setState(() => _repeat = NoteRepeat.daily),
              ),
              ChoiceChip(
                label: Text(tr('كل أسبوع', 'Weekly')),
                selected: _repeat == NoteRepeat.weekly,
                onSelected: (_) => setState(() => _repeat = NoteRepeat.weekly),
              ),
            ]),
            const SizedBox(height: 14),
            Text(tr('نوع الرنين', 'Alert type'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                avatar: const Icon(Icons.alarm, size: 17),
                label: Text(tr('منبّه قوى', 'Loud alarm')),
                selected: _alarm,
                onSelected: (_) => setState(() => _alarm = true),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.notifications_none, size: 17),
                label: Text(tr('تنبيه عادى', 'Normal')),
                selected: !_alarm,
                onSelected: (_) => setState(() => _alarm = false),
              ),
            ]),
            if (_alarm) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(
                    _soundLabel.isEmpty
                        ? tr('الصوت: نغمة المنبّه الافتراضية',
                            'Sound: default alarm tone')
                        : tr('الصوت: $_soundLabel', 'Sound: $_soundLabel'),
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickSound,
                  icon: const Icon(Icons.library_music_outlined, size: 18),
                  label: Text(_soundLabel.isEmpty
                      ? tr('اختر صوت', 'Pick sound')
                      : tr('غيّر', 'Change')),
                ),
                if (_soundLabel.isNotEmpty)
                  IconButton(
                    tooltip: tr('رجّع الافتراضى', 'Reset'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _soundUri = '';
                      _soundChannel = '';
                      _soundLabel = '';
                    }),
                  ),
              ]),
            ],
            if (past) ...[
              const SizedBox(height: 10),
              Text(
                  tr('الميعاد ده فات — اختر وقتًا جاى.',
                      'That time has passed — pick a future time.'),
                  style: TextStyle(fontSize: 12.5, color: scheme.error)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              if (widget.existing != null)
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, const ReminderRemoved()),
                  icon: Icon(Icons.alarm_off, size: 18, color: scheme.error),
                  label: Text(tr('شيل التذكير', 'Remove'),
                      style: TextStyle(color: scheme.error)),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: past
                    ? null
                    : () => Navigator.pop(
                          context,
                          NoteReminder(
                            noteId: widget.noteId,
                            at: _when.toIso8601String(),
                            repeat: _repeat,
                            alarm: _alarm,
                            soundUri: _soundUri,
                            soundChannel: _soundChannel,
                            soundLabel: _soundLabel,
                          ),
                        ),
                child: Text(tr('حفظ', 'Save')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
