import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/docs_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'doc_form.dart';

class DocsScreen extends StatefulWidget {
  final Widget? drawer;

  const DocsScreen({super.key, this.drawer});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  final _repo = DocsRepo();
  bool _loading = true;
  List<DocItem> _docs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _repo.all();
    // الأقرب انتهاءً (والمنتهي) الأول؛ اللي من غير تاريخ في الآخر.
    docs.sort((a, b) {
      if (a.expiry == null && b.expiry == null) return 0;
      if (a.expiry == null) return 1;
      if (b.expiry == null) return -1;
      return a.expiry!.compareTo(b.expiry!);
    });
    if (!mounted) return;
    setState(() {
      _docs = docs;
      _loading = false;
    });
  }

  /// عدد المستندات المنتهية أو القريبة من الانتهاء (خلال مدة التذكير).
  int _needRenewalCount() {
    final today = dateOnly(DateTime.now());
    var n = 0;
    for (final d in _docs) {
      if (d.expiry == null) continue;
      final days = dateOnly(DateTime.parse(d.expiry!)).difference(today).inDays;
      if (days <= d.remindDays) n++;
    }
    return n;
  }

  Future<void> _openForm([DocItem? d]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => DocForm(doc: d)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(DocItem d) async {
    if (!await confirmDelete(
        context, tr('المستند "${d.title}"', 'document "${d.title}"'))) {
      return;
    }
    await _repo.delete(d.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
          title: Text(tr('خزنة المستندات', 'Documents')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _docs.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.folder_open,
                          actionLabel: tr('ضيف مستند', 'Add document'),
                          onAction: () => _openForm(),
                          text:
                              tr('لسه مفيش مستندات — صور البطاقة والرخصة وأي مستند مهم\nوهفكرك قبل ما ينتهي',
                                  'No documents — snap your ID, license & key papers\nreminded before they expire')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        _renewalBanner(context),
                        for (final d in _docs) _docTile(context, d),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'docs_fab',
        onPressed: () => _openForm(),
        tooltip: tr('مستند جديد', 'New document'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _renewalBanner(BuildContext context) {
    final n = _needRenewalCount();
    if (n == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('${arNum(n)} مستند محتاج تجديد قريب',
                  '${arNum(n)} document(s) need renewal soon'),
              style: TextStyle(
                  color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(BuildContext context, DocItem d) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () => _openForm(d),
        leading: _thumbnail(d, scheme),
        title: Text(d.title),
        subtitle: _expiryLine(d, scheme),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                await _openForm(d);
              case 'delete':
                await _delete(d);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(DocItem d, ColorScheme scheme) {
    if (d.imagePath.isEmpty) {
      return CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(Icons.description_outlined,
            color: scheme.onSecondaryContainer),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(d.imagePath),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.broken_image_outlined,
              color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }

  Widget _expiryLine(DocItem d, ColorScheme scheme) {
    if (d.expiry == null) {
      return Text(tr('من غير تاريخ انتهاء', 'No expiry date'),
          style: TextStyle(color: scheme.outline));
    }
    final expiry = DateTime.parse(d.expiry!);
    final days = dateOnly(expiry).difference(dateOnly(DateTime.now())).inDays;
    final String label;
    final Color color;
    if (days < 0) {
      label = tr('منتهي من ${arNum(-days)} يوم — ${arShortDate(expiry)}',
          'Expired ${arNum(-days)} days ago — ${arShortDate(expiry)}');
      color = scheme.error;
    } else if (days == 0) {
      label = tr('ينتهي النهارده!', 'Expires today!');
      color = scheme.error;
    } else if (days <= d.remindDays) {
      label = tr('باقي ${arNum(days)} يوم — ${arShortDate(expiry)}',
          '${arNum(days)} days left — ${arShortDate(expiry)}');
      color = scheme.tertiary;
    } else {
      label = tr('ينتهي ${arShortDate(expiry)}', 'Expires ${arShortDate(expiry)}');
      color = scheme.outline;
    }
    return Text(label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600));
  }
}
