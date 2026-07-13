import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import 'mushaf_page_screen.dart';

/// بحث فى نص القرآن (متحقَّق) → ينقلك لصفحة المصحف.
class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _Hit {
  final int surah, ayah, page;
  final String surahName, text;
  const _Hit(this.surah, this.ayah, this.page, this.surahName, this.text);
}

/// إزالة التشكيل وتوحيد الحروف عشان البحث يطابق النص العثمانى المشكَّل.
String _norm(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x064B && r <= 0x0655) continue; // حركات + همزات فوق/تحت
    if (r == 0x0670 || r == 0x0640) continue; // ألف خنجرية + تطويل
    if (r >= 0x06D6 && r <= 0x06ED) continue; // علامات وقف قرآنية
    b.writeCharCode(r);
  }
  return b
      .toString()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  List<QuranSurah> _surahs = const [];
  final List<({int s, int a, String norm, String text, String name})> _index = [];
  List<_Hit> _hits = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    _surahs = await QuranData.surahs();
    for (final su in _surahs) {
      for (final v in su.verses) {
        _index.add((s: su.id, a: v.id, norm: _norm(v.text), text: v.text, name: su.name));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _search(String q) async {
    final nq = _norm(q.trim());
    if (nq.length < 2) {
      setState(() => _hits = const []);
      return;
    }
    final matched = _index.where((e) => e.norm.contains(nq)).take(80).toList();
    final hits = <_Hit>[];
    for (final m in matched) {
      final page = await QuranData.pageOfAyah(m.s, m.a);
      hits.add(_Hit(m.s, m.a, page, m.name, m.text));
    }
    if (mounted) setState(() => _hits = hits);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('بحث فى القرآن', 'Search the Quran'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: tr('اكتب كلمة أو جملة…', 'Type a word or phrase…'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                    ),
                    onChanged: _search,
                  ),
                ),
                if (_hits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(tr('${arNum(_hits.length)} نتيجة',
                          '${arNum(_hits.length)} results'),
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: _hits.length,
                    itemBuilder: (_, i) {
                      final h = _hits[i];
                      return Card(
                        child: ListTile(
                          title: Text(h.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, height: 1.8)),
                          subtitle: Text(
                              '${h.surahName} · ${tr('آية', 'ayah')} ${arNum(h.ayah)} · ${tr('صفحة', 'p.')} ${arNum(h.page)}'),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MushafPageScreen(startPage: h.page))),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
