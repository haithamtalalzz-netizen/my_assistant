import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../data/settings_repo.dart';
import 'khatma_screen.dart';

/// قارئ السورة — رسم عثمانى، تكبير الخط، حفظ آخر موضع تلقائيًا، وربط بالختمة.
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
  }

  Future<void> _load() async {
    final surah = await QuranData.surah(widget.surahId);
    final font = await _settings.quranFontSize();
    if (!mounted) return;
    setState(() {
      _surah = surah;
      _font = font;
    });
    // القفز لموضع البداية (متابعة القراءة) بعد أول رسم.
    final start = widget.startAyah;
    if (start != null && start > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemController.isAttached) {
          _itemController.jumpTo(index: start - 1);
        }
      });
    }
  }

  void _onScroll() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;
    // أول عنصر ظاهر من فوق (نتخطى الهيدر index 0 لو موجود).
    final top = positions
        .where((p) => p.itemLeadingEdge >= -0.1)
        .fold<ItemPosition?>(null, (min, p) =>
            min == null || p.itemLeadingEdge < min.itemLeadingEdge ? p : min);
    if (top == null) return;
    final ayah = (top.index).clamp(1, _surah?.verses.length ?? 1);
    if (ayah != _topAyah) {
      _topAyah = ayah;
      // حفظ آخر موضع (بتهدئة عشان مانكتبش كتير).
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 600),
          () => _settings.setQuranBookmark(widget.surahId, ayah));
    }
  }

  Future<void> _setFont(double v) async {
    setState(() => _font = v.clamp(18, 44));
    await _settings.setQuranFontSize(_font);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positions.itemPositions.removeListener(_onScroll);
    // حفظ فورى عند الخروج.
    _settings.setQuranBookmark(widget.surahId, _topAyah);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(s == null ? tr('المصحف', 'Quran') : 'سورة ${s.name}'),
        actions: [
          IconButton(
            tooltip: tr('تصغير الخط', 'Smaller'),
            icon: const Icon(Icons.text_decrease),
            onPressed: () => _setFont(_font - 2),
          ),
          IconButton(
            tooltip: tr('تكبير الخط', 'Larger'),
            icon: const Icon(Icons.text_increase),
            onPressed: () => _setFont(_font + 2),
          ),
          IconButton(
            tooltip: tr('الختمة', 'Khatma'),
            icon: const Icon(Icons.menu_book),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KhatmaScreen())),
          ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePositionedList.builder(
              itemScrollController: _itemController,
              itemPositionsListener: _positions,
              // عنصر 0..n-1 = الآيات؛ الهيدر (البسملة) جزء من الآية الأولى للعرض.
              itemCount: s.verses.length,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              itemBuilder: (context, i) => _ayahTile(s, i),
            ),
    );
  }

  Widget _ayahTile(QuranSurah s, int i) {
    final scheme = Theme.of(context).colorScheme;
    final ayah = s.verses[i];
    // البسملة كهيدر فوق أول آية (ماعدا الفاتحة: آيتها الأولى هى البسملة،
    // والتوبة: مفيهاش بسملة).
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
              child: Text(
                'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: _font + 2,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
        Divider(color: scheme.outlineVariant.withValues(alpha: 0.3), height: 1),
      ],
    );
  }
}
