import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../core/quran_topics.dart';
import '../../core/religious_stories.dart' show StoryPassage;
import '../../core/tafsir_data.dart';

/// فهرس القرآن الموضوعى + أدعية القرآن — آيات حسب الموضوع بنصّها من المصحف
/// المدمج (Tanzil) مع التفسير الميسّر عند الطلب.
class QuranTopicsScreen extends StatelessWidget {
  const QuranTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('آيات ودعوات', 'Topics & duas')),
          bottom: TabBar(tabs: [
            Tab(text: tr('حسب الموضوع', 'By topic')),
            Tab(text: tr('أدعية القرآن', 'Quran duas')),
          ]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final t in kQuranTopics)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      leading:
                          Text(t.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(t.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          tr('${arNum(t.passages.length)} مقاطع',
                              '${arNum(t.passages.length)} passages'),
                          style:
                              TextStyle(fontSize: 12, color: scheme.outline)),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VersesScreen(
                                  title: t.name, passages: t.passages))),
                    ),
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final d in kQuranDuas)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      leading: const Text('🤲', style: TextStyle(fontSize: 22)),
                      title: Text(d.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VersesScreen(
                                  title: d.title, passages: [d.passage]))),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// عارض آيات لمجموعة مقاطع — نص الآيات + التفسير الميسّر عند الطلب + مشاركة.
class VersesScreen extends StatefulWidget {
  final String title;
  final List<StoryPassage> passages;
  const VersesScreen({super.key, required this.title, required this.passages});

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  List<({String surah, List<({int n, String text})> verses})>? _data;
  final Set<int> _tafsir = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <({String surah, List<({int n, String text})> verses})>[];
    for (final p in widget.passages) {
      final s = await QuranData.surah(p.surah);
      out.add((
        surah: s.name,
        verses: [
          for (final v in s.verses)
            if (v.id >= p.from && v.id <= p.to) (n: v.id, text: v.text),
        ],
      ));
    }
    if (mounted) setState(() => _data = out);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.passages.length,
              itemBuilder: (_, i) {
                final p = widget.passages[i];
                final d = _data![i];
                final ref = p.from == p.to
                    ? '${d.surah}: ${arNum(p.from)}'
                    : '${d.surah}: ${arNum(p.from)}–${arNum(p.to)}';
                final text =
                    d.verses.map((v) => '${v.text} ﴿${arNum(v.n)}﴾').join(' ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.menu_book, size: 15, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(ref,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: scheme.primary)),
                          ),
                          IconButton(
                            tooltip: tr('مشاركة', 'Share'),
                            icon: const Icon(Icons.ios_share, size: 18),
                            onPressed: () =>
                                Share.share('$text\n\n[$ref]'),
                          ),
                        ]),
                        if (p.label.isNotEmpty)
                          Text(p.label,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(children: [
                            for (final v in d.verses) ...[
                              TextSpan(text: v.text),
                              TextSpan(
                                  text: ' ﴿${arNum(v.n)}﴾ ',
                                  style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ]),
                          textAlign: TextAlign.justify,
                          style: const TextStyle(fontSize: 19, height: 2.1),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _tafsir.contains(i)
                                ? _tafsir.remove(i)
                                : _tafsir.add(i)),
                            icon: Icon(
                                _tafsir.contains(i)
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18),
                            label: Text(_tafsir.contains(i)
                                ? tr('إخفاء التفسير', 'Hide tafsir')
                                : tr('التفسير الميسّر', 'Tafsir')),
                          ),
                        ),
                        if (_tafsir.contains(i)) _TafsirBox(p),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TafsirBox extends StatelessWidget {
  final StoryPassage p;
  const _TafsirBox(this.p);

  Future<List<({int n, String t})>> _load() async {
    final out = <({int n, String t})>[];
    for (var a = p.from; a <= p.to; a++) {
      final t = await TafsirData.of(p.surah, a);
      if (t.isNotEmpty) out.add((n: a, t: t));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<({int n, String t})>>(
      future: _load(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('التفسير الميسّر', 'Tafsir al-Muyassar'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: scheme.primary)),
              const SizedBox(height: 6),
              for (final e in snap.data!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '﴿${arNum(e.n)}﴾ ',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary)),
                        TextSpan(text: e.t),
                      ]),
                      style: const TextStyle(fontSize: 14, height: 1.7)),
                ),
            ],
          ),
        );
      },
    );
  }
}
