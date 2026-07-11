import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/quit_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class QuitScreen extends StatefulWidget {
  const QuitScreen({super.key});

  @override
  State<QuitScreen> createState() => _QuitScreenState();
}

class _QuitScreenState extends State<QuitScreen> {
  final _repo = QuitRepo();
  bool _loading = true;
  List<QuitCounter> _items = [];

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
    final name = TextEditingController();
    final saving = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          scrollable: true,
        title: Text(tr('حاجة بطّلتها', 'Something you quit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: tr('إيه اللي بطّلته؟ (مثلًا: سجائر)',
                      'What did you quit? (e.g. cigarettes)')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('التوفير اليومي (ج.م، اختياري)',
                      'Daily saving (EGP, optional)')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('ابدأ العدّاد', 'Start counter'))),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.add(QuitCounter(
        name: name.text.trim(),
        startDate: dayKey(DateTime.now()),
        dailySaving: parseNumber(saving.text) ?? 0,
      ));
      if (mounted) await _load();
    }
    name.dispose();
    saving.dispose();
  }

  /// شريط تقدّم نحو أقرب محطة (أسبوع/شهر/٣ شهور/٦/سنة/سنتين).
  Widget _milestone(BuildContext context, int days) {
    const marks = [
      (7, 'أسبوع', '1 week'),
      (30, 'شهر', '1 month'),
      (90, '٣ شهور', '3 months'),
      (180, '٦ شهور', '6 months'),
      (365, 'سنة', '1 year'),
      (730, 'سنتين', '2 years'),
    ];
    (int, String, String)? next;
    var prev = 0;
    for (final m in marks) {
      if (days < m.$1) {
        next = m;
        break;
      }
      prev = m.$1;
    }
    if (next == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final remaining = next.$1 - days;
    final progress = (days - prev) / (next.$1 - prev);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.onPrimaryContainer.withValues(alpha: .2),
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
              tr('فاضل ${arNum(remaining)} يوم على ${next.$2}',
                  '${arNum(remaining)} days to ${next.$3}'),
              style: TextStyle(
                  fontSize: 12, color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('عدّاد الإقلاع', 'Quit counter')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.emoji_events_outlined,
                  actionLabel: tr('ابدأ عدّاد', 'Start counter'),
                  onAction: _add,
                  text: tr('بطّلت حاجة؟ ابدأ عدّاد وشوف بقالك كام يوم وفّرت كام',
                      'Quit something? Start a counter — see your streak & savings'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    final days = c.daysSince(now);
                    final saved = c.savedSoFar(now);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: scheme.onPrimaryContainer)),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'reset') {
                                      await _repo.reset(c.id!);
                                      if (mounted) await _load();
                                    } else if (v == 'delete') {
                                      if (!await confirmDelete(context,
                                          tr('«${c.name}»', '"${c.name}"'))) {
                                        return;
                                      }
                                      await _repo.delete(c.id!);
                                      if (mounted) await _load();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        value: 'reset',
                                        child: Text(tr('ابدأ من جديد', 'Restart'))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text(tr('حذف', 'Delete'))),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                                tr('بقالك ${arNum(days)} يوم 🎉',
                                    '${arNum(days)} days 🎉'),
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer)),
                            if (c.dailySaving > 0)
                              Text(
                                  tr('وفّرت حوالي ${egp(saved)}',
                                      'Saved about ${egp(saved)}'),
                                  style: TextStyle(
                                      color: scheme.onPrimaryContainer)),
                            _milestone(context, days),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'quit_fab',
        onPressed: _add,
        tooltip: tr('عدّاد جديد', 'New counter'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
