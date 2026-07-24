
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../data/settings_repo.dart';
import '../../widgets/search_action.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/file_out.dart';
import '../../core/section_pdf.dart';
import '../../data/docs_repo.dart';
import '../../data/money_repo.dart';
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
  final _auth = LocalAuthentication();
  bool _loading = true;
  List<DocItem> _docs = [];

  /// فلتر النوع (null = الكل).
  String? _typeFilter;

  /// القفل بالبصمة — اختيارى من الإعدادات. `_authed` بيبقى true على طول
  /// لو القفل مقفول، فالشاشة مابتتغيّرش لمين مش مفعّله.
  bool _authed = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final locked = (await SettingsRepo().get(kDocsLockSetting)) == '1';
    if (!locked) {
      await _load();
      return;
    }
    var ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: tr('افتح خزنة المستندات', 'Unlock documents'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      logError('فشل فتح المستندات', e);
    }
    if (!mounted) return;
    if (ok) {
      await _load();
    } else {
      setState(() {
        _authed = false;
        _loading = false;
      });
    }
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
          actions: [
            IconButton(
              tooltip: tr('تصدير PDF', 'Export PDF'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _docs.isEmpty ? null : _exportPdf,
            ),
            searchAction(context),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authed
              ? _lockedView(context)
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
                        _typeFilterBar(context),
                        for (final d in _visibleDocs) _docTile(context, d),
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

  /// المستندات المعروضة بعد فلتر النوع.
  List<DocItem> get _visibleDocs =>
      _typeFilter == null ? _docs : _docs.where((d) => d.type == _typeFilter).toList();

  /// شرايط النوع — بتظهر بس لما يبقى فيه أكتر من نوع (مالهاش لازمة قبل كده).
  Widget _typeFilterBar(BuildContext context) {
    final present = _docs.map((d) => d.type).toSet().toList()
      ..sort((a, b) => kDocTypes.indexOf(a).compareTo(kDocTypes.indexOf(b)));
    if (present.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: Text(tr('الكل', 'All')),
              selected: _typeFilter == null,
              onSelected: (_) => setState(() => _typeFilter = null),
            ),
            for (final t in present) ...[
              const SizedBox(width: 6),
              ChoiceChip(
                avatar: Icon(docTypeIcon(t), size: 16),
                label: Text(docTypeLabel(t)),
                selected: _typeFilter == t,
                onSelected: (_) => setState(() => _typeFilter = t),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lockedView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 56, color: scheme.primary),
          const SizedBox(height: 12),
          Text(tr('المستندات مقفولة', 'Documents are locked')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.fingerprint),
            label: Text(tr('افتح', 'Unlock')),
          ),
        ],
      ),
    );
  }

  /// «جدّدته ✓» — بينقل الإصدار للنهارده (فالانتهاء بيتحسب لوحده)،
  /// ولو فيه تكلفة تجديد بيسجّلها مصروف فى الفلوس.
  ///
  /// التسجيل فى الفلوس **بيتسأل عليه** — إضافة مصروف من ورا المستخدم
  /// بتلخبط ميزانيته.
  Future<void> _renew(DocItem d) async {
    final today = DateTime.now();
    final hasCost = d.renewCost > 0;
    final ok = await confirmAction(
      context,
      title: tr('جدّدت «${d.title}»؟', 'Renewed "${d.title}"?'),
      message: hasCost
          ? tr(
              'هحدّث تاريخ الإصدار للنهارده (والانتهاء هيتحسب لوحده)، '
              'وهسجّل ${egp(d.renewCost)} مصروف تجديد فى الفلوس.',
              "I'll set the issue date to today (expiry recalculates) and log "
              '${egp(d.renewCost)} as a renewal expense.')
          : tr('هحدّث تاريخ الإصدار للنهارده، والانتهاء هيتحسب لوحده.',
              "I'll set the issue date to today; expiry recalculates."),
      confirmLabel: tr('جدّدته', 'Renewed'),
    );
    if (!ok) return;
    await _repo.save(DocItem(
      id: d.id,
      title: d.title,
      imagePath: d.imagePath,
      images: d.images,
      // الانتهاء المكتوب بإيد بيتشال عشان المحسوب من الإصدار الجديد يشتغل.
      expiry: null,
      remindDays: d.remindDays,
      notes: d.notes,
      type: d.type,
      docNumber: d.docNumber,
      issuer: d.issuer,
      owner: d.owner,
      issued: dayKey(today),
      validYears: d.validYears,
      renewCost: d.renewCost,
    ));
    if (hasCost) {
      await MoneyRepo().add(Expense(
        amount: d.renewCost,
        category: 'أخرى',
        note: tr('تجديد ${d.title}', 'Renewed ${d.title}'),
        day: dayKey(today),
      ));
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(hasCost
            ? tr('اتجدّد واتسجّل فى الفلوس ✓', 'Renewed & logged ✓')
            : tr('اتجدّد ✓', 'Renewed ✓'))));
  }

  /// تصدير كل المستندات PDF — للمراجعة أو الطباعة.
  Future<void> _exportPdf() async {
    await SectionPdf.share(
      title: tr('خزنة المستندات', 'Documents'),
      headers: [
        tr('المستند', 'Document'),
        tr('النوع', 'Type'),
        tr('الرقم', 'Number'),
        tr('لمين', 'Owner'),
        tr('الانتهاء', 'Expiry'),
      ],
      rows: [
        for (final d in _visibleDocs)
          [
            d.title,
            docTypeLabel(d.type),
            d.docNumber,
            d.owner.trim().isEmpty ? tr('أنا', 'Me') : d.owner,
            d.effectiveExpiry ?? '—',
          ],
      ],
    );
  }

  /// بيشارك صور المستند برّه التطبيق — صورة واحدة تتشارك كصورة، وأكتر
  /// من واحدة بتتجمّع PDF (صفحة لكل صورة) عشان تطلع ملف واحد مرتّب.
  Future<void> _share(DocItem d) async {
    final imgs = d.allImages;
    if (imgs.isEmpty) return;
    final safe = d.title.replaceAll(RegExp(r'[^\w؀-ۿ ]'), '').trim();
    try {
      if (imgs.length == 1) {
        final bytes = await AppImages.bytesOf(imgs.first);
        if (bytes == null) throw StateError('no bytes');
        await deliverFile('$safe.jpg', 'image/jpeg', bytes);
      } else {
        final doc = pw.Document();
        for (final path in imgs) {
          final bytes = await AppImages.bytesOf(path);
          if (bytes == null) continue;
          doc.addPage(pw.Page(
            build: (_) => pw.Center(
                child: pw.Image(pw.MemoryImage(bytes),
                    fit: pw.BoxFit.contain)),
          ));
        }
        await deliverFile('$safe.pdf', 'application/pdf', await doc.save());
      }
    } on Exception catch (e) {
      logError('فشل مشاركة المستند', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('حصلت مشكلة', 'Something went wrong'))));
      }
    }
  }

  Widget _docTile(BuildContext context, DocItem d) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () => _openForm(d),
        leading: _thumbnail(d, scheme),
        title: Text(d.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _expiryLine(d, scheme),
            if (d.docNumber.trim().isNotEmpty || d.owner.trim().isNotEmpty)
              Text(
                [
                  if (d.docNumber.trim().isNotEmpty) d.docNumber,
                  if (d.owner.trim().isNotEmpty) d.owner,
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                await _openForm(d);
              case 'share':
                await _share(d);
              case 'renew':
                await _renew(d);
              case 'delete':
                await _delete(d);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            if (d.allImages.isNotEmpty)
              PopupMenuItem(
                  value: 'share', child: Text(tr('شارك 📤', 'Share 📤'))),
            if (d.validYears > 0)
              PopupMenuItem(
                  value: 'renew', child: Text(tr('جدّدته ✓', 'Renewed ✓'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(DocItem d, ColorScheme scheme) {
    if (d.imagePath.isEmpty) {
      // أيقونة النوع بدل أيقونة عامة — بتخلّى القايمة تتقري بنظرة.
      return CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(docTypeIcon(d.type), color: scheme.onSecondaryContainer),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AppImage(d.imagePath,
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
