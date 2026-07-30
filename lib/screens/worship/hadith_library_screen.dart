import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ar.dart';
import '../../core/hadith_books.dart';
import '../../core/l10n.dart';

/// مكتبة الحديث — كتب كاملة بنصّها من Sunnah.com، بأبوابها وببحث.
class HadithLibraryScreen extends StatelessWidget {
  const HadithLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final books = <({String key, String emoji, String title, String sub, Color color})>[
      (
        key: 'riyad',
        emoji: '🌿',
        title: 'رياض الصالحين',
        sub: tr('للإمام النووى — ${arNum(1896)} حديث فى ${arNum(20)} كتابًا',
            'An-Nawawi — 1896 hadiths'),
        color: const Color(0xFF1E7A5A),
      ),
      (
        key: 'nawawi40',
        emoji: '📜',
        title: 'الأربعون النووية',
        sub: tr('${arNum(42)} حديثًا جامعًا', '42 core hadiths'),
        color: const Color(0xFFCC8A2E),
      ),
      (
        key: 'qudsi40',
        emoji: '✨',
        title: 'الأربعون القدسية',
        sub: tr('${arNum(40)} حديثًا قدسيًّا', '40 hadith qudsi'),
        color: const Color(0xFF6A4C93),
      ),
      (
        key: 'shamail',
        emoji: '🌙',
        title: 'الشمائل المحمدية',
        sub: tr('للترمذى — صفته وأخلاقه ﷺ (${arNum(402)} حديث)',
            "At-Tirmidhi — the Prophet's noble features"),
        color: const Color(0xFF3C5A99),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr('مكتبة الحديث', 'Hadith library'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final b in books)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: b.color.withValues(alpha: 0.15),
                  child: Text(b.emoji, style: const TextStyle(fontSize: 24)),
                ),
                title: Text(b.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                subtitle: Text(b.sub,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _BookScreen(bookKey: b.key))),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr('النصوص من Sunnah.com — بلا تعديل أو صياغة.',
                  'Texts from Sunnah.com — unmodified.'),
              style:
                  TextStyle(fontSize: 11.5, color: scheme.outline, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// كتاب واحد — أبوابه + بحث فى كل أحاديثه.
class _BookScreen extends StatefulWidget {
  final String bookKey;
  const _BookScreen({required this.bookKey});

  @override
  State<_BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<_BookScreen> {
  HadithBook? _book;
  String _query = '';

  @override
  void initState() {
    super.initState();
    HadithBooks.load(widget.bookKey).then((b) {
      if (mounted) setState(() => _book = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = _book;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(b?.title ?? tr('تحميل…', 'Loading…'))),
      body: b == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: tr('ابحث فى الأحاديث…', 'Search hadiths…'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (b.author.isNotEmpty && _query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(b.author,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
                Expanded(
                  child: _query.trim().isNotEmpty
                      ? _searchResults(b, scheme)
                      : _chapterList(b, scheme),
                ),
              ],
            ),
    );
  }

  Widget _searchResults(HadithBook b, ColorScheme scheme) {
    final hits = b.search(_query);
    if (hits.isEmpty) {
      return Center(
        child: Text(tr('مفيش نتائج', 'No matches'),
            style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: hits.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                tr('${arNum(hits.length)} نتيجة', '${arNum(hits.length)} results'),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: scheme.primary)),
          );
        }
        return _hadithCard(hits[i - 1], b, scheme);
      },
    );
  }

  Widget _chapterList(HadithBook b, ColorScheme scheme) {
    // كتاب بباب واحد (زى الأربعينات) → اعرض الأحاديث مباشرة.
    if (b.chapters.length <= 1) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: b.hadiths.length,
        itemBuilder: (_, i) => _hadithCard(b.hadiths[i], b, scheme),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: b.chapters.length,
      itemBuilder: (_, i) {
        final c = b.chapters[i];
        final count = b.inChapter(c.id).length;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.6),
              child: Text(arNum(i + 1),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer)),
            ),
            title: Text(c.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                tr('${arNum(count)} حديث', '${arNum(count)} hadiths'),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _ChapterScreen(book: b, chapter: c))),
          ),
        );
      },
    );
  }

  Widget _hadithCard(BookHadith h, HadithBook b, ColorScheme scheme) =>
      hadithCard(h, b, scheme);
}

/// أحاديث باب واحد.
class _ChapterScreen extends StatelessWidget {
  final HadithBook book;
  final BookChapter chapter;
  const _ChapterScreen({required this.book, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = book.inChapter(chapter.id);
    return Scaffold(
      appBar: AppBar(title: Text(chapter.name)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) => hadithCard(list[i], book, scheme),
      ),
    );
  }
}

/// كارت حديث مشترك — الرقم + النص + زر مشاركة.
Widget hadithCard(BookHadith h, HadithBook b, ColorScheme scheme) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.6),
                child: Text(arNum(h.n),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(b.title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
              ),
              IconButton(
                tooltip: 'مشاركة',
                icon: const Icon(Icons.ios_share, size: 18),
                onPressed: () =>
                    Share.share('${h.text}\n\n[${b.title} — ${arNum(h.n)}]'),
              ),
            ]),
            const SizedBox(height: 8),
            Text(h.text, style: const TextStyle(fontSize: 17, height: 2.0)),
          ],
        ),
      ),
    );
