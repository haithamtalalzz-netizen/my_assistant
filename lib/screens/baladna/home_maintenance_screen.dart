import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/home_maintenance_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class HomeMaintenanceScreen extends StatefulWidget {
  const HomeMaintenanceScreen({super.key});

  @override
  State<HomeMaintenanceScreen> createState() => _HomeMaintenanceScreenState();
}

class _HomeMaintenanceScreenState extends State<HomeMaintenanceScreen> {
  final _repo = HomeMaintenanceRepo();
  bool _loading = true;
  List<HomeMaintenance> _items = [];

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

  String _dueLabel(HomeMaintenance m) {
    final days = m.daysUntilDue(DateTime.now());
    if (days < 0) {
      return tr('فات ميعادها من ${arNum(-days)} يوم',
          'overdue by ${arNum(-days)} days');
    }
    if (days == 0) return tr('ميعادها النهارده', 'due today');
    if (days <= 30) return tr('باقي ${arNum(days)} يوم', '${arNum(days)} days left');
    final months = (days / 30).round();
    return tr('باقي حوالي ${arNum(months)} شهور', '~${arNum(months)} months left');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('صيانة البيت', 'Home maintenance')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.home_repair_service_outlined,
                          text:
                              tr('سجل صيانات بيتك الدورية — فلتر المياه، التكييف، السخان\nوهفكرك كل واحدة في ميعادها',
                                  'Log home upkeep — water filter, AC, heater\nreminded when each is due')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      children: [
                        for (final m in _items)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: m.isDue(DateTime.now())
                                ? scheme.tertiaryContainer
                                : null,
                            child: ListTile(
                              leading: Icon(Icons.build_outlined,
                                  color: m.isDue(DateTime.now())
                                      ? scheme.onTertiaryContainer
                                      : scheme.primary),
                              title: Text(m.name),
                              subtitle: Text(
                                  '${_dueLabel(m)} • ${tr('كل ${arNum(m.intervalMonths)} شهور', 'every ${arNum(m.intervalMonths)} months')}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () async {
                                      await _repo.markDone(m.id!);
                                      if (mounted) await _load();
                                    },
                                    child: Text(tr('اتعملت', 'Done')),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'delete') {
                                        await _repo.delete(m.id!);
                                        if (mounted) await _load();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text(tr('حذف', 'Delete'))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'maint_fab',
        onPressed: _addForm,
        icon: const Icon(Icons.add),
        label: Text(tr('صيانة جديدة', 'New maintenance')),
      ),
    );
  }

  Future<void> _addForm() async {
    final name = TextEditingController();
    var interval = 6;
    var lastDoneRecently = true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('صيانة دورية', 'Recurring maintenance')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                      labelText: tr('الصيانة', 'Maintenance')),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final (label, months) in kMaintenanceSuggestions)
                      ActionChip(
                        label: Text(label),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          name.text = label;
                          setDialogState(() => interval = months);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: Text(tr('تتكرر كل كام شهر', 'Repeat every'))),
                    DropdownButton<int>(
                      value: interval,
                      items: [
                        for (final m in const [1, 2, 3, 6, 12, 24])
                          DropdownMenuItem(
                              value: m,
                              child: Text(
                                  tr('${arNum(m)} شهور', '${arNum(m)} months'))),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => interval = v ?? interval),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('اتعملت لسه دلوقتي', 'Just done now')),
                  subtitle: Text(tr('لو مقفولة، الصيانة تعتبر مستحقة من دلوقتي',
                      'If off, it counts as due from now')),
                  value: lastDoneRecently,
                  onChanged: (v) =>
                      setDialogState(() => lastDoneRecently = v),
                ),
              ],
            ),
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
      final now = DateTime.now();
      // لو لسه ماتعملتش، نحط آخر صيانة قبل فترة كاملة عشان تبان مستحقة.
      final lastDone = lastDoneRecently
          ? dayKey(now)
          : dayKey(DateTime(now.year, now.month - interval, now.day));
      await _repo.save(HomeMaintenance(
        name: name.text.trim(),
        intervalMonths: interval,
        lastDone: lastDone,
      ));
      if (mounted) await _load();
    }
    name.dispose();
  }
}
