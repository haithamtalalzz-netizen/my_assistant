import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_images.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/body_progress_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repo = BodyProgressRepo();
  bool _loading = true;
  List<BodyProgress> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repo.all();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
        child: const _ProgressForm(),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  /// فرق قيمة عن السجل الأقدم اللي بعده (لعرض «−٢ كجم»).
  String? _delta(double? current, int index, double? Function(BodyProgress) get) {
    if (current == null) return null;
    for (var i = index + 1; i < _entries.length; i++) {
      final prev = get(_entries[i]);
      if (prev != null) {
        final d = current - prev;
        if (d == 0) return null;
        final sign = d > 0 ? '+' : '−';
        final v = d.abs();
        return '$sign${arNum(v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1))}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التقدّم والمقاسات', 'Progress & measurements')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? EmptyHint(
                  icon: Icons.straighten,
                  text: tr(
                      'سجّل وزنك ومقاساتك وصورة كل فترة — وتابع تغيّرك بالأرقام والصورة',
                      'Log your weight, measurements & a photo periodically — track your change'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    children: [
                      _summaryCard(context),
                      _comparisonCard(context),
                      for (var i = 0; i < _entries.length; i++)
                        _entryCard(context, i),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'progress_fab',
        onPressed: _addEntry,
        tooltip: tr('سجل جديد', 'New entry'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// كارت علوي: الوزن الحالي + إجمالي التغيّر من أول تسجيل.
  Widget _summaryCard(BuildContext context) {
    // الأحدث أول في _entries؛ ناخد أول وزن من فوق وآخر وزن من تحت.
    double? current;
    for (final e in _entries) {
      if (e.weight != null) {
        current = e.weight;
        break;
      }
    }
    double? first;
    for (final e in _entries.reversed) {
      if (e.weight != null) {
        first = e.weight;
        break;
      }
    }
    if (current == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final change = (first != null && current != first) ? current - first : null;
    String fmt(double v) =>
        arNum(v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(tr('الوزن الحالي', 'Current weight'),
                  style: TextStyle(color: scheme.outline)),
            ),
            Text('${fmt(current)} ${tr('كجم', 'kg')}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (change != null) ...[
              const SizedBox(width: 8),
              Text(
                  '(${change < 0 ? '−' : '+'}${fmt(change.abs())})',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: change < 0 ? Colors.green : scheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  /// مقارنة «قبل / بعد» تلقائية: أقدم صورة مقابل أحدث صورة + فرق الوزن
  /// والأيام بينهم. بتظهر لوحدها لما يبقى فيه صورتين على الأقل.
  Widget _comparisonCard(BuildContext context) {
    // الأحدث أول فى _entries. أحدث سجل بصورة + أقدم سجل بصورة.
    BodyProgress? latest;
    for (final e in _entries) {
      if (e.photo.isNotEmpty) {
        latest = e;
        break;
      }
    }
    BodyProgress? first;
    for (final e in _entries.reversed) {
      if (e.photo.isNotEmpty) {
        first = e;
        break;
      }
    }
    if (first == null || latest == null || first.id == latest.id) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final d1 = DateTime.parse(first.day);
    final d2 = DateTime.parse(latest.day);
    final days = d2.difference(d1).inDays;
    final wChange = (first.weight != null && latest.weight != null)
        ? latest.weight! - first.weight!
        : null;
    String fmt(double v) =>
        arNum(v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('📸', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(tr('قبل / بعد', 'Before / after'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (days > 0)
                Text(tr('فرق ${arNum(days)} يوم', '${arNum(days)} days apart'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _comparePane(context, first, tr('قبل', 'Before'))),
                const SizedBox(width: 8),
                Expanded(child: _comparePane(context, latest, tr('بعد', 'After'))),
              ],
            ),
            if (wChange != null && wChange != 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  wChange < 0
                      ? tr('نزلت ${fmt(wChange.abs())} كجم 💪',
                          'Down ${fmt(wChange.abs())} kg 💪')
                      : tr('زودت ${fmt(wChange.abs())} كجم',
                          'Up ${fmt(wChange.abs())} kg'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: wChange < 0 ? Colors.green : scheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _comparePane(BuildContext context, BodyProgress e, String tag) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: AppImage(e.photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: scheme.surfaceContainerHighest)),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(arShortDate(DateTime.parse(e.day)),
            style: TextStyle(fontSize: 11, color: scheme.outline)),
        if (e.weight != null)
          Text(
              '${arNum(e.weight! % 1 == 0 ? e.weight!.toInt() : e.weight!.toStringAsFixed(1))} ${tr('كجم', 'kg')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _entryCard(BuildContext context, int i) {
    final e = _entries[i];
    final scheme = Theme.of(context).colorScheme;
    Widget metric(String label, double? value, String? delta, String unit) {
      if (value == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(label,
                style: TextStyle(color: scheme.outline, fontSize: 13))),
            Text(
                '${arNum(value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1))} $unit',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (delta != null) ...[
              const SizedBox(width: 8),
              Text('($delta)',
                  style: TextStyle(
                      fontSize: 12,
                      color: delta.startsWith('−') ? Colors.green : scheme.error)),
            ],
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.photo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppImage(e.photo,
                    width: 72,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const SizedBox(width: 72, height: 96)),
              ),
            if (e.photo.isNotEmpty) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(arFullDate(DateTime.parse(e.day)),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: tr('حذف', 'Delete'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          if (!await confirmDelete(
                              context, tr('السجل ده', 'this entry'))) {
                            return;
                          }
                          await _repo.delete(e.id!);
                          if (mounted) await _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  metric(tr('الوزن', 'Weight'), e.weight,
                      _delta(e.weight, i, (x) => x.weight), tr('كجم', 'kg')),
                  metric(tr('الوسط', 'Waist'), e.waist,
                      _delta(e.waist, i, (x) => x.waist), tr('سم', 'cm')),
                  metric(tr('الصدر', 'Chest'), e.chest,
                      _delta(e.chest, i, (x) => x.chest), tr('سم', 'cm')),
                  metric(tr('الذراع', 'Arms'), e.arms,
                      _delta(e.arms, i, (x) => x.arms), tr('سم', 'cm')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressForm extends StatefulWidget {
  const _ProgressForm();

  @override
  State<_ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends State<_ProgressForm> {
  final _weight = TextEditingController();
  final _waist = TextEditingController();
  final _chest = TextEditingController();
  final _arms = TextEditingController();
  String _photo = '';

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _chest.dispose();
    _arms.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final stored = await AppImages.pickAndStore(source,
        maxWidth: 1600, namePrefix: 'prog');
    if (stored == null) return;
    if (mounted) setState(() => _photo = stored);
  }

  Future<void> _save() async {
    final b = BodyProgress(
      day: dayKey(DateTime.now()),
      weight: parseNumber(_weight.text),
      waist: parseNumber(_waist.text),
      chest: parseNumber(_chest.text),
      arms: parseNumber(_arms.text),
      photo: _photo,
    );
    if (b.weight == null &&
        b.waist == null &&
        b.chest == null &&
        b.arms == null &&
        b.photo.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    await BodyProgressRepo().add(b);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('سجل تقدّم جديد', 'New progress entry'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _num(_weight, tr('الوزن (كجم)', 'Weight (kg)'))),
              const SizedBox(width: 8),
              Expanded(child: _num(_waist, tr('الوسط (سم)', 'Waist (cm)'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _num(_chest, tr('الصدر (سم)', 'Chest (cm)'))),
              const SizedBox(width: 8),
              Expanded(child: _num(_arms, tr('الذراع (سم)', 'Arms (cm)'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_photo.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(_photo,
                        width: 48, height: 48, fit: BoxFit.cover),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(tr('صورة', 'Photo')),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: Icon(Icons.photo_library_outlined,
                    size: 18, color: scheme.primary),
                label: Text(tr('معرض', 'Gallery')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ),
        ],
      ),
    );
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, isDense: true),
      );
}
