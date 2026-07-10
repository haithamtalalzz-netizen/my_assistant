import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/bills_repo.dart';
import '../data/income_repo.dart';
import 'alerts_center_screen.dart';
import 'reports_hub_screen.dart';
import 'baladna/debts_screen.dart';
import 'baladna/gameya_screen.dart';
import 'baladna/home_maintenance_screen.dart';
import 'baladna/relatives_screen.dart';
import 'baladna/savings_screen.dart';
import 'baladna/social_screen.dart';
import 'money/assets_screen.dart';
import 'calendar_screen.dart';
import 'capsule_screen.dart';
import 'challenges_screen.dart';
import 'diary_screen.dart';
import 'recipes_screen.dart';
import 'brain/charts_screen.dart';
import 'emergency_view.dart';
import 'food/shopping_list_screen.dart';
import 'gym/gym_screen.dart';
import 'gym/progress_screen.dart';
import 'health/health_hub_screen.dart';
import 'home/meters_screen.dart';
import 'home/pharmacy_screen.dart';
import 'home/plants_screen.dart';
import 'home/warranty_screen.dart';
import 'inbox_screen.dart';
import 'medical/medical_screen.dart';
import 'quit_screen.dart';
import 'quran_screen.dart';
import 'secret_notes_screen.dart';
import 'settings_screen.dart';
import 'wardrobe/wardrobe_screen.dart';
import 'weekly/weekly_planning_screen.dart';

/// الدرج الجانبي (زي طارة): بنود التطبيق الرئيسية بتبدّل الشاشة،
/// وباقي الأدوات بتتفتح كصفحات ليها سهم رجوع.
class AppDrawer extends StatelessWidget {
  final int current;
  final void Function(int index) onSelect;

