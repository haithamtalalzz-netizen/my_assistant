import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/memorization_repo.dart';
import '../../widgets/common.dart';
import '../../widgets/quick_add_field.dart';

/// «حفظ ومراجعة القرآن» بالتكرار المتباعد — ضيف سورة/صفحة، وراجعها لما تستحق؛
/// المراجعة الناجحة بتباعد الموعد، والضعيفة بترجّعها لأول الصف.
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  final _repo = MemorizationRepo();
  bool _loading = true;
  List<MemorizationItem> _all = [];
  List<MemorizationItem> _due = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.all();
    final due = await _repo.due();
    if (!mounted) return;
    setState(() {
      _all = all;
      _due = due;
      _loading = false;
    });
  }

  Future<void> _review(MemorizationItem it, bool ok) async {
    if (it.id == null) return;
    await _repo.review(it.id!, ok);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(ok
          ? tr('أحسنت — بعّدنا موعد المراجعة', 'Nice — review spaced out')
          : tr('هنراجعها بكرة تانى', "We'll review it again tomorrow")),
    ));
    await _load();
  }

  String _levelText(int box) => tr(
      'كل ${arNum(MemorizationRepo.intervalForBox(box))} يوم',
      'every ${arNum(MemorizationRepo.intervalForBox(box))}d');

  String _nextText(MemorizationItem it) {
    if (it.dueBy(DateTime.now())) return tr('مستحقة', 'Due');
    final d = DateTime.tryParse(it.nextReview);
    return d != null ? '${tr('المراجعة', 'Review')} ${arShortDate(d)}' : '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('حفظ ومراجعة القرآن', 'Memorization'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: QuickAddField(
            label: tr('ضيف سورة أو صفحة للحفظ', 'Add a surah or page'),
            emptyHint: tr('اكتب اسم السورة أو رقم الصفحة',
                'Type a surah name or page number'),
            onSubmit: (t) async {
              await _repo.add(t);
              await _load();
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_all.isEmpty
                  ? EmptyHint(
                      icon: Icons.menu_book_outlined,
                      text: tr(
                          'ابدأ خطة حفظك — ضيف أول سورة أو صفحة فوق، وهنفكّرك تراجعها بالتكرار المتباعد.',
                          'Start your plan — add your first surah or page above and we\'ll space out the reviews.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: [
                        if (_due.isNotEmpty) ...[
                          _header(scheme,
                              '${tr('محتاج مراجعة النهاردة', 'Due today')} (${arNum(_due.length)})',
                              scheme.primary),
                          for (final it in _due) _dueCard(scheme, it),
                          const SizedBox(height: 8),
                        ],
                        _header(
                            scheme,
                            '${tr('كل المحفوظات', 'All items')} (${arNum(_all.length)})',
                            scheme.onSurfaceVariant),
                        for (final it in _all) _allRow(scheme, it),
                      ],
                    )),
        ),
      ]),
    );
  }

  Widget _header(ColorScheme scheme, String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8, right: 2, left: 2),
        child: Text(text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      );

  Widget _dueCard(ColorScheme scheme, MemorizationItem it) {
    const green = Color(0xFF16A34A);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 2),
          Text(_levelText(it.box),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: green),
                onPressed: () => _review(it, true),
                icon: const Icon(Icons.check, size: 18),
                label: Text(tr('تمام', 'Good')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _review(it, false),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(tr('محتاج مراجعة', 'Weak')),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _allRow(ColorScheme scheme, MemorizationItem it) {
    final due = it.dueBy(DateTime.now());
    return SwipeToDelete(
      id: it.id ?? it.label,
      onDelete: () async {
        if (it.id != null) await _repo.delete(it.id!);
        await _load();
      },
      onUndo: () async {
        await _repo.add(it.label, notes: it.notes);
        await _load();
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(arNum(it.box + 1),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
          ),
          title: Text(it.label),
          subtitle: Text('${_levelText(it.box)} • ${_nextText(it)}'),
          trailing: due
              ? Icon(Icons.notifications_active, color: scheme.primary, size: 20)
              : null,
        ),
      ),
    );
  }
}
