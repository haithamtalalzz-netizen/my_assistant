import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/mood_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// تتبّع المزاج — سجّل مزاجك كل يوم وشوف اتجاهه.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

const _moodEmoji = {1: '😞', 2: '🙁', 3: '😐', 4: '🙂', 5: '😄'};
String _moodLabel(int s) => switch (s) {
      1 => tr('سيئ', 'Awful'),
      2 => tr('مش كويس', 'Bad'),
      3 => tr('عادي', 'Okay'),
      4 => tr('كويس', 'Good'),
      _ => tr('ممتاز', 'Great'),
    };

class _MoodScreenState extends State<MoodScreen> {
  final _repo = MoodRepo();
  bool _loading = true;
  MoodLog? _today;
  List<MoodLog> _history = [];
  double? _avg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await _repo.forDay(dayKey(DateTime.now()));
    final history = await _repo.recent();
    final avg = await _repo.average();
    if (!mounted) return;
    setState(() {
      _today = today;
      _history = history;
      _avg = avg;
      _loading = false;
    });
  }

  Future<void> _set(int score) async {
    await _repo.setToday(score, note: _today?.note ?? '');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('تتبّع المزاج', 'Mood tracker'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(tr('مزاجك النهاردة؟', 'How are you today?'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var s = 1; s <= 5; s++)
                              GestureDetector(
                                onTap: () => _set(s),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _today?.score == s
                                            ? scheme.primaryContainer
                                            : Colors.transparent,
                                      ),
                                      child: Text(_moodEmoji[s]!,
                                          style: const TextStyle(fontSize: 30)),
                                    ),
                                    Text(_moodLabel(s),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: scheme.outline)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_today != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: Text(_today!.note.isEmpty
                                ? tr('ضيف ملاحظة', 'Add a note')
                                : _today!.note),
                            onPressed: _editNote,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_avg != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                        tr('متوسط الشهر: ${_moodEmoji[_avg!.round()]} ${_avg!.toStringAsFixed(1)}/5',
                            'Month avg: ${_moodEmoji[_avg!.round()]} ${_avg!.toStringAsFixed(1)}/5'),
                        style: TextStyle(
                            color: scheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  EmptyHint(
                      icon: Icons.mood,
                      text: tr('سجّل مزاجك كل يوم وهتشوف اتجاهك',
                          'Log daily and watch your trend'))
                else ...[
                  SectionHeader(tr('السجل', 'History')),
                  for (final m in _history) _tile(m, scheme),
                ],
              ],
            ),
    );
  }

  Widget _tile(MoodLog m, ColorScheme scheme) => Card(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          dense: true,
          leading: Text(_moodEmoji[m.score] ?? '😐',
              style: const TextStyle(fontSize: 22)),
          title: Text('${_moodLabel(m.score)}'
              '${m.note.isEmpty ? '' : ' — ${m.note}'}'),
          subtitle: Text(arShortDate(DateTime.parse(m.day)),
              style: TextStyle(fontSize: 11, color: scheme.outline)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await _repo.delete(m.id!);
              await _load();
            },
          ),
        ),
      );

  Future<void> _editNote() async {
    final ctrl = TextEditingController(text: _today?.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('ملاحظة اليوم', "Today's note")),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 2),
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
    if (ok == true && _today != null) {
      await _repo.setToday(_today!.score, note: ctrl.text.trim());
      await _load();
    }
    ctrl.dispose();
  }
}
