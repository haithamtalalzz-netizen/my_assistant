import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ar.dart';
import '../core/app_state.dart';
import '../core/l10n.dart';
import '../data/settings_repo.dart';
import 'account_screen.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';
import 'money/subscriptions_screen.dart';
import 'growth/goals_screen.dart';
import 'food/fasting_screen.dart';
import 'food/meal_planner_screen.dart';
import 'growth/courses_screen.dart';
import 'growth/reading_screen.dart';
import 'growth/habit_analytics_screen.dart';
import 'passwords/passwords_screen.dart';
import '../data/bills_repo.dart';
import '../data/income_repo.dart';
import 'alerts_center_screen.dart';
import 'reports_hub_screen.dart';
import 'reports/year_review_screen.dart';
import 'reports/calculators_screen.dart';
import 'health/mood_screen.dart';
import 'money/wishlist_screen.dart';
import 'baladna/debts_screen.dart';
import 'baladna/gameya_screen.dart';
import 'baladna/relatives_screen.dart';
import 'baladna/savings_screen.dart';
import 'calendar_screen.dart';
import 'challenges_screen.dart';
import 'diary_screen.dart';
import 'time_machine_screen.dart';
import 'rules_screen.dart';
import 'food/diet_plans_screen.dart';
import 'food/food_card_screen.dart';
import 'recipes_screen.dart';
import 'brain/charts_screen.dart';
import 'emergency_view.dart';
import 'group_hub_screen.dart';
import 'gym/exercise_library_screen.dart';
import 'gym/gym_screen.dart';
import 'gym/progress_screen.dart';
import 'gym/walk_tracker_screen.dart';
import 'gym/workout_programs_screen.dart';
import 'health/cycle_screen.dart';
import 'health/health_hub_screen.dart';
import 'home/pharmacy_screen.dart';
import 'inbox_screen.dart';
import 'medical/medical_screen.dart';
import 'quit_screen.dart';
import 'settings_screen.dart';
import 'wardrobe/wardrobe_screen.dart';
import 'weekly/weekly_planning_screen.dart';
import 'worship/prayer_screen.dart';

/// الدرج الجانبي (زي طارة): بنود التطبيق الرئيسية بتبدّل الشاشة،
/// وباقي الأدوات بتتفتح كصفحات ليها سهم رجوع.
class AppDrawer extends StatelessWidget {
  final int current;
  final void Function(int index) onSelect;

