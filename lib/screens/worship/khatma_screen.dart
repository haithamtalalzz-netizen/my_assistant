import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/worship_repo.dart';

/// عدّاد ختمة القرآن — تتبّع الورد اليومى وكام يوم تخلّص الختمة.
class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key});

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  final _repo = WorshipRepo();
  Khatma? _k;
  double _avg = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await _repo.activeKhatma();
    final avg = await _repo.khatmaAvgPerDay();
    if (!mounted) return;
    setState(() {
      _k = k;
      _avg = avg;
      _loading = false;
    });
  }

  Future<void> _start(int target) async {
    await _repo.startKhatma(dailyTarget: target);
    await _load();
  }

  Future<void> _logPages(int pages) async {
    await _repo.logKhatmaRead(pages);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('ختمة القرآن', 'Quran khatma')),
        actions: [
          if (_k != null)
            IconButton(
              tooltip: tr('ختمة جديدة', 'New khatma'),
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(tr('ختمة جديدة؟', 'New khatma?')),
                    content: Text(tr('هيتصفّر التقدّم الحالى.',
                        'Current progress will reset.')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('إلغاء', 'Cancel'))),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr('تأكيد', 'Confirm'))),
                    ],
                  ),
                );
                if (ok == true) {
                  await _repo.resetKhatma();
                  await _load();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _k == null
              ? _startView()
              : _progressView(_k!),
    );
  }

  Widget _startView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(tr('ابدأ ختمة جديدة', 'Start a new khatma'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              tr('اختر وردك اليومى (المصحف ٦٠٤ صفحة = ٣٠ جزء)',
                  'Pick your daily target (Mushaf = 604 pages / 30 juz\')'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _startChip(tr('صفحتين/يوم', '2 pages/day'), 2, '~١٠ شهور'),
                _startChip(tr('٤ صفحات/يوم', '4 pages/day'), 4, '~٥ شهور'),
                _startChip(tr('١٠ صفحات/يوم', '10 pages/day'), 10, '~شهرين'),
                _startChip(tr('جزء/يوم', '1 juz\'/day'), 20, '~شهر'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _startChip(String label, int pages, String hint) => ActionChip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(hint, style: const TextStyle(fontSize: 11)),
          ],
        ),
        onPressed: () => _start(pages),
      );

  Widget _progressView(Khatma k) {
    final scheme = Theme.of(context).colorScheme;
    final juz = (k.currentPage / 20).clamp(0, 30).ceil();
    final days = k.daysToFinish(_avg);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k.done ? tr('تمّت الختمة 🎉', 'Khatma complete 🎉')
                    : tr('تقدّمك فى الختمة', 'Your khatma progress'),
                style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '${arNum(k.currentPage)} / ${arNum(k.totalPages)}',
                style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900),
              ),
              Text(
                tr('صفحة · الجزء ${arNum(juz)} من ٣٠',
                    'pages · Juz\' ${arNum(juz)} of 30'),
                style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: k.progress,
                  minHeight: 10,
                  backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.percent, size: 16, color: scheme.onPrimary),
                  const SizedBox(width: 4),
                  Text('${arNum((k.progress * 100).round())}%',
                      style: TextStyle(
                          color: scheme.onPrimary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (!k.done) ...[
                    Icon(Icons.event_available,
                        size: 16, color: scheme.onPrimary),
                    const SizedBox(width: 4),
                    Text(
                      tr('باقى ~${arNum(days)} يوم', '~${arNum(days)} days left'),
                      style: TextStyle(
                          color: scheme.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!k.done) ...[
          Text(tr('سجّل ورد اليوم', "Log today's reading"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _logChip(tr('صفحة', '1 page'), 1),
              _logChip(tr('صفحتين', '2 pages'), 2),
              _logChip(tr('٤ صفحات', '4 pages'), 4),
              _logChip(tr('نصف جزء', 'Half juz\''), 10),
              _logChip(tr('جزء كامل', 'Full juz\''), 20),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _customPages,
            icon: const Icon(Icons.edit),
            label: Text(tr('عدد صفحات مخصّص', 'Custom pages')),
          ),
        ],
        const SizedBox(height: 16),
        if (_avg > 0)
          Text(
            tr('متوسّط وردك: ${arNum(_avg.toStringAsFixed(1))} صفحة/يوم',
                'Your average: ${arNum(_avg.toStringAsFixed(1))} pages/day'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _logChip(String label, int pages) =>
      ActionChip(label: Text(label), onPressed: () => _logPages(pages));

  Future<void> _customPages() async {
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('كام صفحة قرأت؟', 'How many pages?')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('مثال: ٧', 'e.g. 7')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(ctrl.text.trim()) ?? 0),
              child: Text(tr('سجّل', 'Log'))),
        ],
      ),
    );
    if (n != null && n > 0) await _logPages(n);
  }
}
