import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/plants_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';

/// متابعة نباتات البيت — كل نبتة ليها ميعاد ري، والتطبيق بيفكّرك النهار المناسب.
class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final _repo = PlantsRepo();
  bool _loading = true;
  List<Plant> _items = [];

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

  Future<void> _form([Plant? p]) async {
    final name = TextEditingController(text: p?.name ?? '');
    final location = TextEditingController(text: p?.location ?? '');
    final note = TextEditingController(text: p?.note ?? '');
    var interval = p?.waterIntervalDays ?? 3;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(p == null
              ? tr('نبتة جديدة', 'New plant')
              : tr('تعديل', 'Edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: p == null,
                  decoration: InputDecoration(
                      labelText: tr('اسم النبتة (بوتس، صبار...)',
                          'Plant name (pothos, cactus...)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: InputDecoration(
                      labelText: tr('المكان (بلكونة، صالة...)',
                          'Location (balcony, hall...)')),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(tr('أسقيها كل', 'Water every'))),
                    DropdownButton<int>(
                      value: interval,
                      items: [
                        for (final d in [1, 2, 3, 4, 5, 7, 10, 14])
                          DropdownMenuItem(
                              value: d,
                              child: Text(
                                  tr('${arNum(d)} يوم', '${arNum(d)} days'))),
                      ],
                      onChanged: (v) => setD(() => interval = v ?? interval),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                      labelText: tr('ملاحظة (اختياري)', 'Note (optional)')),
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
      await _repo.save(Plant(
        id: p?.id,
        name: name.text.trim(),
        location: location.text.trim(),
        waterIntervalDays: interval,
        lastWatered: p?.lastWatered,
        note: note.text.trim(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    location.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dueCount = _items.where((p) => p.isDue(now)).length;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('نباتات البيت', 'Home plants')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.yard_outlined,
                  text: tr(
                      'ضيف نباتاتك — والتطبيق يفكّرك تسقيها في وقتها',
                      'Add your plants — get reminded to water them on time'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    children: [
                      if (dueCount > 0)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: scheme.tertiary.withValues(alpha: .13),
                          child: ListTile(
                            leading: const Text('🪴',
                                style: TextStyle(fontSize: 24)),
                            title: Text(
                              tr('${arNum(dueCount)} نبتة محتاجة مياه النهارده',
                                  '${arNum(dueCount)} plant(s) need water today'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      for (final p in _items) _plantTile(p, now, scheme),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'plants_fab',
        onPressed: () => _form(),
        tooltip: tr('نبتة جديدة', 'New plant'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _plantTile(Plant p, DateTime now, ColorScheme scheme) {
    final due = p.isDue(now);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: due ? scheme.tertiary.withValues(alpha: .13) : null,
      child: ListTile(
        leading: const Text('🪴', style: TextStyle(fontSize: 26)),
        title: Text(p.name,
            style: due
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null),
        subtitle: Text(_subtitle(p, now)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.water_drop,
                  color: due ? Colors.blue : scheme.outline),
              tooltip: tr('سقيت', 'Watered'),
              onPressed: () async {
                await _repo.markWatered(p);
                if (mounted) await _load();
              },
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await _form(p);
                } else if (v == 'delete') {
                  if (!await confirmDelete(
                      context, tr('«${p.name}»', '"${p.name}"'))) {
                    return;
                  }
                  await _repo.delete(p.id!);
                  if (mounted) await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(
                    value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Plant p, DateTime now) {
    final loc = p.location.isEmpty ? '' : '${p.location} • ';
    if (p.lastWatered == null) {
      return '$loc${tr('لسه ما اتسقتش', 'Not watered yet')}';
    }
    if (p.isDue(now)) return '$loc${tr('محتاجة مياه دلوقتي', 'Needs water now')}';
    return '$loc${tr('الري الجاي: ${arShortDate(p.nextWater())}', 'Next water: ${arShortDate(p.nextWater())}')}';
  }
}
