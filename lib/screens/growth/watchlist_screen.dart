import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/watchlist_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// قائمة المشاهدة — أفلام ومسلسلات.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

String _statusLabel(String s) => switch (s) {
      'watching' => tr('بتفرّج', 'Watching'),
      'done' => tr('اتفرجت', 'Watched'),
      _ => tr('هتفرّجه', 'Want to watch'),
    };

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _repo = WatchlistRepo();
  bool _loading = true;
  List<WatchItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('قائمة المشاهدة', 'Watchlist'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.movie_outlined,
                          text: tr('ضيف فيلم أو مسلسل بزرار +',
                              'Add a movie or series with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final w in _items) _tile(w, scheme)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('إضافة', 'Add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(WatchItem w, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(
            w.kind == 'series' ? Icons.live_tv_outlined : Icons.movie_outlined,
            color: scheme.primary),
        title: Text(w.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration:
                    w.status == 'done' ? TextDecoration.lineThrough : null,
                color: w.status == 'done' ? scheme.outline : null)),
        subtitle: Text([
          w.kind == 'series' ? tr('مسلسل', 'Series') : tr('فيلم', 'Movie'),
          _statusLabel(w.status),
          if (w.note.isNotEmpty) w.note,
        ].join('  •  ')),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _form(w);
            if (v == 'delete') {
              await _repo.delete(w.id!);
              await _load();
            }
            if (v == 'want' || v == 'watching' || v == 'done') {
              await _repo.setStatus(w.id!, v);
              await _load();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'want', child: Text(tr('هتفرّجه', 'Want to watch'))),
            PopupMenuItem(value: 'watching', child: Text(tr('بتفرّج', 'Watching'))),
            PopupMenuItem(value: 'done', child: Text(tr('اتفرجت', 'Watched'))),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _form(w),
      ),
    );
  }

  Future<void> _form([WatchItem? item]) async {
    final title = TextEditingController(text: item?.title ?? '');
    final note = TextEditingController(text: item?.note ?? '');
    var kind = item?.kind ?? 'movie';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null ? tr('إضافة', 'Add') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: title,
                  autofocus: item == null,
                  decoration: InputDecoration(labelText: tr('العنوان', 'Title'))),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [
                ChoiceChip(
                    label: Text(tr('فيلم', 'Movie')),
                    selected: kind == 'movie',
                    onSelected: (_) => setD(() => kind = 'movie')),
                ChoiceChip(
                    label: Text(tr('مسلسل', 'Series')),
                    selected: kind == 'series',
                    onSelected: (_) => setD(() => kind = 'series')),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: tr('ملاحظة', 'Note'))),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(WatchItem(
        id: item?.id,
        title: title.text.trim(),
        kind: kind,
        status: item?.status ?? 'want',
        note: note.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    note.dispose();
  }
}
