import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/capsule_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/wheel_date_picker.dart';

class CapsuleScreen extends StatefulWidget {
  const CapsuleScreen({super.key});

  @override
  State<CapsuleScreen> createState() => _CapsuleScreenState();
}

class _CapsuleScreenState extends State<CapsuleScreen> {
  final _repo = CapsuleRepo();
  bool _loading = true;
  List<TimeCapsule> _items = [];

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

  Future<void> _add() async {
    final message = TextEditingController();
    var openDate = DateTime.now().add(const Duration(days: 365));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('كبسولة زمنية', 'Time capsule')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: message,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: tr('رسالة لنفسك في المستقبل',
                        'A message to your future self'),
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await pickWheelDate(
                    ctx,
                    initial: openDate,
                    first: now.add(const Duration(days: 1)),
                    last: now.add(const Duration(days: 365 * 20)),
                  );
                  if (picked != null) setD(() => openDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: tr('تتفتح يوم', 'Opens on')),
                  child: Text(arFullDate(openDate)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('اقفل الكبسولة', 'Seal capsule'))),
          ],
        ),
      ),
    );
    if (saved == true && message.text.trim().isNotEmpty) {
      await _repo.add(TimeCapsule(
        message: message.text.trim(),
        openDate: dayKey(openDate),
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    message.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('الكبسولة الزمنية', 'Time capsule')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.hourglass_empty,
                  text: tr('اكتب رسالة لنفسك تتفتح بعد سنة — وشوف إزاي اتغيّرت',
                      'Write a message to your future self — open it later'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    final ready = c.isReady(now);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: ready ? scheme.primaryContainer : null,
                      child: ListTile(
                        leading: Icon(
                            ready ? Icons.card_giftcard : Icons.lock_clock,
                            color: ready
                                ? scheme.onPrimaryContainer
                                : scheme.outline),
                        title: Text(ready
                            ? c.message
                            : tr('كبسولة مقفولة', 'Sealed capsule')),
                        subtitle: Text(ready
                            ? tr('اتفتحت (كتبتها ${arShortDate(DateTime.parse(c.createdAt.split('T').first))})',
                                'Opened')
                            : tr('تتفتح يوم ${arShortDate(DateTime.parse(c.openDate))}',
                                'Opens on ${arShortDate(DateTime.parse(c.openDate))}')),
                        onTap: ready && !c.opened
                            ? () async {
                                await _repo.markOpened(c.id!);
                                if (mounted) await _load();
                              }
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () async {
                            if (!await confirmDelete(
                                context, tr('الكبسولة دي', 'this capsule'))) {
                              return;
                            }
                            await _repo.delete(c.id!);
                            if (mounted) await _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'capsule_fab',
        onPressed: _add,
        tooltip: tr('كبسولة جديدة', 'New capsule'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
