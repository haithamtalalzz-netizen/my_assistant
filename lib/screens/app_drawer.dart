import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ar.dart';
import '../core/app_state.dart';
import '../core/l10n.dart';
import '../data/settings_repo.dart';
import 'account_screen.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';
import 'notes_screen.dart';
import 'money/subscriptions_screen.dart';
import 'growth/goals_screen.dart';
import 'food/fasting_screen.dart';
import 'food/meal_planner_screen.dart';
import 'growth/courses_screen.dart';
import 'growth/reading_screen.dart';
import 'growth/habit_analytics_screen.dart';
import 'passwords/passwords_screen.dart';
import '../data/bills_repo.dart';
import '../data/docs_repo.dart';
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

// ألوان أيقونات بنود السايدبار — كل بند له لون ثابت (زى التصميم).
const _cHome = Color(0xFF2FA36B);
const _cCalendar = Color(0xFF3B9BE8);
const _cTasks = Color(0xFF4F7FE8);
const _cNotes = Color(0xFF8B5CF6);
const _cGoals = Color(0xFFE8A33B);
const _cPrayer = Color(0xFF2FA36B);
const _cClothes = Color(0xFF9B6BE8);
const _cEmergency = Color(0xFFE85C5C);

/// صفّ بند فى السايدبار: أيقونة مربّعة ملوّنة + العنوان + مؤشّر جانبى للمختار.
Widget _navRow({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
  bool selected = false,
  Widget? trailing,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Material(
    color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          // المؤشّر على حافة البداية (يمين فى العربى).
          if (selected)
            PositionedDirectional(
              start: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                // الشارة جنب الاسم مباشرةً (زى التصميم) مش فى آخر الصف.
                // ملاحظة: مافيش Spacer هنا — كان بيزاحم النص على المساحة
                // فيتقصّ («المتابعة والأدوات»)؛ الصف بيبدأ من الحافة أصلاً.
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// الدرج الجانبي (زي طارة): بنود التطبيق الرئيسية بتبدّل الشاشة،
/// وباقي الأدوات بتتفتح كصفحات ليها سهم رجوع.
class AppDrawer extends StatelessWidget {
  final int current;
  final void Function(int index) onSelect;

  const AppDrawer({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget top(int index, IconData icon, String label, Color color) => _navRow(
          context: context,
          icon: icon,
          label: label,
          color: color,
          selected: current == index,
          onTap: () {
            Navigator.pop(context);
            onSelect(index);
          },
        );

    Widget push(IconData icon, String label, Widget screen, Color color) =>
        _navRow(
          context: context,
          icon: icon,
          label: label,
          color: color,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen));
          },
        );

    // شارة عدد صغيرة (مثلًا «٢ مستحق» جنب مجموعة).
    Widget badge(int n) => Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.error,
            shape: BoxShape.circle,
          ),
          child: Text(arNum(n),
              style: TextStyle(
                  color: scheme.onError,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        );

    // مجموعة → بتفتح صفحة فيها بنودها على شكل مربعات (زي هَبّات ملف المركبة).
    Widget groupTile(IconData icon, String title, List<GroupHubItem> items,
            {Widget? trailingBadge, Color? accent}) =>
        _navRow(
          context: context,
          icon: icon,
          label: title,
          color: accent ?? scheme.primary,
          trailing: trailingBadge,
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

    // فاصل رفيع بين البنود (يبدأ بعد الأيقونة زى التصميم).
    final rowDivider = Divider(
      height: 1,
      thickness: 0.7,
      indent: 66,
      endIndent: 14,
      color: scheme.outlineVariant.withValues(alpha: 0.35),
    );
    // فاصل أقسام (أعرض شوية).
    final sectionDivider = Divider(
      height: 17,
      thickness: 0.7,
      indent: 30,
      endIndent: 30,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
    );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          children: [
            // ---- كارت الحساب ----
            FutureBuilder<String>(
              future: SettingsRepo().userName(),
              builder: (context, snap) {
                final name = (snap.data ?? '').trim();
                return Material(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountScreen()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary,
                                  scheme.primary.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            child: name.isNotEmpty
                                ? Text(name.characters.first,
                                    style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800))
                                : Icon(Icons.star,
                                    color: scheme.onPrimary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    name.isEmpty
                                        ? tr('حسابك', 'Your account')
                                        : name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19)),
                                const SizedBox(height: 2),
                                Text(tr('إدارة حسابك', 'Manage your account'),
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          // فى العربى بيتقلب لـ«‹» ناحية الحافة (زى التصميم).
                          Icon(Icons.chevron_left,
                              color: scheme.primary, size: 26),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // ---- لوحة البنود ----
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
            // مثبّت فوق — أكتر ٣ حاجات بتتفتح.
            top(0, Icons.home_outlined, tr('الرئيسية', 'Home'), _cHome),
            rowDivider,
            // ---- بنود مستقلة ورا بعض ----
            // مواعيدى = شاشة الجدول (تذكيرات + مواعيد) · مهامى = المهام ·
            // تذكيراتى = ملاحظات حرّة · الأهداف = بند مستقل.
            top(1, Icons.calendar_month_outlined, tr('مواعيدى', 'My calendar'),
                _cCalendar),
            rowDivider,
            push(Icons.checklist_rtl, tr('مهامى', 'My tasks'),
                const TasksScreen(), _cTasks),
            rowDivider,
            push(Icons.sticky_note_2_outlined, tr('تذكيراتى', 'My notes'),
                const NotesScreen(), _cNotes),
            rowDivider,
            push(Icons.flag_outlined, tr('الأهداف', 'Goals'),
                const GoalsScreen(), _cGoals),
            sectionDivider,
            // الصلاة والأذكار — فوق الفلوس مباشرة (المصحف جوّاها).
            push(Icons.mosque_outlined, tr('صلاتى', 'My prayers'),
                const PrayerScreen(), _cPrayer),
            rowDivider,
            // ---- صحتى (يجمع الصحة + الرياضة + النظام الغذائي) ----
            groupTile(Icons.health_and_safety_outlined, tr('صحتى', 'My health'),
                accent: Colors.pink,
                [
                  GroupHubItem(Icons.dashboard_outlined,
                      tr('لوحة الصحة', 'Health hub'),
                      color: Colors.pink,
                      screen: const HealthHubScreen()),
                  GroupHubItem(Icons.favorite_outline, tr('الصحة', 'Health'),
                      color: Colors.pink,
                      screen: GroupHubScreen(
                        title: tr('الصحة', 'Health'),
                        onSelectTab: onSelect,
                        accent: Colors.pink,
                        items: [
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
            rowDivider,
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
            rowDivider,
            // ---- ملابس (بند مستقل) ----
            push(Icons.checkroom_outlined, tr('ملابسى', 'My clothes'),
                const WardrobeScreen(), _cClothes),
            rowDivider,
            groupTile(Icons.self_improvement, tr('تطوّري', 'Growth'),
                accent: Colors.indigo,
                [
                  // «الأهداف» بقى بند مستقل فوق (تحت «تذكيراتى»).
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
            rowDivider,
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
                      tr('المستندات', 'Documents'),
                      tabIndex: 4,
                      badge: () async =>
                          (await DocsRepo().expiringSoon()).length),
                  GroupHubItem(Icons.notifications_none, tr('مركز التنبيهات', 'Alerts'),
                      screen: const AlertsCenterScreen()),
                ]),
            sectionDivider,
            // دايمًا ظاهرة في الآخر.
            push(Icons.medical_services_outlined,
                tr('كارت الطوارئ', 'Emergency card'),
                const EmergencyView(), _cEmergency),
              ]),
            ),
            const SizedBox(height: 12),
            // ---- كارت التحكّم السفلى: الإعدادات + اللغة + المظهر ----
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _footerBtn(
                          context,
                          Icons.settings_outlined,
                          tr('الإعدادات', 'Settings'),
                          tr('تخصيص التطبيق', 'Customize'),
                          const Color(0xFF9B6BE8), () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()));
                      }),
                    ),
                    VerticalDivider(
                        width: 1,
                        thickness: 0.7,
                        indent: 4,
                        endIndent: 4,
                        color:
                            scheme.outlineVariant.withValues(alpha: 0.5)),
                    Expanded(
                      child: _footerBtn(
                          context,
                          Icons.language,
                          AppState.isEnglish ? 'العربية' : 'English',
                          tr('اللغة', 'Language'),
                          const Color(0xFF3B9BE8),
                          () => AppState.setLanguage(
                              AppState.isEnglish ? 'ar' : 'en')),
                    ),
                    VerticalDivider(
                        width: 1,
                        thickness: 0.7,
                        indent: 4,
                        endIndent: 4,
                        color:
                            scheme.outlineVariant.withValues(alpha: 0.5)),
                    Expanded(
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: AppState.themeMode,
                        builder: (context, mode, _) {
                          final isDark = mode == ThemeMode.dark ||
                              (mode == ThemeMode.system &&
                                  MediaQuery.platformBrightnessOf(context) ==
                                      Brightness.dark);
                          return _footerBtn(
                              context,
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              isDark ? tr('فاتح', 'Light') : tr('غامق', 'Dark'),
                              tr('الوضع الليلى', 'Night mode'),
                              const Color(0xFFE8A33B),
                              () => AppState.setThemeMode(
                                  isDark ? ThemeMode.light : ThemeMode.dark));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ---- تسجيل الخروج ----
            Material(
              color: scheme.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: scheme.error.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.logout, color: scheme.error, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Center(
                          child: Text(tr('تسجيل الخروج', 'Log out'),
                              style: TextStyle(
                                  color: scheme.error,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 52),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// زر أداة سفلي (أيقونة ملوّنة + عنوان + وصف صغير تحته).
  Widget _footerBtn(BuildContext context, IconData icon, String label,
      String sub, Color color, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.5, color: scheme.onSurfaceVariant)),
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
