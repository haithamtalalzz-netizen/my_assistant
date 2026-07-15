import 'package:flutter/material.dart';

import '../core/dashboard_stats.dart';
import '../core/l10n.dart';
import 'baladna/debts_screen.dart';
import 'docs/docs_screen.dart';
import 'food/food_card_screen.dart';
import 'growth/reading_screen.dart';
import 'habits/habits_screen.dart';
import 'health/health_hub_screen.dart';
import 'health/lab_results_screen.dart';
import 'home/plants_screen.dart';
import 'money/money_screen.dart';
import 'money/subscriptions_screen.dart';
import 'tasks/tasks_screen.dart';
import 'worship/prayer_screen.dart';

/// شكل الكارت (أيقونة/لون/وجهة) لكل مفتاح — الأرقام نفسها بتيجى من
/// `collectDashboard` فى الـcore.
({IconData icon, Color color, Widget Function() screen})? _look(String key) =>
    switch (key) {
      'money' => (
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.teal,
          screen: MoneyScreen.new
        ),
      'tasks' => (
          icon: Icons.checklist_outlined,
          color: Colors.orange,
          screen: TasksScreen.new
        ),
      'habits' => (
          icon: Icons.task_alt,
          color: Colors.lightGreen,
          screen: HabitsScreen.new
        ),
      'prayer' => (
          icon: Icons.mosque_outlined,
          color: Color(0xFF2FA36B),
          screen: PrayerScreen.new
        ),
      'food' => (
          icon: Icons.restaurant_outlined,
          color: Colors.deepOrange,
          screen: FoodCardScreen.new
        ),
      'health' => (
          icon: Icons.favorite_outline,
          color: Colors.pink,
          screen: HealthHubScreen.new
        ),
      'debts' => (
          icon: Icons.handshake_outlined,
          color: Color(0xFFFF6F00),
          screen: DebtsScreen.new
        ),
      'subs' => (
          icon: Icons.subscriptions_outlined,
          color: Colors.indigo,
          screen: SubscriptionsScreen.new
        ),
      'reading' => (
          icon: Icons.menu_book_outlined,
          color: Colors.brown,
          screen: ReadingScreen.new
        ),
      'home' => (
          icon: Icons.home_outlined,
          color: Colors.blueGrey,
          screen: PlantsScreen.new
        ),
      'docs' => (
          icon: Icons.folder_outlined,
          color: Colors.blue,
          screen: DocsScreen.new
        ),
      'labs' => (
          icon: Icons.biotech_outlined,
          color: Colors.deepPurple,
          screen: LabResultsScreen.new
        ),
      _ => null,
    };

/// اللوحة الشاملة — كارت لكل قسم برقمه الحى، ودوس عليه يفتح القسم.
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
                      itemBuilder: (_, i) => _card(_stats[i], scheme),
                    ),
            ),
    );
  }

  Widget _card(DashStat s, ColorScheme scheme) {
    final look = _look(s.key);
    final color = look?.color ?? scheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: look == null ? null : () => _open(look.screen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(look?.icon ?? Icons.dashboard_outlined,
                    size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(s.title,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // الرقم الكبير — بيتصغّر لو طويل بدل ما يتقص.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.value,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 28,
              width: double.infinity,
              child: Text(
                s.sub,
                maxLines: 2,
                style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
