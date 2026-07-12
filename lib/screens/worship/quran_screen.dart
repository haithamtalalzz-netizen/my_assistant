import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../data/settings_repo.dart';
import 'mushaf_page_screen.dart';
import 'surah_reader_screen.dart';

/// المصحف — قائمة السور + تبديل بين «صفحات المصحف» (صور) و«النص» (تفسير/صوت).
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _settings = SettingsRepo();
  String _query = '';
  String _mode = 'page';
  int _lastPage = 1;
  ({int surah, int ayah})? _bookmark;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final mode = await _settings.quranViewMode();
    final page = await _settings.quranLastPage();
    final bm = await _settings.quranBookmark();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _lastPage = page;
      _bookmark = bm;
    });
  }

  Future<void> _openSurah(int surahId) async {
    if (_mode == 'page') {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MushafPageScreen(startPage: surahStartPage(surahId))));
    } else {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => SurahReaderScreen(surahId: surahId)));
    }
    _reload();
  }

  Future<void> _resume() async {
    if (_mode == 'page') {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MushafPageScreen(startPage: _lastPage)));
    } else if (_bookmark != null) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                  surahId: _bookmark!.surah, startAyah: _bookmark!.ayah)));
    }
    _reload();
  }

  Future<void> _setMode(String m) async {
    setState(() => _mode = m);
    await _settings.setQuranViewMode(m);
  }

  bool get _hasResume => _mode == 'page' ? _lastPage > 1 : _bookmark != null;

  String get _resumeText {
    if (_mode == 'page') {
      return tr('صفحة ${arNum(_lastPage)}', 'Page ${arNum(_lastPage)}');
    }
    return tr('سورة ${arNum(_bookmark!.surah)} — آية ${arNum(_bookmark!.ayah)}',
        'Surah ${arNum(_bookmark!.surah)} — Ayah ${arNum(_bookmark!.ayah)}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('المصحف', 'Quran'))),
      body: FutureBuilder<List<QuranSurah>>(
        future: QuranData.surahs(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final q = _query.trim();
          final list = q.isEmpty
              ? all
              : all
                  .where((s) =>
                      s.name.contains(q) ||
                      s.tr.toLowerCase().contains(q.toLowerCase()) ||
                      '${s.id}' == q)
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'page',
                        icon: const Icon(Icons.menu_book, size: 18),
                        label: Text(tr('صفحات المصحف', 'Mushaf pages'))),
                    ButtonSegment(
                        value: 'text',
                        icon: const Icon(Icons.notes, size: 18),
                        label: Text(tr('نص + تفسير', 'Text + tafsir'))),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => _setMode(s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: tr('ابحث عن سورة…', 'Search a surah…'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_hasResume && q.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _resume,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bookmark, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('تابع القراءة', 'Continue reading'),
                                    style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w800)),
                                Text(_resumeText,
                                    style: TextStyle(color: scheme.onSurface)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return ListTile(
                      leading: _surahBadge(s.id, scheme),
                      title: Text('سورة ${s.name}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${s.isMeccan ? tr('مكية', 'Meccan') : tr('مدنية', 'Medinan')} · '
                        '${arNum(s.verses.length)} ${tr('آية', 'ayat')} · '
                        '${tr('صفحة', 'p.')} ${arNum(surahStartPage(s.id))}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      onTap: () => _openSurah(s.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _surahBadge(int id, ColorScheme scheme) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(arNum(id),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
      );
}
