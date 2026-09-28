import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/note_reminders_repo.dart';
import '../data/notes_repo.dart';
import '../data/voice_memos_repo.dart';
import '../widgets/a_kit.dart';
import '../widgets/common.dart';
import 'note_reminder_sheet.dart';
import 'voice/dictation_sheet.dart';
import 'voice/voice_memo_sheet.dart';

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
  final _memos = VoiceMemosRepo();
  bool _loading = true;
  List<Note> _notes = [];
  /// تذكيرات كل ملاحظة (ممكن أكتر من واحد).
  Map<int, List<NoteReminder>> _rem = {};
  Map<int, VoiceMemo> _memo = {};
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _repo.all(search: _search);
    final rem = await _reminders.byNote();
    final memos = await _memos.byNote();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _rem = rem;
      _memo = memos;
      _loading = false;
    });
  }

  /// ضبط/تعديل/شيل تذكير. [existing] = null يعنى **تذكير جديد** (ملاحظة
  /// واحدة ممكن يكون عليها أكتر من تذكير — مثلاً فكّرنى الصبح وتانى بالليل).
  Future<void> _setReminder(Note n, {NoteReminder? existing}) async {
    var slot = existing?.slot;
    if (slot == null) {
      slot = await _reminders.freeSlot(n.id!);
      if (slot == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('وصلت أقصى عدد تذكيرات للملاحظة دى',
                'Max reminders reached for this note'))));
        return;
      }
    }
    if (!mounted) return;
    final res = await showNoteReminderSheet(context,
        noteId: n.id!, existing: existing);
    if (res == null) return;
    if (res is ReminderRemoved) {
      await _reminders.removeOne(n.id!, slot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتشال التذكير', 'Reminder removed'))));
    } else if (res is NoteReminder) {
      await _reminders.setFor(
          NoteReminder(
            noteId: res.noteId,
            slot: slot,
            at: res.at,
            repeat: res.repeat,
            alarm: res.alarm,
            soundUri: res.soundUri,
            soundChannel: res.soundChannel,
            soundLabel: res.soundLabel,
          ),
          n.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتظبط التذكير ⏰', 'Reminder set ⏰'))));
    }
    await _load();
  }

  /// قايمة تذكيرات الملاحظة — تعديل واحد أو إضافة جديد.
  Future<void> _remindersSheet(Note n) async {
    final list = _rem[n.id] ?? const <NoteReminder>[];
    if (list.isEmpty) {
      await _setReminder(n);
      return;
    }
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final r in list)
            ListTile(
              leading: Icon(r.alarm ? Icons.alarm : Icons.notifications_none,
                  color: scheme.primary),
              title: Text(_reminderText(r)),
              onTap: () {
                Navigator.pop(ctx);
                _setReminder(n, existing: r);
              },
            ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.add_alarm, color: scheme.primary),
            title: Text(tr('تذكير تانى', 'Another reminder')),
            onTap: () {
              Navigator.pop(ctx);
              _setReminder(n);
            },
          ),
        ]),
      ),
    );
  }

  /// نص مختصر للتذكير (الميعاد + التكرار).
  String _reminderText(NoteReminder r) {
    final t = r.time;
    final when = t == null ? '' : '${arShortDate(t)} • ${arTime(t)}';
    final rep = switch (r.repeat) {
      NoteRepeat.daily => tr(' • يوميًا', ' • daily'),
      NoteRepeat.weekly => tr(' • أسبوعيًا', ' • weekly'),
      NoteRepeat.once => '',
    };
    return '$when$rep';
  }

  /// **تفريغ المذكرة نصًا** — الصوت نفسه مش قابل للبحث، فالنص بيخلّيك
  /// تلاقيها. بيتكتب بالإيد أو بالإملاء (سماعة المذكرة شغّالة جنبه).
  ///
  /// ليه مش تفريغ تلقائى: محرّك النطق المتاح بيفرّغ **من الميكروفون
  /// مباشرة** مش من ملف محفوظ، وتشغيل الاتنين مع بعض مش مضمون.
  Future<void> _memoText(Note n) async {
    final memo = _memo[n.id];
    if (memo == null) return;
    final ctrl = TextEditingController(text: memo.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('تفريغ المذكرة', 'Transcript')),
        content: StatefulBuilder(
          builder: (ctx, setDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceMemoChip(memo: memo),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: null,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: tr('اكتب اللى فى المذكرة…', 'Type what it says…'),
                  suffixIcon: IconButton(
                    tooltip: tr('اكتب بصوتك', 'By voice'),
                    icon: const Icon(Icons.mic),
                    onPressed: () async {
                      final said = await showDictationSheet(ctx,
                          initial: ctrl.text,
                          title: tr('فرّغ بصوتك', 'Dictate transcript'));
                      if (said != null) setDialog(() => ctrl.text = said);
                    },
                  ),
                ),
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
    );
    if (ok == true) {
      await _memos.setText(n.id!, ctrl.text);
      await _load();
    }
  }

  /// تسجيل/تشغيل/مسح مذكرة صوتية مرفقة بالملاحظة.
  Future<void> _recordMemo(Note n) async {
    final res = await showVoiceMemoSheet(context,
        noteId: n.id!, existing: _memo[n.id]);
    if (res == null) return;
    if (res is MemoRemoved) {
      await _memos.removeFor(n.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتمسحت المذكرة', 'Memo deleted'))));
    } else if (res is VoiceMemo) {
      await _memos.setFor(res);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتحفظت المذكرة 🎙', 'Memo saved 🎙'))));
    }
    await _load();
  }

  /// حذف ملاحظة **مع** ما يخصّها: إلغاء المنبّه المجدول ومسح ملف المذكرة
  /// الصوتية. من غير ده المنبّه كان يفضل مجدول فى النظام ويرنّ بنص ملاحظة
  /// اتمسحت (لحد ما التطبيق يتفتح من جديد وينضّف).
  Future<void> _deleteNote(Note n) async {
    await _reminders.removeFor(n.id!);
    await _memos.removeFor(n.id!);
    await _repo.delete(n.id!);
    if (mounted) await _load();
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

  /// حوار الكتابة — بيخدم التعديل **والإضافة** (note == null).
  Future<void> _edit(Note? note) async {
    final ctrl = TextEditingController(text: note?.text ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null
            ? tr('ملاحظة جديدة', 'New note')
            : tr('تعديل الملاحظة', 'Edit note')),
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
      if (note == null) {
        await _repo.add(ctrl.text);
      } else {
        await _repo.update(note.id!, ctrl.text);
      }
      await _load();
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // التقسيم بقى بالمعنى: اللى عليه منبّه أهم حاجة تشوفها، بعده
    // المثبّت، وبعده الباقى — بدل «مثبّتة/كل الملاحظات» اللى كانت
    // بتخبّى المنبّهات وسط الكلام.
    bool hasAlarm(Note n) => (_rem[n.id] ?? const <NoteReminder>[]).isNotEmpty;
    final alarmed = _notes.where(hasAlarm).toList();
    final pinned = _notes.where((n) => n.pinned && !hasAlarm(n)).toList();
    final rest =
        _notes.where((n) => !n.pinned && !hasAlarm(n)).toList();
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () => _edit(null),
        tooltip: tr('ملاحظة جديدة', 'New note'),
        child: const Icon(Icons.edit),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  AppPad(
                    TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: tr('دوّر فى التذكيرات…', 'Search notes…'),
                      ),
                      onChanged: (v) {
                        _search = v;
                        _load();
                      },
                    ),
                    top: 12,
                    bottom: 4,
                  ),
                  if (_notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: EmptyHint(
                        icon: Icons.sticky_note_2_outlined,
                        text: _search.isNotEmpty
                            ? tr('مفيش نتائج', 'No matches')
                            : tr('اكتب أى تذكرة أو فكرة تحب تفتكرها',
                                'Jot any note or reminder you want to keep'),
                        actionLabel: _search.isEmpty
                            ? tr('اكتب أول ملاحظة', 'Write your first note')
                            : null,
                        onAction: () => _edit(null),
                      ),
                    ),
                  if (alarmed.isNotEmpty) ...[
                    AppPad(AppGroupHead(tr('عليها منبّه', 'With a reminder'),
                        trail: arNum(alarmed.length))),
                    for (var i = 0; i < alarmed.length; i++)
                      AppPad(_row(alarmed[i], scheme,
                          last: i == alarmed.length - 1)),
                  ],
                  if (pinned.isNotEmpty) ...[
                    AppPad(AppGroupHead(tr('مثبّتة', 'Pinned'),
                        trail: arNum(pinned.length))),
                    for (var i = 0; i < pinned.length; i++)
                      AppPad(
                          _row(pinned[i], scheme, last: i == pinned.length - 1)),
                  ],
                  if (rest.isNotEmpty) ...[
                    AppPad(AppGroupHead(tr('من غير منبّه', 'No reminder'),
                        trail: arNum(rest.length))),
                    for (var i = 0; i < rest.length; i++)
                      AppPad(_row(rest[i], scheme, last: i == rest.length - 1)),
                  ],
                  const SizedBox(height: 18),
                ],
              ),
            ),
    );
  }

  /// قايمة الإجراءات (⋮) — نفس البنود القديمة بالظبط.
  Widget _menu(Note n) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (v) async {
          switch (v) {
            case 'remind':
              await _remindersSheet(n);
            case 'memo':
              await _recordMemo(n);
            case 'memo_text':
              await _memoText(n);
            case 'edit':
              await _edit(n);
            case 'pin':
              await _repo.setPinned(n.id!, !n.pinned);
              await _load();
            case 'delete':
              if (!await confirmDelete(context, tr('الملاحظة', 'this note'))) {
                return;
              }
              await _deleteNote(n);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
              value: 'remind',
              child: Text((_rem[n.id] ?? const []).isEmpty
                  ? tr('ذكّرنى ⏰', 'Remind me ⏰')
                  : tr('التذكيرات (${arNum(_rem[n.id]!.length)}) ⏰',
                      'Reminders (${arNum(_rem[n.id]!.length)}) ⏰'))),
          PopupMenuItem(
              value: 'memo',
              child: Text(_memo.containsKey(n.id)
                  ? tr('المذكرة الصوتية 🎙', 'Voice memo 🎙')
                  : tr('سجّل مذكرة صوتية 🎙', 'Record voice memo 🎙'))),
          if (_memo[n.id] != null)
            PopupMenuItem(
                value: 'memo_text',
                child: Text((_memo[n.id]!.text).isEmpty
                    ? tr('فرّغ المذكرة نصًا 📝', 'Transcribe memo 📝')
                    : tr('عدّل تفريغ المذكرة 📝', 'Edit transcript 📝'))),
          PopupMenuItem(
              value: 'pin',
              child: Text(n.pinned
                  ? tr('إلغاء التثبيت', 'Unpin')
                  : tr('تثبيت فوق', 'Pin to top'))),
          PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
          PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
        ],
      );

  /// سطر ملاحظة جوّه كارت القسم.
  Widget _row(Note n, ColorScheme scheme, {bool last = false}) {
    final date = DateTime.tryParse(n.updatedAt);
    final chips = <Widget>[
      if (date != null)
        Text(arShortDate(date),
            style: TextStyle(fontSize: 11, color: scheme.outline)),
      for (final r in _rem[n.id] ?? const <NoteReminder>[])
        _reminderChip(r, scheme),
      if ((_memo[n.id]?.text ?? '').isNotEmpty)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mic, size: 12, color: scheme.outline),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(_memo[n.id]!.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.outline)),
          ),
        ]),
      if (_memo[n.id] != null) VoiceMemoChip(memo: _memo[n.id]!),
    ];
    return InkWell(
      onTap: () => _edit(n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.7)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: (n.pinned ? scheme.tertiary : scheme.primary)
                    .withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(n.pinned ? Icons.push_pin : Icons.sticky_note_2_outlined,
                size: 18, color: n.pinned ? scheme.tertiary : scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600)),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(spacing: 8, runSpacing: 4, children: chips),
                  ],
                ]),
          ),
          _menu(n),
        ]),
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

}
