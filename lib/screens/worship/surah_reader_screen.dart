import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_audio.dart';
import '../../core/quran_data.dart';
import '../../core/tafsir_data.dart';
import '../../data/settings_repo.dart';
import 'khatma_screen.dart';

/// قارئ السورة — رسم عثمانى، تكبير الخط، حفظ آخر موضع، تفسير الميسّر، وتلاوة صوتية.
class SurahReaderScreen extends StatefulWidget {
  final int surahId;
  final int? startAyah;
  const SurahReaderScreen({super.key, required this.surahId, this.startAyah});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final _settings = SettingsRepo();
  final _itemController = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  QuranSurah? _surah;
  double _font = 26;
  int _topAyah = 1;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _positions.itemPositions.addListener(_onScroll);
    QuranAudio.playing.addListener(_onPlaying);
  }

  Future<void> _load() async {
    final surah = await QuranData.surah(widget.surahId);
    final font = await _settings.quranFontSize();
    QuranAudio.reciter = await _settings.quranReciter();
    if (!mounted) return;
    setState(() {
      _surah = surah;
      _font = font;
    });
    final start = widget.startAyah;
    if (start != null && start > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemController.isAttached) _itemController.jumpTo(index: start - 1);
      });
    }
  }

  void _onPlaying() {
    final p = QuranAudio.playing.value;
    if (p != null && p.surah == widget.surahId && _itemController.isAttached) {
      _itemController.scrollTo(
          index: p.ayah - 1,
          duration: const Duration(milliseconds: 400),
          alignment: 0.3);
    }
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;
    final top = positions
        .where((p) => p.itemLeadingEdge >= -0.1)
        .fold<ItemPosition?>(
            null,
            (min, p) =>
                min == null || p.itemLeadingEdge < min.itemLeadingEdge ? p : min);
    if (top == null) return;
    final ayah = top.index.clamp(1, _surah?.verses.length ?? 1);
    if (ayah != _topAyah) {
      _topAyah = ayah;
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 600),
          () => _settings.setQuranBookmark(widget.surahId, ayah));
    }
  }

  Future<void> _setFont(double v) async {
    setState(() => _font = v.clamp(18, 44));
    await _settings.setQuranFontSize(_font);
  }

  Future<void> _toggleSurahPlay() async {
    final p = QuranAudio.playing.value;
    if (p != null && p.surah == widget.surahId) {
      await QuranAudio.stop();
    } else {
      await QuranAudio.playSurah(
          widget.surahId, _topAyah, _surah!.verses.length);
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

  void _openAyahSheet(int surah, int ayah, String text) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(arNum(ayah),
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Text(tr('آية ${arNum(ayah)}', 'Ayah ${arNum(ayah)}'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => QuranAudio.playAyah(surah, ayah),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr('استمع', 'Listen')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(fontSize: _font, height: 2.1)),
            const Divider(height: 28),
            Text(tr('التفسير الميسّر', 'Tafsir al-Muyassar'),
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: scheme.primary)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: TafsirData.of(surah, ayah),
              builder: (_, snap) => Text(
                snap.data ?? tr('…جارٍ التحميل', '…loading'),
                style: const TextStyle(fontSize: 16, height: 1.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positions.itemPositions.removeListener(_onScroll);
    QuranAudio.playing.removeListener(_onPlaying);
    QuranAudio.stop();
    _settings.setQuranBookmark(widget.surahId, _topAyah);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _surah;
    final playing = QuranAudio.playing.value;
    final surahPlaying = playing != null && playing.surah == widget.surahId;
    return Scaffold(
      appBar: AppBar(
        title: Text(s == null ? tr('المصحف', 'Quran') : 'سورة ${s.name}'),
        actions: [
          IconButton(
              tooltip: tr('القارئ', 'Reciter'),
              icon: const Icon(Icons.record_voice_over),
              onPressed: _pickReciter),
          IconButton(
              tooltip: tr('تصغير', 'Smaller'),
              icon: const Icon(Icons.text_decrease),
              onPressed: () => _setFont(_font - 2)),
          IconButton(
              tooltip: tr('تكبير', 'Larger'),
              icon: const Icon(Icons.text_increase),
              onPressed: () => _setFont(_font + 2)),
          IconButton(
              tooltip: tr('الختمة', 'Khatma'),
              icon: const Icon(Icons.menu_book),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KhatmaScreen()))),
        ],
      ),
      floatingActionButton: s == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleSurahPlay,
              icon: Icon(surahPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(surahPlaying
                  ? tr('إيقاف', 'Stop')
                  : tr('تلاوة السورة', 'Play surah')),
            ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePositionedList.builder(
              itemScrollController: _itemController,
              itemPositionsListener: _positions,
              itemCount: s.verses.length,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
              itemBuilder: (context, i) => _ayahTile(s, i, playing?.ayah),
            ),
    );
  }

  Widget _ayahTile(QuranSurah s, int i, int? playingAyah) {
    final scheme = Theme.of(context).colorScheme;
    final ayah = s.verses[i];
    final isPlaying = playingAyah == ayah.id;
    final showBismillah = i == 0 && s.id != 1 && s.id != 9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (i == 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${s.isMeccan ? tr('سورة مكية', 'Meccan') : tr('سورة مدنية', 'Medinan')} · ${arNum(s.verses.length)} ${tr('آية', 'ayat')}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          if (showBismillah)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: _font + 2,
                      height: 2.0,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary)),
            ),
        ],
        InkWell(
          onTap: () => _openAyahSheet(s.id, ayah.id, ayah.text),
          child: Container(
            color: isPlaying
                ? scheme.primaryContainer.withValues(alpha: 0.4)
                : null,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${ayah.text} '),
                TextSpan(
                  text: '۝${arNum(ayah.id)} ',
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ]),
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: _font, height: 2.1),
            ),
          ),
        ),
        Divider(color: scheme.outlineVariant.withValues(alpha: 0.3), height: 1),
      ],
    );
  }
}
