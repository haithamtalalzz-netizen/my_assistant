import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/ar.dart';
import '../../core/ayah_share.dart';
import '../../core/l10n.dart';
import '../../core/quran_audio.dart';
import '../../core/quran_data.dart';
import '../../core/tafsir_data.dart';
import '../../core/translation_data.dart';
import '../../data/mushaf_repo.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';
import 'quran_search_screen.dart';

/// عرض صفحات المصحف كصور + سحب لأعلى (تفسير الصفحة + نبذة السورة) + تلاوة تُعلّم
/// الآية الجارية وتمشى مع الصفحات.
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
  final List<int> starts;
  final List<_AyahTaf> items;
  const _PageContent(this.starts, this.items);
}

class _MushafPageScreenState extends State<MushafPageScreen> {
  final _settings = SettingsRepo();
  final _repo = MushafRepo();
  final _worship = WorshipRepo();
  late final PageController _controller =
      PageController(initialPage: widget.startPage - 1);
  int _page = 1;
  bool _reciting = false;
  bool _night = false;
  int _readCount = 0;
  List<QuranSurah> _surahs = const [];

  @override
  void initState() {
    super.initState();
    _page = widget.startPage;
    _settings.quranReciter().then((r) => QuranAudio.reciter = r);
    _settings.quranSpeed().then((v) => QuranAudio.speed = v);
    _settings.mushafNight().then((n) {
      if (mounted) setState(() => _night = n);
    });
    _markRead(widget.startPage);
    QuranData.surahs().then((s) {
      if (mounted) setState(() => _surahs = s);
    });
    QuranAudio.playing.addListener(_onAudio);
  }

  Future<void> _markRead(int page) async {
    await _repo.markRead(page);
    final c = await _repo.readCount();
    if (mounted) setState(() => _readCount = c);
  }

  // بيتنفّذ لمّا تخلص آيات الصفحة → ينتقل للى بعدها ويكمّل التلاوة.
  void _onAudio() {
    if (!mounted) return;
    if (QuranAudio.playing.value == null && _reciting) {
      if (_page < kMushafPages) {
        final next = _page + 1;
        _controller.jumpToPage(next - 1);
        QuranData.pageAyahs(next).then((r) {
          if (_reciting) QuranAudio.playList(r);
        });
      } else {
        _reciting = false;
      }
    }
  }

