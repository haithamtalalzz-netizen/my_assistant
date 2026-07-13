import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/renewals_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// التجديدات — وثائق (بطاقة/جواز/رخصة/تأمين) بتنتهى، مع تنبيه قبل الموعد.
class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> {
  final _repo = RenewalsRepo();
  bool _loading = true;
  List<Renewal> _items = [];

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
      appBar: AppBar(title: Text(tr('التجديدات', 'Renewals'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.badge_outlined,
                          text: tr(
                              'ضيف بطاقتك ورخصتك وجوازك — وهفكرك قبل ما تنتهى',
                              'Add your ID, license & passport — reminded before expiry')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final r in _items) _tile(r)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('تجديد جديد', 'New renewal'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tile(Renewal r) {
    final scheme = Theme.of(context).colorScheme;
    final days = r.daysLeft;
    final (color, statusText) = switch (days) {
      null => (scheme.outline, ''),
      < 0 => (scheme.error, tr('انتهت من ${arNum(-days)} يوم', 'Expired ${arNum(-days)}d ago')),
      0 => (scheme.error, tr('تنتهى النهاردة', 'Expires today')),
      <= 30 => (Colors.orange, tr('باقى ${arNum(days)} يوم', '${arNum(days)}d left')),
      _ => (Colors.green, tr('باقى ${arNum(days)} يوم', '${arNum(days)}d left')),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.event_available, color: color),
        ),
        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          renewalTypeLabel(r.type),
          if (r.expiryDate != null) arShortDate(r.expiryDate!),
          statusText,
        ].where((s) => s.isNotEmpty).join('  •  '),
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _form(r);
            if (v == 'delete') {
              if (!mounted) return;
              if (await confirmDelete(context, tr('"${r.title}"', '"${r.title}"'))) {
                await _repo.delete(r.id!);
                if (mounted) await _load();
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _form(r),
      ),
    );
  }

  Future<void> _form([Renewal? item]) async {
    final title = TextEditingController(text: item?.title ?? '');
    final notes = TextEditingController(text: item?.notes ?? '');
    var type = item?.type ?? kRenewalTypes.first;
    var remindDays = item?.remindDays ?? 30;
    DateTime expiry = item?.expiryDate ?? DateTime.now().add(const Duration(days: 365));

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null ? tr('تجديد جديد', 'New renewal') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: title,
                  autofocus: item == null,
                  decoration: InputDecoration(
                      labelText: tr('الاسم (رخصتى…)', 'Name (my license…)'))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: tr('النوع', 'Type')),
                items: [
                  for (final t in kRenewalTypes)
                    DropdownMenuItem(value: t, child: Text(renewalTypeLabel(t))),
                ],
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(tr('ينتهى: ${arShortDate(expiry)}',
                        'Expires: ${arShortDate(expiry)}'))),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('التاريخ', 'Date')),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: expiry,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => expiry = d);
                  },
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(tr('نبّهني قبلها بـ', 'Remind me before'))),
                DropdownButton<int>(
                  value: remindDays,
                  items: [
                    for (final d in const [7, 14, 30, 60, 90])
                      DropdownMenuItem(
                          value: d,
                          child: Text(tr('${arNum(d)} يوم', '${arNum(d)}d'))),
                  ],
                  onChanged: (v) => setD(() => remindDays = v ?? remindDays),
                ),
              ]),
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

    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(Renewal(
        id: item?.id,
        title: title.text.trim(),
        type: type,
        expiry: dayKey(expiry),
        remindDays: remindDays,
        notes: notes.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    notes.dispose();
  }
}
