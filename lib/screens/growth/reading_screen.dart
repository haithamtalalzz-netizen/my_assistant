import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/reading_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// تتبّع القراءة — كتبك وتقدّمك فيها.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

String _bookStatusLabel(String s) => switch (s) {
      'done' => tr('خلصته', 'Finished'),
      'wishlist' => tr('قائمة أمنيات', 'Wishlist'),
      _ => tr('بقرأه', 'Reading'),
    };

class _ReadingScreenState extends State<ReadingScreen> {
  final _repo = ReadingRepo();
  bool _loading = true;
  List<Book> _books = [];
  int _finished = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await _repo.all();
    final finished = await _repo.finishedCount();
    if (!mounted) return;
    setState(() {
      _books = books;
      _finished = finished;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('القراءة', 'Reading'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _books.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.menu_book_outlined,
                          text: tr('ضيف كتاب بتقرأه بزرار +',
                              'Add a book with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [
                        if (_finished > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                                tr('📚 خلّصت ${arNum(_finished)} كتاب',
                                    '📚 ${arNum(_finished)} books finished'),
                                style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        for (final b in _books) _card(b, scheme),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('كتاب جديد', 'New book'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card(Book b, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: b.status == 'done' ? scheme.outline : null)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') await _form(b);
                    if (v == 'delete') {
                      await _repo.delete(b.id!);
                      await _load();
                    }
                    if (v == 'reading' || v == 'done' || v == 'wishlist') {
                      await _repo.setStatus(b.id!, v);
                      await _load();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'reading', child: Text(tr('بقرأه', 'Reading'))),
                    PopupMenuItem(value: 'done', child: Text(tr('خلصته', 'Finished'))),
                    PopupMenuItem(value: 'wishlist', child: Text(tr('قائمة أمنيات', 'Wishlist'))),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                    PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            if (b.author.isNotEmpty)
              Text(b.author,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: b.progress, minHeight: 7),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                    b.totalPages == 0
                        ? _bookStatusLabel(b.status)
                        : tr('${arNum(b.currentPage)}/${arNum(b.totalPages)} ص · ${_bookStatusLabel(b.status)}',
                            '${arNum(b.currentPage)}/${arNum(b.totalPages)} pp · ${_bookStatusLabel(b.status)}'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                const Spacer(),
                if (b.totalPages > 0 && b.status != 'wishlist')
                  TextButton(
                    onPressed: () => _updatePage(b),
                    child: Text(tr('حدّث الصفحة', 'Update page')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePage(Book b) async {
    final ctrl = TextEditingController(text: '${b.currentPage}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('وصلت صفحة كام؟', 'Current page?')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              hintText: tr('من ${arNum(b.totalPages)}', 'of ${arNum(b.totalPages)}')),
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
    );
    if (ok == true) {
      await _repo.setPage(
          b, int.tryParse(toEnglishDigits(ctrl.text.trim())) ?? b.currentPage);
      await _load();
    }
    ctrl.dispose();
  }

  Future<void> _form([Book? book]) async {
    final title = TextEditingController(text: book?.title ?? '');
    final author = TextEditingController(text: book?.author ?? '');
    final total = TextEditingController(
        text: book == null || book.totalPages == 0 ? '' : '${book.totalPages}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(book == null ? tr('كتاب جديد', 'New book') : tr('تعديل', 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                autofocus: book == null,
                decoration: InputDecoration(labelText: tr('العنوان', 'Title'))),
            const SizedBox(height: 8),
            TextField(
                controller: author,
                decoration: InputDecoration(labelText: tr('المؤلف', 'Author'))),
            const SizedBox(height: 8),
            TextField(
                controller: total,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: tr('عدد الصفحات', 'Total pages'))),
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
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(Book(
        id: book?.id,
        title: title.text.trim(),
        author: author.text.trim(),
        totalPages: int.tryParse(toEnglishDigits(total.text.trim())) ?? 0,
        currentPage: book?.currentPage ?? 0,
        status: book?.status ?? 'reading',
        note: book?.note ?? '',
        createdAt: book?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    author.dispose();
    total.dispose();
  }
}
