import 'package:flutter/material.dart';

import '../core/dashboard_stats.dart';
import '../screens/baladna/debts_screen.dart';
import '../screens/docs/docs_screen.dart';
import '../screens/food/food_card_screen.dart';
import '../screens/growth/reading_screen.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/health/health_hub_screen.dart';
import '../screens/health/lab_results_screen.dart';
import '../screens/home/plants_screen.dart';
import '../screens/money/money_screen.dart';
import '../screens/money/subscriptions_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/worship/prayer_screen.dart';

/// شكل الكارت (أيقونة/لون/وجهة) لكل مفتاح — الأرقام نفسها بتيجى من
/// `collectDashboard` فى الـcore. مشترك بين الرئيسية واللوحة الشاملة.
({IconData icon, Color color, Widget Function() screen})? dashLook(String key) =>
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

/// كارت قسم برقمه الحى — النصوص كلها فى `FittedBox` يعنى **مفيش قص بأى لغة**.
class DashCardTile extends StatelessWidget {
  final DashStat stat;

  /// بيتنادى بالشاشة اللى المفروض تتفتح (المستدعى بيعمل push ويحدّث بعدها).
  final void Function(Widget screen)? onOpen;

  const DashCardTile({super.key, required this.stat, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final look = dashLook(stat.key);
    final color = look?.color ?? scheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: (look == null || onOpen == null)
          ? null
          : () => onOpen!(look.screen()),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                    size: 17, color: color),
                const SizedBox(width: 5),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(stat.title,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(stat.value,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 26,
              width: double.infinity,
              child: Text(stat.sub,
                  maxLines: 2,
                  style:
                      TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
