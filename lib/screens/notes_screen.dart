import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/note_reminders_repo.dart';
import '../data/notes_repo.dart';
import '../widgets/common.dart';
import '../widgets/quick_add_field.dart';
import 'note_reminder_sheet.dart';
import 'voice/dictation_sheet.dart';

/// «تذكيراتى» — ملاحظات حرّة تكتبها بسرعة وتلاقيها. المثبّت فوق.
class NotesScreen extends StatefulWidget {
  final Widget? drawer;
  const NotesScreen({super.key, this.drawer});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = NotesRepo();
  final _reminders = NoteRemindersRepo();
  bool _loading = true;
  List<Note> _notes = [];
  Map<int, NoteReminder> _rem = {};
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _repo.all(search: _search);
    final rem = await _reminders.byNote();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _rem = rem;
      _loading = false;
    });
  }

  /// ضبط/تعديل/شيل تذكير للملاحظة (بمنبّه صوتى أو تنبيه عادى).
  Future<void> _setReminder(Note n) async {
    final res = await showNoteReminderSheet(context,
        noteId: n.id!, existing: _rem[n.id]);
    if (res == null) return;
    if (res is ReminderRemoved) {
      await _reminders.removeFor(n.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتشال التذكير', 'Reminder removed'))));
    } else if (res is NoteReminder) {
      await _reminders.setFor(res, n.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتظبط التذكير ⏰', 'Reminder set ⏰'))));
    }
    await _load();
  }

  Future<void> _add(String text) async {
    if (text.trim().isEmpty) return;
    await _repo.add(text);
    await _load();
  }

  /// إضافة ملاحظة بالصوت — بتتكلم، الكلام يتحوّل نص، وتقدر تعدّله قبل الحفظ.
  Future<void> _addByVoice() async {
    final text = await showDictationSheet(
      context,
      title: tr('ملاحظة بصوتك', 'Note by voice'),
    );
    if (text == null || text.trim().isEmpty) return;
    await _repo.add(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('اتسجّلت الملاحظة 🎙', 'Note saved 🎙'))));
    await _load();
  }

  Future<void> _edit(Note note) async {
    final ctrl = TextEditingController(text: note.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('تعديل الملاحظة', 'Edit note')),
        content: StatefulBuilder(
          builder: (ctx, setDialog) => TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: tr('اكتب…', 'Write…'),
              // إملاء صوتى يكمّل على النص الموجود.
              suffixIcon: IconButton(
                tooltip: tr('أكمل بصوتك', 'Continue by voice'),
                icon: const Icon(Icons.mic),
                onPressed: () async {
                  final said = await showDictationSheet(ctx,
                      initial: ctrl.text,
                      title: tr('أكمل بصوتك', 'Continue by voice'));
                  if (said != null) setDialog(() => ctrl.text = said);
                },
              ),
            ),
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
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await _repo.update(note.id!, ctrl.text);
      await _load();
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('تذكيراتى', 'My notes')),
        actions: [
          IconButton(
            tooltip: tr('ملاحظة بصوتك', 'Note by voice'),
            icon: const Icon(Icons.mic_none),
            onPressed: _addByVoice,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: QuickAddField(
                    label: tr('اكتب تذكرة أو ملاحظة…', 'Write a note…'),
                    onSubmit: _add,
                  ),
                ),
                const SizedBox(width: 8),
                // زر الإملاء الصوتى جنب خانة الكتابة.
                Material(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _addByVoice,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.mic,
                          color: scheme.onPrimaryContainer, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: tr('ابحث فى ملاحظاتك…', 'Search notes…'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                _search = v;
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(children: [
                          const SizedBox(height: 60),
                          EmptyHint(
                            icon: Icons.sticky_note_2_outlined,
                            text: _search.isNotEmpty
                                ? tr('مفيش نتائج', 'No matches')
                                : tr('اكتب أى تذكرة أو فكرة تحب تفتكرها',
                                    'Jot any note or reminder you want to keep'),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: _notes.length,
                          itemBuilder: (_, i) => _card(_notes[i], scheme),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// شارة التذكير تحت الملاحظة: الميعاد + التكرار + نوع الرنين.
  Widget _reminderChip(NoteReminder r, ColorScheme scheme) {
    final t = r.time;
    final past = r.repeat == NoteRepeat.once &&
        t != null &&
        t.isBefore(DateTime.now());
    final label = t == null
        ? ''
        : switch (r.repeat) {
            NoteRepeat.daily =>
              tr('كل يوم ${arTime(t)}', 'Daily ${arTime(t)}'),
            NoteRepeat.weekly => tr('كل ${arWeekday(t)} ${arTime(t)}',
                'Weekly ${arWeekday(t)} ${arTime(t)}'),
            NoteRepeat.once => '${arShortDate(t)} · ${arTime(t)}',
          };
    final color = past ? scheme.outline : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(r.alarm ? Icons.alarm : Icons.notifications_none,
            size: 12, color: color),
        const SizedBox(width: 4),
        Text(past ? tr('فات · $label', 'Passed · $label') : label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _card(Note n, ColorScheme scheme) {
    final date = DateTime.tryParse(n.updatedAt);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: n.pinned ? scheme.tertiaryContainer.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: () => _edit(n),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.pinned)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 6),
                      child: Icon(Icons.push_pin,
                          size: 16, color: scheme.tertiary),
                    ),
                  Expanded(
                    child: Text(n.text,
                        style: const TextStyle(fontSize: 15, height: 1.4)),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'remind':
                          await _setReminder(n);
                        case 'edit':
                          await _edit(n);
                        case 'pin':
                          await _repo.setPinned(n.id!, !n.pinned);
                          await _load();
                        case 'delete':
                          if (!await confirmDelete(
                              context, tr('الملاحظة', 'this note'))) {
                            return;
                          }
                          await _repo.delete(n.id!);
                          if (mounted) await _load();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'remind',
                          child: Text(_rem.containsKey(n.id)
                              ? tr('عدّل التذكير ⏰', 'Edit reminder ⏰')
                              : tr('ذكّرنى ⏰', 'Remind me ⏰'))),
                      PopupMenuItem(
                          value: 'pin',
                          child: Text(n.pinned
                              ? tr('إلغاء التثبيت', 'Unpin')
                              : tr('تثبيت فوق', 'Pin to top'))),
                      PopupMenuItem(
                          value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                      PopupMenuItem(
                          value: 'delete', child: Text(tr('حذف', 'Delete'))),
                    ],
                  ),
                ],
              ),
              Row(children: [
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: Text(arShortDate(date),
                        style: TextStyle(fontSize: 11, color: scheme.outline)),
                  ),
                if (_rem[n.id] != null) ...[
                  const SizedBox(width: 8),
                  _reminderChip(_rem[n.id]!, scheme),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