  @override
  void dispose() {
    _settings.setQuranLastPage(_page);
    _reciting = false;
    QuranAudio.playing.removeListener(_onAudio);
    QuranAudio.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_reciting || QuranAudio.playing.value != null) {
      _reciting = false;
      await QuranAudio.stop();
    } else {
      _reciting = true;
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

  Future<void> _toggleNight() async {
    setState(() => _night = !_night);
    await _settings.setMushafNight(_night);
  }

  void _juzSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: 420,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, childAspectRatio: 1.3,
              crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 30,
          itemBuilder: (ctx, i) => InkWell(
            onTap: () {
              Navigator.pop(ctx);
              _controller.jumpToPage(kJuzStartPage[i] - 1);
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tr('جزء', 'Juz'),
                      style: const TextStyle(fontSize: 11)),
                  Text(arNum(i + 1),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addBookmark() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('علامة على صفحة ${arNum(_page)}',
            'Bookmark page ${arNum(_page)}')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
              hintText: tr('اسم العلامة (اختيارى)', 'Label (optional)')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    if (ok == true) {
      await _repo.addBookmark(_page, ctrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('اتحفظت العلامة ✓', 'Bookmark saved ✓'))));
      }
    }
  }

  void _bookmarksSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => FutureBuilder<List<QuranBookmark>>(
          future: _repo.bookmarks(),
          builder: (_, snap) {
            final list = snap.data ?? const <QuranBookmark>[];
            if (list.isEmpty) {
              return SizedBox(
                height: 160,
                child: Center(
                    child: Text(tr('لا توجد علامات بعد', 'No bookmarks yet'))),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final b in list)
                  ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(b.label.isEmpty
                        ? tr('صفحة ${arNum(b.page)}', 'Page ${arNum(b.page)}')
                        : b.label),
                    subtitle: b.label.isEmpty
                        ? null
                        : Text(tr('صفحة ${arNum(b.page)}', 'Page ${arNum(b.page)}')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _repo.deleteBookmark(b.id);
                        setSheet(() {});
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _controller.jumpToPage(b.page - 1);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _repeatSpeedSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('سرعة التلاوة', 'Recitation speed'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.75, 1.0, 1.25, 1.5]
                    .map((v) => ChoiceChip(
                          label: Text('${arNum(v)}×'),
                          selected: QuranAudio.speed == v,
                          onSelected: (_) {
                            QuranAudio.setSpeed(v);
                            _settings.setQuranSpeed(v);
                            setSheet(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(tr('التكرار (للحفظ)', 'Repeat (memorization)'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('none', tr('بدون', 'None')),
                  ('one', tr('كرّر الآية', 'Repeat ayah')),
                  ('all', tr('كرّر الصفحة', 'Loop page')),
                ]
                    .map((e) => ChoiceChip(
                          label: Text(e.$2),
                          selected: QuranAudio.repeatMode == e.$1,
                          onSelected: (_) {
                            QuranAudio.repeatMode = e.$1;
                            setSheet(() {});
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logWird() async {
    await _worship.ensureKhatma();
    await _worship.logKhatmaRead(1);
    final today = await _worship.todayKhatmaPages();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتسجّلت فى وردك — وردك اليوم ${arNum(today)} صفحة',
            'Logged — today\'s wird: ${arNum(today)} pages'))));
  }

  void _progressDialog() {
    final pct = (_readCount / kMushafPages * 100).round();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('تقدّم القراءة', 'Reading progress')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${arNum(pct)}%',
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _readCount / kMushafPages),
            const SizedBox(height: 10),
            Text(tr('قرأت ${arNum(_readCount)} من ${arNum(kMushafPages)} صفحة',
                'Read ${arNum(_readCount)} of ${arNum(kMushafPages)} pages')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('تمام', 'OK'))),
        ],
      ),
    );
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
          ValueListenableBuilder<({int surah, int ayah})?>(
            valueListenable: QuranAudio.playing,
            builder: (_, p, _) => IconButton(
              tooltip: tr('تلاوة', 'Recite'),
              icon: Icon(p != null ? Icons.stop_circle : Icons.play_circle),
              onPressed: _togglePlay,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'night':
                  _toggleNight();
                case 'juz':
                  _juzSheet();
                case 'bookmarks':
                  _bookmarksSheet();
                case 'addbm':
                  _addBookmark();
                case 'search':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
                case 'repeat':
                  _repeatSpeedSheet();
                case 'progress':
                  _progressDialog();
                case 'wird':
                  _logWird();
                case 'download':
                  _downloadAll();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'night',
                  child: Text(_night
                      ? tr('وضع نهارى', 'Day mode')
                      : tr('وضع ليلى', 'Night mode'))),
              PopupMenuItem(value: 'search', child: Text(tr('بحث فى القرآن', 'Search'))),
              PopupMenuItem(value: 'juz', child: Text(tr('فهرس الأجزاء', 'Juz index'))),
              PopupMenuItem(value: 'bookmarks', child: Text(tr('العلامات المرجعية', 'Bookmarks'))),
              PopupMenuItem(value: 'addbm', child: Text(tr('أضف علامة هنا', 'Bookmark this page'))),
              PopupMenuItem(value: 'repeat', child: Text(tr('تكرار وسرعة التلاوة', 'Repeat & speed'))),
              PopupMenuItem(value: 'wird', child: Text(tr('سجّل هذه الصفحة فى وردى', 'Log this page to my wird'))),
              PopupMenuItem(value: 'progress', child: Text(tr('تقدّم القراءة', 'Reading progress'))),
              PopupMenuItem(value: 'download', child: Text(tr('تحميل المصحف كامل', 'Download mushaf'))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: kMushafPages,
              onPageChanged: (i) {
                setState(() => _page = i + 1);
                _markRead(i + 1);
              },
              itemBuilder: (_, i) =>
                  _MushafPageImage(page: i + 1, night: _night),
            ),
          ),
          _nowPlayingStrip(),
          _tafsirSheet(),
        ],
      ),
    );
  }

  // شريط «يُتلى الآن» بيعلّم الآية الجارية (فوق مقبض التفسير).
  Widget _nowPlayingStrip() {
    return ValueListenableBuilder<({int surah, int ayah})?>(
      valueListenable: QuranAudio.playing,
      builder: (context, p, _) {
        if (p == null || _surahs.isEmpty) return const SizedBox.shrink();
        final surah = _surahs[p.surah - 1];
        final v = surah.verses.firstWhere((e) => e.id == p.ayah,
            orElse: () => surah.verses.first);
        var snippet = v.text;
        if (snippet.length > 60) snippet = '${snippet.substring(0, 60)}…';
        return Positioned(
          left: 12,
          right: 12,
          bottom: 70,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF1E7A5A),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('يُتلى الآن — ${surah.name} · آية ${arNum(p.ayah)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5)),
                        Text(snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _togglePlay,
                    child: const Icon(Icons.stop_circle,
                        color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                    Text(
                        tr('اسحب لأعلى: تفسير آيات الصفحة',
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
    if (_surahs.isEmpty) return const SizedBox.shrink();
    final s = _surahs[surahId - 1];
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
                color: scheme.onPrimary.withValues(alpha: 0.95), height: 1.7),
          ),
          const SizedBox(height: 6),
          Text(
            'ترتيبها فى المصحف: ${arNum(surahId)} · '
            'ترتيب نزولها: ${arNum(kSurahRevOrder[surahId - 1])}',
            style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.95), height: 1.7),
          ),
          Text(
            'عدد آياتها: ${arNum(s.verses.length)} · '
            'الجزء ${arNum(kSurahStartJuz[surahId - 1])} · '
            'صفحة ${arNum(surahStartPage(surahId))}',
            style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.95), height: 1.7),
          ),
        ],
      ),
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
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.play_arrow, size: 20),
                onPressed: () {
                  _reciting = false;
                  QuranAudio.playAyah(it.surah, it.ayah);
                },
              ),
            ],
          ),
          // أزرار: نسخ + مشاركة كصورة.
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 30),
            child: Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(tr('نسخ', 'Copy')),
                  onPressed: () async {
                    await copyAyah(_surahName(it.surah), it.ayah, it.text,
                        it.tafsir);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(tr('اتنسخت ✓', 'Copied ✓'))));
                    }
                  },
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: Text(tr('مشاركة كصورة', 'Share image')),
                  onPressed: () => shareAyahImage(
                      surahName: _surahName(it.surah),
                      ayah: it.ayah,
                      text: it.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: Text(it.tafsir,
                style: TextStyle(
                    fontSize: 15, height: 1.8, color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: FutureBuilder<String>(
              future: TranslationData.of(it.surah, it.ayah),
              builder: (_, snap) {
                final t = snap.data ?? '';
                if (t.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('المعنى بالإنجليزية', 'English meaning'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 13.5,
                              height: 1.6,
                              color: scheme.onSurfaceVariant)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _surahName(int surahId) =>
      _surahs.isEmpty ? '' : _surahs[surahId - 1].name;
}

/// صفحة مصحف واحدة — StatefulWidget عشان الزووم (TransformationController)
/// يفضل ثابت ومايترسمش من جديد مع أى تحديث خارجى (يخلّى التكبير سلس).
class _MushafPageImage extends StatefulWidget {
  final int page;
  final bool night;
  const _MushafPageImage({required this.page, this.night = false});

  @override
  State<_MushafPageImage> createState() => _MushafPageImageState();
}

/// مصفوفة عكس الألوان (وضع ليلى) — خلفية سوداء ونصّ فاتح.
const ColorFilter _invert = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
]);

class _MushafPageImageState extends State<_MushafPageImage>
    with AutomaticKeepAliveClientMixin {
  final _tc = TransformationController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final img = CachedNetworkImage(
      imageUrl: mushafPageUrl(widget.page),
      fit: BoxFit.fitWidth,
      width: double.infinity,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, _) => const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator())),
      errorWidget: (_, _, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('تعذّر تحميل الصفحة — تحقق من الإنترنت',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ),
      ),
    );
    return Container(
      color: widget.night ? Colors.black : Colors.white,
      padding: const EdgeInsets.only(bottom: 40),
      child: InteractiveViewer(
        transformationController: _tc,
        minScale: 1,
        maxScale: 5,
        clipBehavior: Clip.none,
        child: Center(
          child: widget.night
              ? ColorFiltered(colorFilter: _invert, child: img)
              : img,
        ),
      ),
    );
  }
}
