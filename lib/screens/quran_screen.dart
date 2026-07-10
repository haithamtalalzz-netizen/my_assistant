import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/quran_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _repo = QuranRepo();
  bool _loading = true;
  List<QuranReview> _items = [];

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
    await _repo.ensureReminder();
  }

  Future<void> _add() async {
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('ورد جديد', 'New portion')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              labelText: tr('السورة/الجزء (مثلًا: البقرة)',
                  'Surah/Juz (e.g. Al-Baqarah)')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('إضافة', 'Add'))),
        ],
      ),
    );
    if (saved == true && ctrl.text.trim().isNotEmpty) {
      await _repo.add(ctrl.text.trim());
      if (mounted) await _load();
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('مراجعة القرآن', 'Quran review')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.menu_book_outlined,
                  text: tr(
                      'ضيف السور اللي حافظها — والتطبيق يذكّرك تراجعها بالتكرار المتباعد',
                      'Add memorized surahs — spaced-repetition reminds you to review'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      final due = r.isDue(now);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: due ? scheme.tertiaryContainer : null,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.menu_book,
                                      color: due
                                          ? scheme.onTertiaryContainer
                                          : scheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(r.portion,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: due
                                                ? scheme.onTertiaryContainer
                                                : null)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: tr('حذف', 'Delete'),
                                    onPressed: () async {
                                      if (!await confirmDelete(context,
                                          tr('«${r.portion}»', '"${r.portion}"'))) {
                                        return;
                                      }
                                      await _repo.delete(r.id!);
                                      if (mounted) await _load();
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                  due
                                      ? tr('مستحقة المراجعة النهارده',
                                          'Due for review today')
                                      : tr('المراجعة الجاية: ${arShortDate(r.nextDue())}',
                                          'Next review: ${arShortDate(r.nextDue())}'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: due
                                          ? scheme.onTertiaryContainer
                                          : scheme.outline)),
                              if (due) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.tonal(
                                        onPressed: () async {
                                          await _repo.markReviewed(r, now: now);
                                          if (mounted) await _load();
                                        },
                                        child: Text(tr('راجعتها ✓', 'Reviewed ✓')),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await _repo.markForgot(r, now: now);
                                          if (mounted) await _load();
                                        },
                                        child: Text(
                                            tr('محتاجة أكتر', 'Need more')),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'quran_fab',
        onPressed: _add,
        tooltip: tr('ورد جديد', 'New portion'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
