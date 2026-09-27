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
  Map<int, NoteReminder> _rem = {};
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
    final pinned = _notes.where((n) => n.pinned).toList();
    final rest = _notes.where((n) => !n.pinned).toList();
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
                    AppHero(
                      icon: Icons.edit_note,
                      kicker: tr('اكتب بسرعة', 'Quick capture'),
                      title: tr('إيه اللى فى دماغك؟', 'What is on your mind?'),
                      primaryLabel: tr('اكتب', 'Write'),
                      primaryIcon: Icons.edit,
                      onPrimary: () => _edit(null),
                      secondaryLabel: tr('سجّل بصوتك', 'By voice'),
                      onSecondary: _addByVoice,
                    ),
                    top: 12,
                  ),
                  AppPad(
                    TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: tr('ابحث فى ملاحظاتك…', 'Search notes…'),
                      ),
                      onChanged: (v) {
                        _search = v;
                        _load();
                      },
                    ),
                    top: 18,
                    bottom: 18,
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
                  if (pinned.isNotEmpty) ...[
                    AppPad(AppSectionTitle(tr('مثبّتة', 'Pinned'))),
                    AppPad(AppCard(Column(children: [
                      for (var i = 0; i < pinned.length; i++)
                        _row(pinned[i], scheme, last: i == pinned.length - 1),
                    ]))),
                    const SizedBox(height: 18),
                  ],
                  if (rest.isNotEmpty) ...[
                    AppPad(AppSectionTitle(
                        pinned.isEmpty
                            ? tr('ملاحظاتك', 'Your notes')
                            : tr('كل الملاحظات', 'All notes'),
                        trailing:
                            tr('${rest.length} ملاحظة', '${rest.length} notes'))),
                    AppPad(AppCard(Column(children: [
                      for (var i = 0; i < rest.length; i++)
                        _row(rest[i], scheme, last: i == rest.length - 1),
                    ]))),
                  ],
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
              await _setReminder(n);
            case 'memo':
              await _recordMemo(n);
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
              child: Text(_rem.containsKey(n.id)
                  ? tr('عدّل التذكير ⏰', 'Edit reminder ⏰')
                  : tr('ذكّرنى ⏰', 'Remind me ⏰'))),
          PopupMenuItem(
              value: 'memo',
              child: Text(_memo.containsKey(n.id)
                  ? tr('المذكرة الصوتية 🎙', 'Voice memo 🎙')
                  : tr('سجّل مذكرة صوتية 🎙', 'Record voice memo 🎙'))),
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
      if (_rem[n.id] != null) _reminderChip(_rem[n.id]!, scheme),
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
