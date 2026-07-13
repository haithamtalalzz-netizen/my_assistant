import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/app_state.dart';
import '../core/l10n.dart';
import '../data/settings_repo.dart';
import 'account_screen.dart';
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
import 'food/diet_plans_screen.dart';
import 'recipes_screen.dart';
import 'brain/charts_screen.dart';
import 'brain/chat_screen.dart';
import 'emergency_view.dart';
import 'food/shopping_list_screen.dart';
import 'group_hub_screen.dart';
import 'gym/exercise_library_screen.dart';
import 'gym/gym_screen.dart';
import 'gym/progress_screen.dart';
import 'gym/walk_tracker_screen.dart';
import 'gym/workout_programs_screen.dart';
import 'health/cycle_screen.dart';
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
import 'worship/prayer_screen.dart';
import 'worship/quran_screen.dart';

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

    // مجموعة → بتفتح صفحة فيها بنودها على شكل مربعات (زي هَبّات ملف المركبة).
    Widget groupTile(IconData icon, String title, List<GroupHubItem> items,
            {Widget? trailingBadge, Color? accent}) =>
        ListTile(
          leading: Icon(icon, color: accent),
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
          trailing: const Icon(Icons.chevron_right, size: 20),
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
            top(0, Icons.wb_sunny_outlined, tr('اليوم', 'Today')),
            push(Icons.psychology_outlined, tr('اسأل مديرك', 'Ask your manager'),
                const ChatScreen()),
            push(Icons.mosque_outlined, tr('الصلاة والأذكار', 'Prayer & Adhkar'),
                const PrayerScreen()),
            push(Icons.import_contacts_outlined, tr('المصحف', 'Quran'),
                const MushafScreen()),
            top(1, Icons.event_note_outlined, tr('الجدول', 'Schedule')),
            const Divider(),
            // مجموعات بحسب مجال الحياة.
            groupTile(
                Icons.account_balance_wallet_outlined,
                tr('الفلوس', 'Money'),
                accent: Colors.teal,
                [
                  GroupHubItem(Icons.account_balance_wallet_outlined,
                      tr('المحفظة', 'Wallet'), tabIndex: 2),
                  GroupHubItem(Icons.savings_outlined, tr('الادخار', 'Savings'),
                      screen: const SavingsScreen()),
                  GroupHubItem(Icons.diamond_outlined,
                      tr('أموالي الخارجية', 'My assets'),
                      screen: const AssetsScreen()),
                  GroupHubItem(Icons.handshake_outlined,
                      tr('الديون والسلف', 'Debts'),
                      screen: const DebtsScreen()),
                  GroupHubItem(Icons.groups_outlined, tr('الجمعيات', "Gam'iyas"),
                      screen: const GameyaScreen()),
                  GroupHubItem(Icons.volunteer_activism_outlined,
                      tr('الواجبات الاجتماعية', 'Social ledger'),
                      screen: const SocialScreen()),
                ],
                trailingBadge: FutureBuilder<int>(
                  future: _moneyDueCount(),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return n == 0 ? const SizedBox.shrink() : badge(n);
                  },
                )),
            // ---- الصحة ----
            groupTile(Icons.favorite_outline, tr('الصحة', 'Health'),
                accent: Colors.pink,
                [
                  GroupHubItem(Icons.dashboard_outlined,
                      tr('لوحة الصحة', 'Health hub'),
                      screen: const HealthHubScreen()),
                  if (AppState.gender.value == 'female')
                    GroupHubItem(Icons.favorite,
                        tr('الدورة الشهرية', 'Menstrual cycle'),
                        screen: const CycleScreen(), color: Colors.pink),
                  GroupHubItem(Icons.task_alt, tr('العادات', 'Habits'),
                      tabIndex: 3),
                  GroupHubItem(Icons.medical_information_outlined,
                      tr('الملف الطبي', 'Medical file'),
                      screen: const MedicalScreen()),
                  GroupHubItem(Icons.medication_outlined,
                      tr('صيدلية البيت', 'Home pharmacy'),
                      screen: const PharmacyScreen()),
                ]),
            // ---- الرياضة ----
            groupTile(Icons.fitness_center, tr('الرياضة', 'Exercise'),
                accent: Colors.deepPurple,
                [
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
                ]),
            // ---- النظام الغذائي ----
            groupTile(Icons.restaurant_outlined,
                tr('النظام الغذائي', 'Nutrition'),
                accent: Colors.green,
                [
                  GroupHubItem(Icons.restaurant_menu,
                      tr('الأنظمة الغذائية', 'Diet plans'),
                      screen: const DietPlansScreen()),
                  GroupHubItem(Icons.restaurant_menu_outlined,
                      tr('دفتر الوصفات', 'Recipes'),
                      screen: const RecipesScreen()),
                ]),
            groupTile(Icons.home_outlined,
                tr('البيت والمشتريات', 'Home & shopping'),
                accent: Colors.brown,
                [
                  GroupHubItem(Icons.home_repair_service_outlined,
                      tr('صيانة البيت', 'Home maintenance'),
                      screen: const HomeMaintenanceScreen()),
                  GroupHubItem(Icons.verified_outlined,
                      tr('أرشيف الضمانات', 'Warranties'),
                      screen: const WarrantyScreen()),
                  GroupHubItem(Icons.speed_outlined,
                      tr('قراءات العدادات', 'Meter readings'),
                      screen: const MetersScreen()),
                  GroupHubItem(Icons.yard_outlined,
                      tr('نباتات البيت', 'Home plants'),
                      screen: const PlantsScreen()),
                  GroupHubItem(Icons.checkroom_outlined,
                      tr('خزانة الملابس', 'Wardrobe'),
                      screen: const WardrobeScreen()),
                  GroupHubItem(Icons.shopping_cart_outlined,
                      tr('قائمة التسوق', 'Shopping list'),
                      screen: const ShoppingListScreen()),
                ]),
            groupTile(
                Icons.self_improvement, tr('حياتي وتطوّري', 'My life & growth'),
                accent: Colors.indigo,
                [
                  GroupHubItem(Icons.menu_book_outlined,
                      tr('مراجعة القرآن', 'Quran review'),
                      screen: const QuranScreen()),
                  GroupHubItem(Icons.flag_outlined, tr('التحديات', 'Challenges'),
                      screen: const ChallengesScreen()),
                  GroupHubItem(Icons.auto_stories_outlined,
                      tr('اليوميات', 'Diary'),
                      screen: const DiaryScreen()),
                  GroupHubItem(Icons.emoji_events_outlined,
                      tr('عدّاد الإقلاع', 'Quit counter'),
                      screen: const QuitScreen()),
                  GroupHubItem(Icons.hourglass_empty,
                      tr('الكبسولة الزمنية', 'Time capsule'),
                      screen: const CapsuleScreen()),
                  GroupHubItem(Icons.diversity_1_outlined,
                      tr('صلة الرحم', 'Keep in touch'),
                      screen: const RelativesScreen()),
                  GroupHubItem(Icons.lock_outline,
                      tr('الخزنة السرية', 'Secret vault'),
                      screen: const SecretNotesScreen()),
                ]),
            groupTile(Icons.insights_outlined,
                tr('المتابعة والأدوات', 'Review & tools'),
                accent: Colors.blue,
                [
                  GroupHubItem(Icons.lightbulb_outline,
                      tr('رؤى المدير', 'Insights'), tabIndex: 5),
                  GroupHubItem(Icons.pie_chart_outline, tr('التقارير', 'Reports'),
                      screen: const ReportsHubScreen()),
                  GroupHubItem(Icons.bar_chart, tr('إحصائياتك', 'Charts'),
                      screen: const ChartsScreen()),
                  GroupHubItem(Icons.calendar_month_outlined,
                      tr('تقويم النتيجة', 'Activity calendar'),
                      screen: const CalendarScreen()),
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
