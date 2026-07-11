import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/diaries_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _repo = DiariesRepo();
  bool _loading = true;
  List<Diary> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const _DiaryEditor()));
    if (saved == true && mounted) await _load();
  }

  Widget _header(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final last = DateTime.tryParse(_items.first.day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Row(children: [
        Icon(Icons.auto_stories_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
            tr('${arNum(_items.length)} يومية${last == null ? '' : ' • آخر كتابة ${arShortDate(last)}'}',
                '${arNum(_items.length)} entries${last == null ? '' : ' • last ${arShortDate(last)}'}'),
            style: TextStyle(color: scheme.outline, fontSize: 13)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('اليوميات', 'Diary')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.auto_stories_outlined,
                  actionLabel: tr('اكتب يومية', 'Write entry'),
                  onAction: _add,
                  text: tr('اكتب أو احكي دقيقة عن يومك — بعد فترة يبقى أرشيف لحياتك',
                      'Write or speak a minute about your day — a life archive over time'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == 0) return _header(context);
                      final d = _items[idx - 1];
                      return SwipeToDelete(
                        id: d.id!,
                        undoLabel: tr('اتمسحت اليومية', 'Entry deleted'),
                        onDelete: () async {
                          await _repo.delete(d.id!);
                          if (mounted) await _load();
                        },
                        onUndo: () async {
                          await _repo.add(d);
                          if (mounted) await _load();
                        },
                        child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          title: Text(arFullDate(DateTime.parse(d.day)),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(d.text,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () async {
                              if (!await confirmDelete(
                                  context, tr('اليومية دي', 'this entry'))) {
                                return;
                              }
                              await _repo.delete(d.id!);
                              if (mounted) await _load();
                            },
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'diary_fab',
        onPressed: _add,
        tooltip: tr('يومية جديدة', 'New entry'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DiaryEditor extends StatefulWidget {
  const _DiaryEditor();

  @override
  State<_DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends State<_DiaryEditor> {
  final _text = TextEditingController();
  final _stt = SpeechToText();
  bool _listening = false;
  String _base = '';

  @override
  void dispose() {
    _stt.stop();
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _stt.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('الميكروفون مش متاح', 'Mic unavailable'))));
      }
      return;
    }
    _base = _text.text.isEmpty ? '' : '${_text.text} ';
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions:
          SpeechListenOptions(partialResults: true, localeId: 'ar_EG'),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _text.text = '$_base${r.recognizedWords}');
      },
    );
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    await DiariesRepo().add(Diary(
      day: dayKey(DateTime.now()),
      text: _text.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('يومية النهارده', "Today's entry")),
        actions: [
          IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: tr('حفظ', 'Save')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: tr('اكتب أو دوس المايك واحكي عن يومك...',
                      'Write, or tap the mic and talk about your day...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _toggleMic,
              icon: Icon(_listening ? Icons.stop : Icons.mic,
                  color: _listening ? scheme.error : null),
              label: Text(_listening
                  ? tr('بسمع... دوس توقف', 'Listening... tap to stop')
                  : tr('احكي بصوتك', 'Dictate')),
            ),
          ],
        ),
      ),
    );
  }
}
