import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../data/settings_repo.dart';
import 'mushaf_page_screen.dart';

/// المصحف — قائمة السور تفتح على صفحات المصحف (مصحف المدينة) + متابعة من آخر صفحة.
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _settings = SettingsRepo();
  String _query = '';
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final page = await _settings.quranLastPage();
    if (mounted) setState(() => _lastPage = page);
  }

  Future<void> _openPage(int startPage) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => MushafPageScreen(startPage: startPage)));
    _reload();
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: tr('ابحث عن سورة…', 'Search a surah…'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_lastPage > 1 && q.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openPage(_lastPage),
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
                                Text(tr('صفحة ${arNum(_lastPage)}',
                                    'Page ${arNum(_lastPage)}'),
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
                      onTap: () => _openPage(surahStartPage(s.id)),
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
