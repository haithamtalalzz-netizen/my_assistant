import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/symptoms_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// مفكرة الأعراض — سجّل أعراضك بشدّتها؛ تفيد فى متابعة حالتك وتجهيز زيارة الدكتور.
class SymptomJournalScreen extends StatefulWidget {
  const SymptomJournalScreen({super.key});

  @override
  State<SymptomJournalScreen> createState() => _SymptomJournalScreenState();
}

Color _sevColor(int s) => switch (s) {
      1 => Colors.green,
      2 => Colors.lightGreen,
      3 => Colors.orange,
      4 => Colors.deepOrange,
      _ => Colors.red,
    };

String _sevLabel(int s) => switch (s) {
      1 => tr('خفيف جدًا', 'Very mild'),
      2 => tr('خفيف', 'Mild'),
      3 => tr('متوسط', 'Moderate'),
      4 => tr('شديد', 'Severe'),
      _ => tr('شديد جدًا', 'Very severe'),
    };

class _SymptomJournalScreenState extends State<SymptomJournalScreen> {
  final _repo = SymptomsRepo();
  bool _loading = true;
  List<SymptomLog> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.recent();
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
      appBar: AppBar(title: Text(tr('مفكرة الأعراض', 'Symptom journal'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.sick_outlined,
                          text: tr('سجّل أى عرض بتحسّه بزرار +',
                              'Log any symptom with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final s in _items) _tile(s, scheme)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('عرض جديد', 'New symptom'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(SymptomLog s, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _sevColor(s.severity).withValues(alpha: 0.18),
          child: Text(arNum(s.severity),
              style: TextStyle(
                  color: _sevColor(s.severity), fontWeight: FontWeight.w800)),
        ),
        title: Text(s.symptom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          arShortDate(DateTime.parse(s.day)),
          _sevLabel(s.severity),
          if (s.note.isNotEmpty) s.note,
        ].join('  •  ')),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _form(s);
            if (v == 'delete') {
              await _repo.delete(s.id!);
              await _load();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _form(s),
      ),
    );
  }

  Future<void> _form([SymptomLog? item]) async {
    final symptom = TextEditingController(text: item?.symptom ?? '');
    final note = TextEditingController(text: item?.note ?? '');
    var severity = item?.severity ?? 3;
    DateTime day = item == null ? DateTime.now() : DateTime.parse(item.day);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null ? tr('عرض جديد', 'New symptom') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: symptom,
                  autofocus: item == null,
                  decoration: InputDecoration(
                      labelText: tr('العرض (صداع، مغص…)', 'Symptom (headache…)'))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(tr('الشدّة:', 'Severity:')),
                  const SizedBox(width: 6),
                  Text('${arNum(severity)} — ${_sevLabel(severity)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _sevColor(severity))),
                ],
              ),
              Slider(
                value: severity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$severity',
                activeColor: _sevColor(severity),
                onChanged: (v) => setD(() => severity = v.round()),
              ),
              Row(children: [
                Expanded(child: Text(arShortDate(day))),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('التاريخ', 'Date')),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: day,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setD(() => day = d);
                  },
                ),
              ]),
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

    if (saved == true && symptom.text.trim().isNotEmpty) {
      await _repo.save(SymptomLog(
        id: item?.id,
        day: dayKey(day),
        symptom: symptom.text.trim(),
        severity: severity,
        note: note.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    symptom.dispose();
    note.dispose();
  }
}
