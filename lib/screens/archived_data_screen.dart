import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/archived_data.dart';
import '../core/l10n.dart';
import '../core/log.dart';
import '../widgets/common.dart';

/// «استرجاع البيانات المؤرشفة» — البنود اللى اتشالت من التطبيق بياناتها
/// اتحفظت وقت الترقية (مااتمسحتش). الشاشة دى بتوريها وبتصدّرها JSON.
class ArchivedDataScreen extends StatefulWidget {
  const ArchivedDataScreen({super.key});

  @override
  State<ArchivedDataScreen> createState() => _ArchivedDataScreenState();
}

class _ArchivedDataScreenState extends State<ArchivedDataScreen> {
  List<ArchivedEntry> _items = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ArchivedData.list();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final ok = await ArchivedData.shareExport();
      if (!ok) _toast(tr('مفيش حاجة مؤرشفة', 'Nothing archived'));
    } on Exception catch (e, st) {
      logError('فشل تصدير الأرشيف', e, st);
      _toast(tr('فشل التصدير', 'Export failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAll() async {
    final sure = await confirmAction(
      context,
      title: tr('مسح الأرشيف نهائيًا؟', 'Delete archive permanently?'),
      message: tr(
          'البيانات دى مش هتترجع تانى. صدّرها الأول لو ممكن تحتاجها.',
          "This can't be undone. Export it first if you might need it."),
      confirmLabel: tr('امسح', 'Delete'),
    );
    if (!sure) return;
    setState(() => _busy = true);
    final n = await ArchivedData.deleteAll();
    await _load();
    if (mounted) setState(() => _busy = false);
    _toast(tr('اتمسح ${arNum(n)} بند', 'Deleted ${arNum(n)} sections'));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _items.fold<int>(0, (a, b) => a + b.rowCount);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('البيانات المؤرشفة', 'Archived data')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.inventory_2_outlined,
                  text: tr(
                      'مفيش بيانات مؤرشفة — يعنى مكانش عندك حاجة مسجّلة فى البنود اللى اتشالت.',
                      'Nothing archived — you had no data in the removed sections.'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('${arNum(_items.length)} بند · ${arNum(total)} سجل',
                                  '${arNum(_items.length)} sections · ${arNum(total)} records'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr(
                                  'البنود دى اتشالت من التطبيق، لكن بياناتك اتحفظت هنا ومابتتمسحش. صدّرها ملف JSON تقدر تفتحه أو تحتفظ بيه.',
                                  'These sections were removed from the app, but your data was kept here. Export it as a JSON file you can open or keep.'),
                              style: TextStyle(
                                  fontSize: 12.5, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final it in _items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primary.withValues(alpha: .12),
                            child: Icon(Icons.inventory_2_outlined,
                                color: scheme.primary, size: 20),
                          ),
                          title: Text(it.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(tr(
                              '${arNum(it.rowCount)} سجل${it.archivedAt.isEmpty ? '' : ' · ${_when(it.archivedAt)}'}',
                              '${arNum(it.rowCount)} records${it.archivedAt.isEmpty ? '' : ' · ${_when(it.archivedAt)}'}')),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _export,
                      icon: const Icon(Icons.ios_share),
                      label: Text(tr('تصدير الكل (JSON)', 'Export all (JSON)')),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _deleteAll,
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      label: Text(
                          tr('مسح الأرشيف نهائيًا', 'Delete archive permanently'),
                          style: TextStyle(color: scheme.error)),
                    ),
                  ],
                ),
    );
  }

  String _when(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : arShortDate(d);
  }
}
