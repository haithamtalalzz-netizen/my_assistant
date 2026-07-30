import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/arbain_data.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../core/religious_stories.dart';
import '../../core/tafsir_data.dart';

/// كارت «القصص والسيرة» الموحّد فى «صلاتى» — هَب يجمع:
/// قصص الأنبياء · قصص قرآنية · السيرة النبوية المختصرة · الأربعون النووية.
/// كل المحتوى من مصادر متحقّقة مدمجة (قرآن Tanzil + تفسير ميسّر + نووية Sunnah).
class ReligiousContentScreen extends StatelessWidget {
  const ReligiousContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem('📖', tr('قصص الأنبياء', 'Stories of the Prophets'),
          tr('${arNum(kProphetStories.length)} نبى — من القرآن',
              '${arNum(kProphetStories.length)} prophets — from the Quran'),
          const Color(0xFF1E7A5A),
          () => _StoriesListScreen(
              title: tr('قصص الأنبياء', 'Prophets'),
              stories: kProphetStories)),
      _HubItem('🕋', tr('قصص قرآنية', 'Quranic stories'),
          tr('${arNum(kQuranicStories.length)} قصة وعِبرة',
              '${arNum(kQuranicStories.length)} stories & lessons'),
          const Color(0xFF2E7D6B),
          () => _StoriesListScreen(
              title: tr('قصص قرآنية', 'Quranic stories'),
              stories: kQuranicStories)),
      _HubItem('🌙', tr('السيرة النبوية', "The Prophet's biography"),
          tr('محطّات مختصرة', 'Key milestones'), const Color(0xFF6A4C93),
          () => const _SeerahScreen()),
      _HubItem('📜', tr('الأربعون النووية', 'An-Nawawi 40 Hadith'),
          tr('٤٢ حديثًا جامعًا', '42 core hadiths'), const Color(0xFFCC8A2E),
          () => const _ArbainScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr('القصص والسيرة', 'Stories & seerah'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final it in items) ...[
            _hubCard(context, it),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          _sourceNote(context),
        ],
      ),
    );
  }

  Widget _hubCard(BuildContext context, _HubItem it) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: it.color.withValues(alpha: 0.15),
          child: Text(it.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(it.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text(it.subtitle,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => it.build())),
      ),
    );
  }

  Widget _sourceNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tr(
            'المصادر: نص القرآن من مصحف المدينة (Tanzil) · التفسير الميسّر '
                '(مجمع الملك فهد) · الأربعون النووية من Sunnah.com. كل النصوص '
                'مقتبسة بمصدرها — بلا صياغة.',
            'Sources: Quran (Tanzil/Madinah) · Tafsir al-Muyassar (King Fahd '
                'Complex) · An-Nawawi 40 from Sunnah.com. All texts quoted with '
                'their source — no paraphrase.'),
        style: TextStyle(fontSize: 11.5, color: scheme.outline, height: 1.5),
      ),
    );
  }
}

class _HubItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Widget Function() build;
  _HubItem(this.emoji, this.title, this.subtitle, this.color, this.build);
}

/// قائمة قصص (أنبياء أو قرآنية).
class _StoriesListScreen extends StatelessWidget {
  final String title;
  final List<QuranStory> stories;
  const _StoriesListScreen({required this.title, required this.stories});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: stories.length,
        itemBuilder: (_, i) {
          final s = stories[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Text(s.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(s.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.intro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12.5)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _StoryReaderScreen(s))),
            ),
          );
        },
      ),
    );
  }
}

/// قارئ قصة — يعرض كل مقطع بنص آياته + التفسير الميسّر عند الطلب.
class _StoryReaderScreen extends StatefulWidget {
  final QuranStory story;
  const _StoryReaderScreen(this.story);

