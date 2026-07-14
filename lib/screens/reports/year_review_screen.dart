import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/year_review.dart';

/// المراجعة السنوية — ملخّص سنتك عبر كل البنود + تصدير PDF.
class YearReviewScreen extends StatefulWidget {
  const YearReviewScreen({super.key});

  @override
  State<YearReviewScreen> createState() => _YearReviewScreenState();
}

class _YearReviewScreenState extends State<YearReviewScreen> {
  int _year = DateTime.now().year;
  bool _loading = true;
  List<YearStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await collectYearReview(_year);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('المراجعة السنوية', 'Year in review')),
        actions: [
          if (!kIsWeb)
            IconButton(
              tooltip: tr('تصدير PDF', 'Export PDF'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    setState(() => _year--);
                    _load();
                  },
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Center(
                  child: Text(arNum(_year),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
              IconButton(
                  onPressed: _year >= DateTime.now().year
                      ? null
                      : () {
                          setState(() => _year++);
                          _load();
                        },
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final s in _stats)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 2),
                                Text(s.value,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900)),
                                Text(s.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11, color: scheme.outline)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();
    doc.addPage(pw.Page(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('المراجعة السنوية — ${arNum(_year)}',
              style: pw.TextStyle(font: font, fontSize: 20)),
          pw.SizedBox(height: 4),
          pw.Text('اتولّدت تلقائيًا من تطبيق My Assistant.',
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['البند', 'القيمة'],
            cellStyle: pw.TextStyle(font: font, fontSize: 12),
            headerStyle: pw.TextStyle(
                font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0F2EC)),
            cellAlignment: pw.Alignment.centerRight,
            data: [
              for (final s in _stats) ['${s.emoji} ${s.label}', s.value],
            ],
          ),
        ],
      ),
    ));
    final bytes = await doc.save();
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, 'year_review_$_year.pdf'));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: tr('مراجعتى السنوية ${arNum(_year)}',
            'My $_year in review'));
  }
}