  const AppDrawer({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // خط موحّد لكل بنود السايدبار (نفس الحجم والوزن).
    const navStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

    Widget top(int index, IconData icon, String label) => ListTile(
          selected: current == index,
          selectedTileColor: scheme.secondaryContainer,
          leading: Icon(icon),
          title: Text(label, style: navStyle),
          onTap: () {
            Navigator.pop(context);
            onSelect(index);
          },
        );

    Widget push(IconData icon, String label, Widget screen) => ListTile(
          leading: Icon(icon),
          title: Text(label, style: navStyle),
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

    // مجموعة → بتفتح صفحة فيها بنودها على شكل مربعات (زي هَبّات ملف المركبة).
    Widget groupTile(IconData icon, String title, List<GroupHubItem> items,
            {Widget? trailingBadge, Color? accent}) =>
        ListTile(
          leading: Icon(icon, color: accent),
          title: Row(
            children: [
              Flexible(child: Text(title, style: navStyle)),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                trailingBadge,
              ],
            ],
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GroupHubScreen(
                          title: title,
                          items: items,
                          onSelectTab: onSelect,
                          accent: accent,
                        )));
          },
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // حساب المستخدم — فوق (زي طارة): أفاتار + الاسم، يفتح صفحة الحساب.
            FutureBuilder<String>(
              future: SettingsRepo().userName(),
              builder: (context, snap) {
                final name = (snap.data ?? '').trim();
                return Container(
                  color: scheme.primaryContainer,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primary,
                      child: Text(
                          name.isNotEmpty ? name.characters.first : '★',
                          style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(name.isEmpty ? tr('حسابك', 'Your account') : name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: scheme.onPrimaryContainer)),
                    subtitle: Text(tr('إدارة حسابك', 'Manage your account'),
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onPrimaryContainer
                                .withValues(alpha: 0.75))),
                    trailing: Icon(Icons.chevron_left,
                        color: scheme.onPrimaryContainer),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountScreen()));
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // مثبّت فوق — أكتر ٣ حاجات بتتفتح.
            top(0, Icons.home_outlined, tr('الرئيسية', 'Home')),
            // ---- تذكيراتى (المواعيد + المهام) ----
            groupTile(Icons.notifications_active_outlined,
                tr('تذكيراتى', 'My reminders'),
                [
                  GroupHubItem(Icons.event_note_outlined,
                      tr('المواعيد', 'Appointments'), tabIndex: 1),
                  GroupHubItem(Icons.checklist_rtl, tr('المهام', 'Tasks'),
                      screen: const TasksScreen()),
                ]),
            const Divider(),
            // الصلاة والأذكار — فوق الفلوس مباشرة (المصحف جوّاها).
            push(Icons.mosque_outlined, tr('صلاتى', 'My prayers'),
                const PrayerScreen()),
            // ---- صحتى (يجمع الصحة + الرياضة + النظام الغذائي) ----
            groupTile(Icons.health_and_safety_outlined, tr('صحتى', 'My health'),
                accent: Colors.pink,
                [
                  GroupHubItem(Icons.favorite_outline, tr('الصحة', 'Health'),
                      color: Colors.pink,
                      screen: GroupHubScreen(
                        title: tr('الصحة', 'Health'),
                        onSelectTab: onSelect,
                        accent: Colors.pink,
                        items: [
                          GroupHubItem(Icons.dashboard_outlined,
                              tr('لوحة الصحة', 'Health hub'),
                              screen: const HealthHubScreen()),
                          if (AppState.gender.value == 'female')
                            GroupHubItem(Icons.favorite,
                                tr('الدورة الشهرية', 'Menstrual cycle'),
                                screen: const CycleScreen(),
                                color: Colors.pink),
                          GroupHubItem(Icons.task_alt, tr('العادات', 'Habits'),
                              tabIndex: 3),
                          GroupHubItem(
                              Icons.mood, tr('تتبّع المزاج', 'Mood tracker'),
                              screen: const MoodScreen()),
                          GroupHubItem(Icons.medication_outlined,
                              tr('الأدوية', 'Medications'),
                              screen: const MedsScreen()),
                          GroupHubItem(Icons.medical_information_outlined,
                              tr('الملف الطبي', 'Medical file'),
                              screen: const MedicalScreen()),
                          GroupHubItem(Icons.medication_outlined,
                              tr('صيدلية البيت', 'Home pharmacy'),
                              screen: const PharmacyScreen()),
                        ],
                      )),
                  GroupHubItem(Icons.fitness_center, tr('الرياضة', 'Exercise'),
                      color: Colors.deepPurple,
                      screen: GroupHubScreen(
                        title: tr('الرياضة', 'Exercise'),
                        onSelectTab: onSelect,
                        accent: Colors.deepPurple,
                        items: [
                          GroupHubItem(Icons.fitness_center, tr('الجيم', 'Gym'),
                              screen: const GymScreen()),
                          GroupHubItem(Icons.directions_run,
                              tr('تتبّع المشي/الجري', 'Walk / run'),
                              screen: const WalkTrackerScreen()),
                          GroupHubItem(Icons.monitor_weight_outlined,
                              tr('التقدم البدني', 'Body progress'),
                              screen: const ProgressScreen()),
                          GroupHubItem(Icons.menu_book_outlined,
                              tr('مكتبة التمارين', 'Exercise library'),
                              screen: const ExerciseLibraryScreen()),
                          GroupHubItem(Icons.list_alt_outlined,
                              tr('برامج التمارين', 'Workout programs'),
                              screen: const WorkoutProgramsScreen()),
                        ],
                      )),
                  GroupHubItem(
                      Icons.restaurant_outlined, tr('النظام الغذائي', 'Nutrition'),
                      color: Colors.green,
                      screen: GroupHubScreen(
                        title: tr('النظام الغذائي', 'Nutrition'),
                        onSelectTab: onSelect,
                        accent: Colors.green,
                        items: [
                          GroupHubItem(Icons.menu_book_outlined,
                              tr('دليل الأكل', 'Food guide'),
                              screen: const FoodCardScreen()),
                          GroupHubItem(Icons.restaurant_menu,
                              tr('الأنظمة الغذائية', 'Diet plans'),
                              screen: const DietPlansScreen()),
                          GroupHubItem(Icons.calendar_view_week_outlined,
                              tr('مخطّط الوجبات', 'Meal planner'),
                              screen: const MealPlannerScreen()),
                          GroupHubItem(Icons.timer_outlined,
                              tr('الصيام المتقطّع', 'Intermittent fasting'),
                              screen: const FastingScreen()),
                          GroupHubItem(Icons.restaurant_menu_outlined,
                              tr('دفتر الوصفات', 'Recipes'),
                              screen: const RecipesScreen()),
                        ],
                      )),
                ]),
            // ---- فلوسى ----
            groupTile(
                Icons.account_balance_wallet_outlined,
                tr('فلوسى', 'My money'),
                accent: Colors.teal,
                [
                  GroupHubItem(Icons.account_balance_wallet_outlined,
                      tr('المحفظة', 'Wallet'), tabIndex: 2),
                  GroupHubItem(Icons.savings_outlined, tr('الادخار', 'Savings'),
                      screen: const SavingsScreen()),
                  GroupHubItem(Icons.handshake_outlined,
                      tr('الديون والسلف', 'Debts'),
                      screen: const DebtsScreen()),
                  GroupHubItem(Icons.groups_outlined, tr('الجمعيات', "Gam'iyas"),
                      screen: const GameyaScreen()),
                  GroupHubItem(Icons.subscriptions_outlined,
                      tr('الاشتراكات', 'Subscriptions'),
                      screen: const SubscriptionsScreen()),
                  GroupHubItem(Icons.favorite_border,
                      tr('قائمة الأمنيات', 'Wishlist'),
                      screen: const WishlistScreen()),
                ],
                trailingBadge: FutureBuilder<int>(
                  future: _moneyDueCount(),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return n == 0 ? const SizedBox.shrink() : badge(n);
                  },
                )),
            // ---- ملابس (بند مستقل) ----
            push(Icons.checkroom_outlined, tr('ملابسى', 'My clothes'),
                const WardrobeScreen()),
            groupTile(Icons.self_improvement, tr('تطوّري', 'Growth'),
                accent: Colors.indigo,
                [
                  GroupHubItem(Icons.flag_outlined, tr('الأهداف', 'Goals'),
                      screen: const GoalsScreen()),
                  GroupHubItem(Icons.school_outlined, tr('التعلّم', 'Learning'),
                      screen: const CoursesScreen()),
                  GroupHubItem(Icons.menu_book_outlined, tr('القراءة', 'Reading'),
                      screen: const ReadingScreen()),
                  GroupHubItem(Icons.insights_outlined,
                      tr('تحليلات العادات', 'Habit analytics'),
                      screen: const HabitAnalyticsScreen()),
                  GroupHubItem(Icons.flag_outlined, tr('التحديات', 'Challenges'),
                      screen: const ChallengesScreen()),
                  GroupHubItem(Icons.auto_stories_outlined,
                      tr('اليوميات', 'Diary'),
                      screen: const DiaryScreen()),
                  GroupHubItem(Icons.emoji_events_outlined,
                      tr('عدّاد الإقلاع', 'Quit counter'),
                      screen: const QuitScreen()),
                  GroupHubItem(Icons.diversity_1_outlined,
                      tr('صلة الرحم', 'Keep in touch'),
                      screen: const RelativesScreen()),
                  GroupHubItem(Icons.key_outlined,
                      tr('كلمات السر', 'Passwords'),
                      screen: const PasswordsScreen()),
                ]),
            groupTile(Icons.insights_outlined,
                tr('المتابعة والأدوات', 'Review & tools'),
                accent: Colors.blue,
                [
                  GroupHubItem(Icons.lightbulb_outline,
                      tr('رؤى المدير', 'Insights'), tabIndex: 5),
                  GroupHubItem(Icons.emoji_events_outlined,
                      tr('المراجعة السنوية', 'Year in review'),
                      screen: const YearReviewScreen()),
                  GroupHubItem(Icons.pie_chart_outline, tr('التقارير', 'Reports'),
                      screen: const ReportsHubScreen()),
                  GroupHubItem(Icons.bar_chart, tr('إحصائياتك', 'Charts'),
                      screen: const ChartsScreen()),
                  GroupHubItem(Icons.calculate_outlined, tr('حاسبات', 'Calculators'),
                      screen: const CalculatorsScreen()),
                  GroupHubItem(Icons.calendar_month_outlined,
                      tr('تقويم النتيجة', 'Activity calendar'),
                      screen: const CalendarScreen()),
                  GroupHubItem(Icons.history_toggle_off,
                      tr('آلة الزمن', 'Time machine'),
                      screen: const TimeMachineScreen()),
                  GroupHubItem(Icons.rule, tr('قواعدى', 'My rules'),
                      screen: const RulesScreen()),
                  GroupHubItem(Icons.inbox_outlined,
                      tr('صندوق الوارد', 'Inbox'),
                      screen: const InboxScreen()),
                  GroupHubItem(Icons.event_repeat,
                      tr('التخطيط الأسبوعي', 'Weekly planning'),
                      screen: const WeeklyPlanningScreen()),
                  GroupHubItem(Icons.folder_outlined,
                      tr('المستندات', 'Documents'), tabIndex: 4),
                  GroupHubItem(Icons.notifications_none, tr('مركز التنبيهات', 'Alerts'),
                      screen: const AlertsCenterScreen()),
                ]),
            const Divider(),
            // دايمًا ظاهرة في الآخر.
            push(Icons.medical_services_outlined,
                tr('كارت الطوارئ', 'Emergency card'),
                const EmergencyView()),
            // صف سفلي: الإعدادات + اللغة + المظهر جنب بعض (زي طارة).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _footerBtn(context, Icons.settings_outlined,
                      tr('الإعدادات', 'Settings'), () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()));
                  }),
                  _footerBtn(
                      context,
                      Icons.translate,
                      AppState.isEnglish ? 'العربية' : 'English',
                      () => AppState.setLanguage(
                          AppState.isEnglish ? 'ar' : 'en')),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppState.themeMode,
                    builder: (context, mode, _) {
                      final isDark = mode == ThemeMode.dark ||
                          (mode == ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) ==
                                  Brightness.dark);
                      return _footerBtn(
                          context,
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          isDark ? tr('فاتح', 'Light') : tr('غامق', 'Dark'),
                          () => AppState.setThemeMode(
                              isDark ? ThemeMode.light : ThemeMode.dark));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(tr('تسجيل الخروج', 'Log out'),
                  style: navStyle.copyWith(color: scheme.error)),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('تسجيل الخروج', 'Log out')),
                    content: Text(tr('هيتقفل التطبيق. تحب تكمل؟',
                        'The app will close. Continue?')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(tr('إلغاء', 'Cancel'))),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(tr('خروج', 'Log out'))),
                    ],
                  ),
                );
                if (ok == true) await SystemNavigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// زر أداة سفلي (أيقونة + عنوان صغير تحتها).
  Widget _footerBtn(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
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
