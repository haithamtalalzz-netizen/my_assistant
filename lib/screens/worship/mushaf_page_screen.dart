import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_audio.dart';
import '../../core/quran_data.dart';
import '../../core/tafsir_data.dart';
import '../../data/settings_repo.dart';

/// عرض صفحات المصحف كصور + سحب لأعلى يفتح تفسير آيات الصفحة + نبذة عن السورة.
class MushafPageScreen extends StatefulWidget {
  final int startPage;
  const MushafPageScreen({super.key, this.startPage = 1});

  @override
  State<MushafPageScreen> createState() => _MushafPageScreenState();
}

class _AyahTaf {
  final int surah, ayah;
  final String text, tafsir;
  const _AyahTaf(this.surah, this.ayah, this.text, this.tafsir);
}

class _PageContent {
  final List<int> starts; // سور تبدأ فى الصفحة
  final List<_AyahTaf> items;
  const _PageContent(this.starts, this.items);
}

class _MushafPageScreenState extends State<MushafPageScreen> {
  final _settings = SettingsRepo();
  late final PageController _controller =
      PageController(initialPage: widget.startPage - 1);
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _page = widget.startPage;
    _settings.quranReciter().then((r) => QuranAudio.reciter = r);
    QuranAudio.playing.addListener(_onAudio);
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.setQuranLastPage(_page);
    QuranAudio.playing.removeListener(_onAudio);
    QuranAudio.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (QuranAudio.playing.value != null) {
      await QuranAudio.stop();
    } else {
      final refs = await QuranData.pageAyahs(_page);
      await QuranAudio.playList(refs);
    }
  }

  Future<void> _pickReciter() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(tr('اختر القارئ', 'Choose reciter'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final r in kReciters)
              ListTile(
                title: Text(r.name),
                trailing: QuranAudio.reciter == r.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, r.id),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      QuranAudio.reciter = chosen;
      await _settings.setQuranReciter(chosen);
      if (mounted) setState(() {});
    }
  }

  Future<_PageContent> _loadPage(int page) async {
    final refs = await QuranData.pageAyahs(page);
    final all = await QuranData.surahs();
    final items = <_AyahTaf>[];
    for (final r in refs) {
      final s = r[0], a = r[1];
      final text = all[s - 1].verses.firstWhere((v) => v.id == a).text;
      final taf = await TafsirData.of(s, a);
      items.add(_AyahTaf(s, a, text, taf));
    }
    final starts = refs.where((r) => r[1] == 1).map((r) => r[0]).toList();
    return _PageContent(starts, items);
  }

  Future<void> _jump() async {
    final ctrl = TextEditingController(text: '$_page');
    final n = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('اذهب لصفحة', 'Go to page')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('1 - 604', '1 - 604')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(ctrl.text.trim())),
              child: Text(tr('اذهب', 'Go'))),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= kMushafPages) _controller.jumpToPage(n - 1);
  }

  Future<void> _downloadAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('تحميل المصحف كامل', 'Download full mushaf')),
        content: Text(tr(
            'هيحمّل 604 صفحة (~21 ميجا) للقراءة بدون نت. تأكد من الواى فاى.',
            'Downloads 604 pages (~21 MB) for offline reading. Use Wi-Fi.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('تحميل', 'Download'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final progress = ValueNotifier<int>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(tr('جارٍ التحميل…', 'Downloading…')),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, v, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: v / kMushafPages),
              const SizedBox(height: 8),
              Text('${arNum(v)} / ${arNum(kMushafPages)}'),
            ],
          ),
        ),
      ),
    );
    final cm = DefaultCacheManager();
    for (var p = 1; p <= kMushafPages; p++) {
      try {
        await cm.downloadFile(mushafPageUrl(p));
      } catch (_) {}
      progress.value = p;
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('تمّ تحميل المصحف للأوفلاين ✓',
              'Mushaf downloaded for offline ✓'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _jump,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('صفحة ${arNum(_page)}', 'Page ${arNum(_page)}')),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr('القارئ', 'Reciter'),
            icon: const Icon(Icons.record_voice_over),
            onPressed: _pickReciter,
          ),
          IconButton(
            tooltip: tr('تلاوة الصفحة', 'Recite page'),
            icon: Icon(QuranAudio.playing.value != null
                ? Icons.stop_circle
                : Icons.play_circle),
            onPressed: _togglePlay,
          ),
          IconButton(
            tooltip: tr('تحميل المصحف كامل', 'Download full mushaf'),
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _downloadAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: kMushafPages,
              onPageChanged: (i) => setState(() => _page = i + 1),
              itemBuilder: (_, i) => Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 40),
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: mushafPageUrl(i + 1),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      placeholder: (_, _) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, _, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            tr('تعذّر تحميل الصفحة — تحقق من الإنترنت',
                                'Could not load the page — check your connection'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _tafsirSheet(),
        ],
      ),
    );
  }

  Widget _tafsirSheet() {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.09,
      minChildSize: 0.09,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.09, 0.9],
      builder: (context, controller) => Material(
        elevation: 12,
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            // مقبض السحب.
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_up,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(tr('اسحب لأعلى: تفسير آيات الصفحة',
                        'Swipe up: page tafsir'),
                        style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const Divider(height: 16),
              ],
            ),
            FutureBuilder<_PageContent>(
              // key بالصفحة عشان يعيد التحميل عند تغييرها.
              key: ValueKey(_page),
              future: _loadPage(_page),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final c = snap.data!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in c.starts) _surahIntro(s),
                      for (final it in c.items) _ayahTaf(it),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahIntro(int surahId) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<QuranSurah>>(
      future: QuranData.surahs(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final s = snap.data![surahId - 1];
        final meccan = s.isMeccan;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scheme.primary.withValues(alpha: 0.85),
              scheme.primary.withValues(alpha: 0.55),
            ]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نبذة عن سورة ${s.name}',
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                meccan
                    ? 'سورة مكية — نزلت قبل الهجرة إلى المدينة.'
                    : 'سورة مدنية — نزلت بعد الهجرة إلى المدينة.',
                style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.95),
                    height: 1.7),
              ),
              const SizedBox(height: 6),
              Text(
                'ترتيبها فى المصحف: ${arNum(surahId)} · '
                'ترتيب نزولها: ${arNum(kSurahRevOrder[surahId - 1])}',
                style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.95),
                    height: 1.7),
              ),
              Text(
                'عدد آياتها: ${arNum(s.verses.length)} · '
                'الجزء ${arNum(kSurahStartJuz[surahId - 1])} · '
                'صفحة ${arNum(surahStartPage(surahId))}',
                style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.95),
                    height: 1.7),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ayahTaf(_AyahTaf it) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: scheme.primaryContainer,
                child: Text(arNum(it.ayah),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(it.text,
                    style: const TextStyle(fontSize: 18, height: 1.9)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: Text(it.tafsir,
                style: TextStyle(
                    fontSize: 15, height: 1.8, color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
