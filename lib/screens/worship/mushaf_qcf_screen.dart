import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/qcf.dart';
import '../../core/quran_audio.dart';
import '../../core/quran_data.dart';
import '../../data/settings_repo.dart';

/// عرض المصحف بخط QCF (تجريبى) — نص المصحف كخط بيطابق شكل الصفحة،
/// مع تعليم الآية الجارية بالضبط أثناء التلاوة.
class MushafQcfScreen extends StatefulWidget {
  final int startPage;
  const MushafQcfScreen({super.key, this.startPage = 1});

  @override
  State<MushafQcfScreen> createState() => _MushafQcfScreenState();
}

class _MushafQcfScreenState extends State<MushafQcfScreen> {
  final _settings = SettingsRepo();
  late final PageController _controller =
      PageController(initialPage: widget.startPage - 1);
  int _page = 1;
  bool _reciting = false;

  @override
  void initState() {
    super.initState();
    _page = widget.startPage;
    _settings.quranReciter().then((r) => QuranAudio.reciter = r);
    QuranAudio.playing.addListener(_onAudio);
  }

  void _onAudio() {
    if (!mounted) return;
    if (QuranAudio.playing.value == null && _reciting && _page < kMushafPages) {
      final next = _page + 1;
      _controller.jumpToPage(next - 1);
      QuranData.pageAyahs(next).then((r) {
        if (_reciting) QuranAudio.playList(r);
      });
    }
  }

  @override
  void dispose() {
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
      await QuranAudio.playList(await QuranData.pageAyahs(_page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('المصحف (خط) — صفحة ${arNum(_page)}',
            'Quran (font) — Page ${arNum(_page)}')),
        actions: [
          ValueListenableBuilder<({int surah, int ayah})?>(
            valueListenable: QuranAudio.playing,
            builder: (_, p, _) => IconButton(
              icon: Icon(p != null ? Icons.stop_circle : Icons.play_circle),
              onPressed: _togglePlay,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: kMushafPages,
        onPageChanged: (i) => setState(() => _page = i + 1),
        itemBuilder: (_, i) => _QcfPage(page: i + 1),
      ),
    );
  }
}

class _QcfPage extends StatefulWidget {
  final int page;
  const _QcfPage({required this.page});

  @override
  State<_QcfPage> createState() => _QcfPageState();
}

class _QcfPageState extends State<_QcfPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<List<QcfWord>>>(
      future: Qcf.preparePage(widget.page),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                  tr('تعذّر تحميل الصفحة — تحتاج إنترنت لأول مرة',
                      'Could not load — needs internet the first time'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lines = snap.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              for (final line in lines)
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ValueListenableBuilder<({int surah, int ayah})?>(
                        valueListenable: QuranAudio.playing,
                        builder: (_, p, _) => Text.rich(
                          TextSpan(
                            children: [
                              for (final w in line)
                                TextSpan(
                                  text: w.code,
                                  style: TextStyle(
                                    fontFamily: Qcf.fontFamily(widget.page),
                                    fontSize: 40,
                                    color: scheme.onSurface,
                                    backgroundColor: (p != null &&
                                            p.surah == w.surah &&
                                            p.ayah == w.ayah)
                                        ? scheme.primary.withValues(alpha: 0.28)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
