import 'package:flutter/material.dart';

import '../core/dashboard_stats.dart';
import '../core/l10n.dart';
import '../widgets/dash_card.dart';

/// اللوحة الشاملة — نفس كروت الرئيسية بس فى صفحة لوحدها (عرض كامل).
class DashboardScreen extends StatefulWidget {
  final Widget? drawer;
  const DashboardScreen({super.key, this.drawer});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<DashStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await collectDashboard();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('لوحة شاملة', 'Dashboard')),
        actions: [
          IconButton(
            tooltip: tr('تحديث', 'Refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _stats.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            tr('ابدأ تسجّل حاجات وهتلاقى أرقامك هنا',
                                'Start logging and your numbers appear here'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.outline),
                          ),
                        ),
                      ),
                    ])
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: _stats.length,
                      itemBuilder: (_, i) =>
                          DashCardTile(stat: _stats[i], onOpen: _open),
                    ),
            ),
    );
  }
}
