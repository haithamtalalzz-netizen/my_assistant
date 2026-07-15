import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/section_pdf.dart';
import '../../data/vaccinations_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/wheel_date_picker.dart';

/// سجل التطعيمات — تطعيمات بشرية بتاريخها وجرعتها الجاية، مع تذكير قبلها بأسبوع.
class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final _repo = VaccinationsRepo();
  bool _loading = true;
  List<Vaccination> _items = [];

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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('سجل التطعيمات', 'Vaccinations')),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: tr('تقرير PDF', 'PDF report'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.vaccines_outlined,
                          text: tr(
                              'سجّل تطعيماتك وتطعيمات العيلة — وهفكرك بالجرعة الجاية',
                              'Log your & your family vaccines — reminded before next dose')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final v in _items) _tile(v)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('تطعيم جديد', 'New vaccine'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportPdf() async {
    await SectionPdf.share(
      title: tr('سجل التطعيمات', 'Vaccinations'),
      headers: [
        tr('التطعيم', 'Vaccine'),
        tr('لمين', 'For'),
        tr('التاريخ', 'Date'),
        tr('الجرعة الجاية', 'Next dose'),
      ],
      rows: [
        for (final v in _items)
          [
            v.name,
            v.person,
            v.date,
            v.nextDue,
          ]
      ],
    );
  }

  Widget _tile(Vaccination v) {
    final scheme = Theme.of(context).colorScheme;
    final days = v.daysLeft;
    final (color, statusText) = switch (days) {
      null => (scheme.outline, ''),
      < 0 => (scheme.error, tr('فاتت من ${arNum(-days)} يوم', 'Overdue ${arNum(-days)}d')),
      0 => (scheme.error, tr('الجرعة النهاردة', 'Dose today')),
      <= 30 => (Colors.orange, tr('الجرعة بعد ${arNum(days)} يوم', 'Dose in ${arNum(days)}d')),
      _ => (Colors.green, tr('الجرعة بعد ${arNum(days)} يوم', 'Dose in ${arNum(days)}d')),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.vaccines, color: color),
        ),
        title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (v.person.trim().isNotEmpty) v.person,
          if (DateTime.tryParse(v.date) != null)
            tr('اتاخدت ${arShortDate(DateTime.parse(v.date))}',
                'Taken ${arShortDate(DateTime.parse(v.date))}'),
          if (statusText.isNotEmpty) statusText,
          if (v.notes.trim().isNotEmpty) v.notes,
        ].join('  •  '),
            style: statusText.isEmpty
                ? null
                : TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: PopupMenuButton<String>(
          onSelected: (sel) async {
            if (sel == 'edit') await _form(v);
            if (sel == 'delete') {
              if (!mounted) return;
              if (await confirmDelete(context, '"${v.name}"')) {
                await _repo.delete(v.id!);
                if (mounted) await _load();
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _form(v),
      ),
    );
  }

  Future<void> _form([Vaccination? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final person = TextEditingController(text: item?.person ?? '');
    final notes = TextEditingController(text: item?.notes ?? '');
    DateTime? taken = DateTime.tryParse(item?.date ?? '');
    DateTime? next = DateTime.tryParse(item?.nextDue ?? '');

    Future<DateTime?> pick(DateTime? initial) => pickWheelDate(
          context,
          initial: initial ?? DateTime.now(),
          first: DateTime(2010),
          last: DateTime.now().add(const Duration(days: 365 * 6)),
        );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null
              ? tr('تطعيم جديد', 'New vaccine')
              : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: name,
                  autofocus: item == null,
                  decoration: InputDecoration(
                      labelText: tr('اسم التطعيم', 'Vaccine name'))),
              const SizedBox(height: 10),
              TextField(
                  controller: person,
                  decoration: InputDecoration(
                      labelText: tr('لِمين؟ (اختياري)', 'For whom? (optional)'))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(taken == null
                        ? tr('تاريخ الجرعة: —', 'Dose date: —')
                        : tr('اتاخدت: ${arShortDate(taken!)}',
                            'Taken: ${arShortDate(taken!)}'))),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('التاريخ', 'Date')),
                  onPressed: () async {
                    final d = await pick(taken);
                    if (d != null) setD(() => taken = d);
                  },
                ),
              ]),
              Row(children: [
                Expanded(
                    child: Text(next == null
                        ? tr('الجرعة الجاية: —', 'Next dose: —')
                        : tr('الجاية: ${arShortDate(next!)}',
                            'Next: ${arShortDate(next!)}'))),
                if (next != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setD(() => next = null),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text(tr('حدد', 'Set')),
                  onPressed: () async {
                    final d = await pick(next);
                    if (d != null) setD(() => next = d);
                  },
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: notes,
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

    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.save(Vaccination(
        id: item?.id,
        name: name.text.trim(),
        person: person.text.trim(),
        date: taken == null ? '' : dayKey(taken!),
        nextDue: next == null ? '' : dayKey(next!),
        notes: notes.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    person.dispose();
    notes.dispose();
  }
}
