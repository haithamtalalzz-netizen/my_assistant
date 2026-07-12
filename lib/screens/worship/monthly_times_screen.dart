import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../data/settings_repo.dart';

/// تقويم مواقيت الصلاة لشهر كامل + طباعة/مشاركة PDF.
class MonthlyTimesScreen extends StatefulWidget {
  const MonthlyTimesScreen({super.key});

  @override
  State<MonthlyTimesScreen> createState() => _MonthlyTimesScreenState();
}

class _MonthlyTimesScreenState extends State<MonthlyTimesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Governorate? _gov;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    resolvePlace(SettingsRepo()).then((g) => setState(() => _gov = g));
  }

  String get _locale => AppState.isEnglish ? 'en' : 'ar';
  String get _monthTitle =>
      DateFormat('MMMM y', _locale).format(_month);

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  void _shift(int delta) => setState(() =>
      _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('مواقيت الشهر', 'Monthly times')),
        actions: [
          IconButton(
            tooltip: tr('طباعة / مشاركة', 'Print / share'),
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            onPressed: _gov == null || _sharing ? null : _share,
          ),
        ],
      ),
      body: _gov == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () => _shift(-1),
                          icon: const Icon(Icons.chevron_right)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(_monthTitle,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            Text('${_gov!.name} · ${tr('حساب الهيئة المصرية', 'Egyptian authority')}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => _shift(1),
                          icon: const Icon(Icons.chevron_left)),
                    ],
                  ),
                ),
                _headerRow(scheme),
                Expanded(
                  child: ListView.builder(
                    itemCount: _daysInMonth,
                    itemBuilder: (_, i) => _dayRow(i + 1, scheme),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _headerRow(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            _cell(tr('اليوم', 'Day'), bold: true, flex: 2),
            for (var i = 0; i < kPrayerNames.length; i++)
              _cell(prayerNameLabel(i), bold: true, flex: 3),
          ],
        ),
      );

  Widget _dayRow(int day, ColorScheme scheme) {
    final date = DateTime(_month.year, _month.month, day);
    final pr = prayerTimesFor(date, _gov!);
    final isToday = dayKey(date) == dayKey(DateTime.now());
    return Container(
      color: isToday ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          _cell(arNum(day), flex: 2, bold: isToday),
          for (final t in pr.times) _cell(arTime(t), flex: 3),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
        ),
      );

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final rows = <List<String>>[
        ['اليوم', ...kPrayerNames],
        for (var d = 1; d <= _daysInMonth; d++)
          [
            arNum(d),
            ...prayerTimesFor(DateTime(_month.year, _month.month, d), _gov!)
                .times
                .map(arTime),
          ],
      ];

      if (kIsWeb) {
        final text = rows.map((r) => r.join('\t')).join('\n');
        await Share.share('$_monthTitle\n$text');
        return;
      }

      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final font = pw.Font.ttf(fontData);
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => [
          pw.Text('مواقيت الصلاة — $_monthTitle',
              style: pw.TextStyle(font: font, fontSize: 18)),
          pw.Text('${_gov!.name} · حساب الهيئة المصرية العامة للمساحة',
              style: pw.TextStyle(font: font, fontSize: 11)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.sublist(1),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ));
      final bytes = await doc.save();
      final temp = await getTemporaryDirectory();
      final file = File(p.join(temp.path,
          'prayer_times_${_month.year}_${_month.month}.pdf'));
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'مواقيت الصلاة — $_monthTitle');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
