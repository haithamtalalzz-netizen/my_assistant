import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/relatives_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class RelativesScreen extends StatefulWidget {
  const RelativesScreen({super.key});

  @override
  State<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends State<RelativesScreen> {
  final _repo = RelativesRepo();
  bool _loading = true;
  List<Relative> _items = [];

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

  Future<void> _form([Relative? r]) async {
    final name = TextEditingController(text: r?.name ?? '');
    final phone = TextEditingController(text: r?.phone ?? '');
    var interval = r?.intervalDays ?? 14;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(r == null ? tr('قريب جديد', 'New relative') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: r == null,
                decoration: InputDecoration(labelText: tr('الاسم', 'Name')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: tr('التليفون (اختياري)', 'Phone (optional)')),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(tr('أتصل كل', 'Call every'))),
                  DropdownButton<int>(
                    value: interval,
                    items: [
                      for (final d in [7, 14, 30, 60])
                        DropdownMenuItem(
                            value: d,
                            child: Text(tr('${arNum(d)} يوم', '${arNum(d)} days'))),
                    ],
                    onChanged: (v) => setD(() => interval = v ?? interval),
                  ),
                ],
              ),
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
      await _repo.save(Relative(
        id: r?.id,
        name: name.text.trim(),
        phone: phone.text.trim(),
        intervalDays: interval,
        lastContacted: r?.lastContacted,
      ));
      if (mounted) await _load();
    }
    name.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(tr('صلة الرحم', 'Keep in touch'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.diversity_1_outlined,
                  text: tr('ضيف أهلك وقرايبك — والتطبيق يفكّرك تطمن عليهم كل فترة',
                      'Add family & relatives — get reminded to check on them regularly'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      final due = r.isDue(now);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: due ? scheme.tertiaryContainer : null,
                        child: ListTile(
                          leading: Icon(Icons.person,
                              color: due
                                  ? scheme.onTertiaryContainer
                                  : scheme.primary),
                          title: Text(r.name,
                              style: due
                                  ? TextStyle(
                                      color: scheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600)
                                  : null),
                          subtitle: Text(
                              r.lastContacted == null
                                  ? tr('لسه ما اتصلتش', 'Never contacted')
                                  : due
                                      ? tr('محتاج تطمن عليه', 'Time to check in')
                                      : tr('المكالمة الجاية: ${arShortDate(r.nextDue())}',
                                          'Next call: ${arShortDate(r.nextDue())}'),
                              style: due
                                  ? TextStyle(color: scheme.onTertiaryContainer)
                                  : null),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.phone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  tooltip: tr('اتصل', 'Call'),
                                  onPressed: () => launchUrl(
                                      Uri.parse('tel:${r.phone}'),
                                      mode: LaunchMode.externalApplication),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'contacted') {
                                    await _repo.markContacted(r);
                                    if (mounted) await _load();
                                  } else if (v == 'edit') {
                                    await _form(r);
                                  } else if (v == 'delete') {
                                    if (!await confirmDelete(context,
                                        tr('«${r.name}»', '"${r.name}"'))) {
                                      return;
                                    }
                                    await _repo.delete(r.id!);
                                    if (mounted) await _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'contacted',
                                      child: Text(tr('اتصلت به ✓', 'Contacted ✓'))),
                                  PopupMenuItem(
                                      value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'delete', child: Text(tr('حذف', 'Delete'))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'relatives_fab',
        onPressed: () => _form(),
        tooltip: tr('قريب جديد', 'New relative'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
