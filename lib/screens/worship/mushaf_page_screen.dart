import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';
import '../../data/settings_repo.dart';

/// عرض صفحات المصحف كصور (مصحف المدينة) — بث + تخزين تلقائى، وتحميل كامل اختيارى.
class MushafPageScreen extends StatefulWidget {
  final int startPage;
  const MushafPageScreen({super.key, this.startPage = 1});

  @override
  State<MushafPageScreen> createState() => _MushafPageScreenState();
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
  }

  @override
  void dispose() {
    _settings.setQuranLastPage(_page);
    _controller.dispose();
    super.dispose();
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
          decoration:
              InputDecoration(hintText: tr('1 - 604', '1 - 604')),
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
    if (n != null && n >= 1 && n <= kMushafPages) {
      _controller.jumpToPage(n - 1);
    }
  }

  Future<void> _downloadAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('تحميل المصحف كامل', 'Download full mushaf')),
        content: Text(tr(
            'هيحمّل 604 صفحة (~21 ميجا) للقراءة بدون نت. تأكد من الاتصال بالواى فاى.',
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
      Navigator.pop(context); // اقفل التقدّم
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
            tooltip: tr('تحميل المصحف كامل', 'Download full mushaf'),
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _downloadAll,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: kMushafPages,
        onPageChanged: (i) => setState(() => _page = i + 1),
        itemBuilder: (_, i) => Container(
          color: Colors.white,
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
                      tr('تعذّر تحميل الصفحة — تحقق من الاتصال بالإنترنت',
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
      bottomNavigationBar: BottomAppBar(
        height: 46,
        padding: EdgeInsets.zero,
        child: Center(
          child: Text(
            tr('صفحة ${arNum(_page)} من ${arNum(kMushafPages)}',
                'Page ${arNum(_page)} of ${arNum(kMushafPages)}'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