  @override
  State<_StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _PassageData {
  final String surahName;
  final List<({int n, String text})> verses;
  const _PassageData(this.surahName, this.verses);
}

class _StoryReaderScreenState extends State<_StoryReaderScreen> {
  List<_PassageData>? _data;
  final Set<int> _showTafsir = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <_PassageData>[];
    for (final p in widget.story.passages) {
      final s = await QuranData.surah(p.surah);
      final verses = [
        for (final v in s.verses)
          if (v.id >= p.from && v.id <= p.to) (n: v.id, text: v.text),
      ];
      out.add(_PassageData(s.name, verses));
    }
    if (mounted) setState(() => _data = out);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final story = widget.story;
    return Scaffold(
      appBar: AppBar(title: Text(story.name)),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Text(story.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(story.intro,
                          style: TextStyle(
                              height: 1.6, color: scheme.onSurfaceVariant)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < widget.story.passages.length; i++)
                  _passageCard(i, widget.story.passages[i], _data![i], scheme),
              ],
            ),
    );
  }

  Widget _passageCard(
      int i, StoryPassage p, _PassageData d, ColorScheme scheme) {
    final ref = p.from == p.to
        ? tr('سورة ${d.surahName}: آية ${arNum(p.from)}',
            '${d.surahName}: ${arNum(p.from)}')
        : tr('سورة ${d.surahName}: الآيات ${arNum(p.from)}–${arNum(p.to)}',
            '${d.surahName}: ${arNum(p.from)}–${arNum(p.to)}');
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(ref,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                          fontSize: 13.5)),
                ),
              ],
            ),
            if (p.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(p.label,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 10),
            // نص الآيات — كل آية يتبعها رقمها بلون مميّز.
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
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _showTafsir.contains(i)
                    ? _showTafsir.remove(i)
                    : _showTafsir.add(i)),
                icon: Icon(
                    _showTafsir.contains(i)
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18),
                label: Text(_showTafsir.contains(i)
                    ? tr('إخفاء التفسير', 'Hide tafsir')
                    : tr('التفسير الميسّر', 'Tafsir')),
              ),
            ),
            if (_showTafsir.contains(i)) _TafsirBlock(p),
          ],
        ),
      ),
    );
  }
}

/// كتلة التفسير الميسّر لمقطع — تُحمَّل عند الطلب فقط.
class _TafsirBlock extends StatelessWidget {
  final StoryPassage passage;
  const _TafsirBlock(this.passage);

  Future<List<({int n, String t})>> _load() async {
    final out = <({int n, String t})>[];
    for (var a = passage.from; a <= passage.to; a++) {
      final t = await TafsirData.of(passage.surah, a);
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
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '﴿${arNum(e.n)}﴾ ',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary)),
                    TextSpan(text: e.t),
                  ]), style: const TextStyle(fontSize: 14, height: 1.7)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// السيرة النبوية المختصرة — خط زمن المحطّات الكبرى.
class _SeerahScreen extends StatelessWidget {
  const _SeerahScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('السيرة النبوية المختصرة', 'Seerah'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kSeerahTimeline.length + 1,
        itemBuilder: (_, i) {
          if (i == kSeerahTimeline.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  tr('مختصر للمحطّات الكبرى المتّفق عليها — للتوسّع راجع كتب السيرة.',
                      'A concise timeline of agreed-upon milestones.'),
                  style: TextStyle(fontSize: 11.5, color: scheme.outline)),
            );
          }
          final e = kSeerahTimeline[i];
          final last = i == kSeerahTimeline.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                          color: scheme.primary, shape: BoxShape.circle),
                    ),
                    if (!last)
                      Expanded(
                        child: Container(
                            width: 2,
                            color: scheme.primary.withValues(alpha: 0.3)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.year,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary)),
                        const SizedBox(height: 2),
                        Text(e.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(e.note,
                            style: TextStyle(
                                height: 1.6,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// الأربعون النووية — قائمة الأحاديث الـ٤٢ بنصّها.
class _ArbainScreen extends StatelessWidget {
  const _ArbainScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الأربعون النووية', 'An-Nawawi 40'))),
      body: FutureBuilder<List<ArbainHadith>>(
        future: ArbainData.all(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == list.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      tr('المصدر: Sunnah.com — الأربعون النووية للإمام النووى.',
                          'Source: Sunnah.com — An-Nawawi 40.'),
                      style:
                          TextStyle(fontSize: 11.5, color: scheme.outline)),
                );
              }
              final h = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor:
                              scheme.primaryContainer.withValues(alpha: 0.6),
                          child: Text(arNum(h.n),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: scheme.onPrimaryContainer)),
                        ),
                        const SizedBox(width: 8),
                        Text(tr('الحديث ${arNum(h.n)}', 'Hadith ${arNum(h.n)}'),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary)),
                      ]),
                      const SizedBox(height: 10),
                      Text(h.text,
                          style: const TextStyle(fontSize: 17, height: 2.0)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
