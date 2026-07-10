import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/docs_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/plants_repo.dart';
import '../data/relatives_repo.dart';
import '../widgets/common.dart';
import 'baladna/home_maintenance_screen.dart';
import 'baladna/relatives_screen.dart';
import 'docs/docs_screen.dart';
import 'home/plants_screen.dart';

/// مركز التنبيهات — بيجمع كل اللي محتاج انتباه النهارده في مكان واحد.
class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertItem {
  final IconData icon;
  final Color color;
  final String text;
  final Widget? screen;
  _AlertItem(this.icon, this.color, this.text, {this.screen});
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  bool _loading = true;
  final List<_AlertItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final bills = await BillsRepo().due(now);
    final appts = await AppointmentsRepo().forDay(now);
    final plants = await PlantsRepo().due(now);
    final maint = await HomeMaintenanceRepo().due(now);
    final relatives = await RelativesRepo().due(now);
    final docs = await DocsRepo().expiringSoon();

    final list = <_AlertItem>[];
    for (final b in bills) {
      list.add(_AlertItem(Icons.receipt_long_outlined, Colors.redAccent,
          tr('فاتورة مستحقة: ${b.name}', 'Bill due: ${b.name}')));
    }
    for (final a in appts) {
      list.add(_AlertItem(Icons.event_outlined, Colors.blue,
          tr('موعد النهارده: ${a.title} — ${arTime(a.when)}',
              'Today: ${a.title} — ${arTime(a.when)}')));
    }
    for (final p in plants) {
      list.add(_AlertItem(Icons.yard_outlined, Colors.green,
          tr('${p.name} محتاجة مياه', '${p.name} needs water'),
          screen: const PlantsScreen()));
    }
    for (final m in maint) {
      list.add(_AlertItem(Icons.home_repair_service_outlined, Colors.orange,
          tr('صيانة مستحقة: ${m.name}', 'Maintenance due: ${m.name}'),
          screen: const HomeMaintenanceScreen()));
    }
    for (final r in relatives) {
      list.add(_AlertItem(Icons.diversity_1_outlined, Colors.purple,
          tr('اطمن على ${r.name}', 'Check on ${r.name}'),
          screen: const RelativesScreen()));
    }
    for (final d in docs) {
      list.add(_AlertItem(Icons.folder_outlined, Colors.teal,
          tr('مستند قرب يخلص: ${d.title}', 'Document expiring: ${d.title}'),
          screen: const DocsScreen()));
    }

    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('التنبيهات', 'Alerts'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.notifications_none,
                  text: tr('مفيش تنبيهات النهارده — كله تمام 🎉',
                      'No alerts today — all clear 🎉'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      for (final it in _items)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: it.color.withValues(alpha: 0.15),
                              child: Icon(it.icon, color: it.color, size: 20),
                            ),
                            title: Text(it.text),
                            trailing: it.screen == null
                                ? null
                                : const Icon(Icons.chevron_left, size: 20),
                            onTap: it.screen == null
                                ? null
                                : () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => it.screen!));
                                    if (mounted) await _load();
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