  const AppDrawer({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget top(int index, IconData icon, String label) => ListTile(
          selected: current == index,
          selectedTileColor: scheme.secondaryContainer,
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.pop(context);
            onSelect(index);
          },
        );

    Widget push(IconData icon, String label, Widget screen) => ListTile(
          dense: true,
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen));
          },
        );

    // شارة عدد صغيرة (مثلًا «٢ مستحق» جنب مجموعة).
    Widget badge(int n) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: scheme.error,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(arNum(n),
              style: TextStyle(
                  color: scheme.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        );

    // مجموعة قابلة للطي — بتقلّل زحمة السايدبار.
    Widget groupTile(IconData icon, String title, List<Widget> children,
            {Widget? trailingBadge}) =>
        ExpansionTile(
          leading: Icon(icon),
          title: Row(
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                trailingBadge,
              ],
            ],
          ),
          childrenPadding: const EdgeInsetsDirectional.only(start: 12),
          shape: const Border(),
          collapsedShape: const Border(),
          children: children,
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 36, color: scheme.onPrimaryContainer),
                  const SizedBox(height: 8),
                  Text(tr('مساعدي', 'My Assistant'),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
            // البنود الرئيسية — دايمًا ظاهرة.
            top(0, Icons.wb_sunny_outlined, tr('اليوم', 'Today')),
            top(1, Icons.event_note_outlined, tr('الجدول', 'Schedule')),
            top(2, Icons.account_balance_wallet_outlined,
                tr('المحفظة', 'Wallet')),
            top(3, Icons.task_alt, tr('العادات', 'Habits')),
            top(4, Icons.folder_outlined, tr('المستندات', 'Documents')),
            top(5, Icons.lightbulb_outline, tr('رؤى المدير', 'Insights')),
            const Divider(),
            // مجموعات قابلة للطي — ٥ مجموعات متوازنة وواضحة.
            groupTile(Icons.insights_outlined,
                tr('المراجعة والمتابعة', 'Review & tracking'), [
              push(Icons.notifications_none, tr('مركز التنبيهات', 'Alerts'),
                  const AlertsCenterScreen()),
              push(Icons.pie_chart_outline, tr('التقارير', 'Reports'),
                  const ReportsHubScreen()),
              push(Icons.calendar_month_outlined,
                  tr('تقويم النتيجة', 'Activity calendar'),
                  const CalendarScreen()),
              push(Icons.inbox_outlined, tr('صندوق الوارد', 'Inbox'),
                  const InboxScreen()),
              push(Icons.bar_chart, tr('إحصائياتك', 'Charts'),
                  const ChartsScreen()),
              push(Icons.event_repeat,
                  tr('التخطيط الأسبوعي', 'Weekly planning'),
                  const WeeklyPlanningScreen()),
            ]),
            groupTile(Icons.favorite_outline,
                tr('الصحة واللياقة', 'Health & fitness'), [
              push(Icons.dashboard_outlined,
                  tr('لوحة الصحة', 'Health hub'),
                  const HealthHubScreen()),
              push(Icons.fitness_center, tr('الجيم', 'Gym'),
                  const GymScreen()),
              push(Icons.monitor_weight_outlined,
                  tr('التقدم البدني', 'Body progress'),
                  const ProgressScreen()),
              push(Icons.medical_information_outlined,
                  tr('الملف الطبي', 'Medical file'),
                  const MedicalScreen()),
              push(Icons.medication_outlined,
                  tr('صيدلية البيت', 'Home pharmacy'),
                  const PharmacyScreen()),
            ]),
            groupTile(
                Icons.account_balance_wallet_outlined,
                tr('الفلوس والالتزامات', 'Money & dues'),
                [
                  push(Icons.savings_outlined, tr('الادخار', 'Savings'),
                      const SavingsScreen()),
                  push(Icons.diamond_outlined,
                      tr('أموالي الخارجية', 'My assets'),
                      const AssetsScreen()),
                  push(Icons.handshake_outlined, tr('الديون والسلف', 'Debts'),
                      const DebtsScreen()),
                  push(Icons.groups_outlined, tr('الجمعيات', "Gam'iyas"),
                      const GameyaScreen()),
                  push(Icons.volunteer_activism_outlined,
                      tr('الواجبات الاجتماعية', 'Social ledger'),
                      const SocialScreen()),
                  push(Icons.diversity_1_outlined,
                      tr('صلة الرحم', 'Keep in touch'),
                      const RelativesScreen()),
                ],
                trailingBadge: FutureBuilder<int>(
                  future: _moneyDueCount(),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return n == 0 ? const SizedBox.shrink() : badge(n);
                  },
                )),
            groupTile(Icons.home_outlined,
                tr('البيت والمشتريات', 'Home & shopping'), [
              push(Icons.home_repair_service_outlined,
                  tr('صيانة البيت', 'Home maintenance'),
                  const HomeMaintenanceScreen()),
              push(Icons.verified_outlined,
                  tr('أرشيف الضمانات', 'Warranties'),
                  const WarrantyScreen()),
              push(Icons.speed_outlined,
                  tr('قراءات العدادات', 'Meter readings'),
                  const MetersScreen()),
              push(Icons.yard_outlined,
                  tr('نباتات البيت', 'Home plants'),
                  const PlantsScreen()),
              push(Icons.checkroom_outlined,
                  tr('خزانة الملابس', 'Wardrobe'),
                  const WardrobeScreen()),
              push(Icons.shopping_cart_outlined,
                  tr('قائمة التسوق', 'Shopping list'),
                  const ShoppingListScreen()),
              push(Icons.restaurant_menu_outlined,
                  tr('دفتر الوصفات', 'Recipes'),
                  const RecipesScreen()),
            ]),
            groupTile(Icons.self_improvement,
                tr('تطوير الذات', 'Personal growth'), [
              push(Icons.menu_book_outlined,
                  tr('مراجعة القرآن', 'Quran review'),
                  const QuranScreen()),
              push(Icons.flag_outlined, tr('التحديات', 'Challenges'),
                  const ChallengesScreen()),
              push(Icons.hourglass_empty,
                  tr('الكبسولة الزمنية', 'Time capsule'),
                  const CapsuleScreen()),
              push(Icons.auto_stories_outlined, tr('اليوميات', 'Diary'),
                  const DiaryScreen()),
              push(Icons.emoji_events_outlined,
                  tr('عدّاد الإقلاع', 'Quit counter'),
                  const QuitScreen()),
              push(Icons.lock_outline,
                  tr('الخزنة السرية', 'Secret vault'),
                  const SecretNotesScreen()),
            ]),
            const Divider(),
            // دايمًا ظاهرة في الآخر.
            push(Icons.medical_services_outlined,
                tr('كارت الطوارئ', 'Emergency card'),
                const EmergencyView()),
            push(Icons.settings_outlined, tr('الإعدادات', 'Settings'),
                const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  /// عدد المستحقات المالية النهارده (فواتير + مرتب) — لشارة السايدبار.
  Future<int> _moneyDueCount() async {
    final now = DateTime.now();
    final bills = (await BillsRepo().due(now)).length;
    final income = (await IncomeRepo().dueRecurring(now)).length;
    return bills + income;
  }
}
