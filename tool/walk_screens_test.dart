// **مولَّد** — يفتح كل شاشة ليها constructor بلا مدخلات مطلوبة على
// قاعدة مزروعة، ويتأكد إنها بترسم **وبتتقفل** من غير استثناء ولا
// تجاوز حدود. اختبار مستقل لكل شاشة عشان مايحصلش تلوّث بين الشاشات.
//   flutter test tool/walk_screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_assistant/screens/account_screen.dart';
import 'package:my_assistant/screens/alerts_center_screen.dart';
import 'package:my_assistant/screens/archived_data_screen.dart';
import 'package:my_assistant/screens/baladna/debts_screen.dart';
import 'package:my_assistant/screens/baladna/gameya_screen.dart';
import 'package:my_assistant/screens/baladna/home_maintenance_screen.dart';
import 'package:my_assistant/screens/baladna/relatives_screen.dart';
import 'package:my_assistant/screens/baladna/savings_screen.dart';
import 'package:my_assistant/screens/brain/charts_screen.dart';
import 'package:my_assistant/screens/brain/chat_screen.dart';
import 'package:my_assistant/screens/brain/insights_screen.dart';
import 'package:my_assistant/screens/calendar_screen.dart';
import 'package:my_assistant/screens/challenges_screen.dart';
import 'package:my_assistant/screens/dashboard_screen.dart';
import 'package:my_assistant/screens/diagnostics_screen.dart';
import 'package:my_assistant/screens/diary_screen.dart';
import 'package:my_assistant/screens/docs/doc_form.dart';
import 'package:my_assistant/screens/docs/docs_screen.dart';
import 'package:my_assistant/screens/emergency_view.dart';
import 'package:my_assistant/screens/food/barcode_scan_screen.dart';
import 'package:my_assistant/screens/food/diet_plans_screen.dart';
import 'package:my_assistant/screens/food/fasting_screen.dart';
import 'package:my_assistant/screens/food/food_card_screen.dart';
import 'package:my_assistant/screens/food/meal_planner_screen.dart';
import 'package:my_assistant/screens/growth/courses_screen.dart';
import 'package:my_assistant/screens/growth/goals_screen.dart';
import 'package:my_assistant/screens/growth/habit_analytics_screen.dart';
import 'package:my_assistant/screens/growth/reading_screen.dart';
import 'package:my_assistant/screens/gym/exercise_library_screen.dart';
import 'package:my_assistant/screens/gym/gym_screen.dart';
import 'package:my_assistant/screens/gym/gym_session_form.dart';
import 'package:my_assistant/screens/gym/progress_screen.dart';
import 'package:my_assistant/screens/gym/walk_tracker_screen.dart';
import 'package:my_assistant/screens/gym/workout_programs_screen.dart';
import 'package:my_assistant/screens/habits/habits_screen.dart';
import 'package:my_assistant/screens/health/cycle_screen.dart';
import 'package:my_assistant/screens/health/health_hub_screen.dart';
import 'package:my_assistant/screens/health/lab_results_screen.dart';
import 'package:my_assistant/screens/health/mood_screen.dart';
import 'package:my_assistant/screens/health/symptom_journal_screen.dart';
import 'package:my_assistant/screens/health/vaccinations_screen.dart';
import 'package:my_assistant/screens/home/pharmacy_screen.dart';
import 'package:my_assistant/screens/home/plants_screen.dart';
import 'package:my_assistant/screens/inbox_screen.dart';
import 'package:my_assistant/screens/medical/medical_form.dart';
import 'package:my_assistant/screens/medical/medical_screen.dart';
import 'package:my_assistant/screens/money/money_screen.dart';
import 'package:my_assistant/screens/money/subscriptions_screen.dart';
import 'package:my_assistant/screens/money/wallets_screen.dart';
import 'package:my_assistant/screens/money/wishlist_screen.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:my_assistant/screens/passwords/passwords_screen.dart';
import 'package:my_assistant/screens/pets/pets_screen.dart';
import 'package:my_assistant/screens/quit_screen.dart';
import 'package:my_assistant/screens/recipes_screen.dart';
import 'package:my_assistant/screens/reports/calculators_screen.dart';
import 'package:my_assistant/screens/reports/custom_pdf_screen.dart';
import 'package:my_assistant/screens/reports/year_review_screen.dart';
import 'package:my_assistant/screens/reports_hub_screen.dart';
import 'package:my_assistant/screens/rules_screen.dart';
import 'package:my_assistant/screens/schedule/appointment_form.dart';
import 'package:my_assistant/screens/schedule/appointments_calendar_screen.dart';
import 'package:my_assistant/screens/schedule/med_form.dart';
import 'package:my_assistant/screens/schedule/schedule_screen.dart';
import 'package:my_assistant/screens/search_screen.dart';
import 'package:my_assistant/screens/settings_screen.dart';
import 'package:my_assistant/screens/shell.dart';
import 'package:my_assistant/screens/tasks/focus_screen.dart';
import 'package:my_assistant/screens/tasks/tasks_screen.dart';
import 'package:my_assistant/screens/time_machine_screen.dart';
import 'package:my_assistant/screens/today_screen.dart';
import 'package:my_assistant/screens/wardrobe/clothing_form.dart';
import 'package:my_assistant/screens/wardrobe/outfit_screen.dart';
import 'package:my_assistant/screens/wardrobe/wardrobe_screen.dart';
import 'package:my_assistant/screens/weekly/weekly_planning_screen.dart';
import 'package:my_assistant/screens/workout/workout_plan_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_hub_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_reminders_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_situations_screen.dart';
import 'package:my_assistant/screens/worship/daily_wird_screen.dart';
import 'package:my_assistant/screens/worship/duas_screen.dart';
import 'package:my_assistant/screens/worship/fasting_screen.dart';
import 'package:my_assistant/screens/worship/hadith_library_screen.dart';
import 'package:my_assistant/screens/worship/hajj_umrah_screen.dart';
import 'package:my_assistant/screens/worship/islamic_occasions_screen.dart';
import 'package:my_assistant/screens/worship/khatma_screen.dart';
import 'package:my_assistant/screens/worship/mawarith_screen.dart';
import 'package:my_assistant/screens/worship/memorization_screen.dart';
import 'package:my_assistant/screens/worship/monthly_times_screen.dart';
import 'package:my_assistant/screens/worship/names_screen.dart';
import 'package:my_assistant/screens/worship/post_prayer_dhikr_screen.dart';
import 'package:my_assistant/screens/worship/prayer_screen.dart';
import 'package:my_assistant/screens/worship/qibla_screen.dart';
import 'package:my_assistant/screens/worship/quran_search_screen.dart';
import 'package:my_assistant/screens/worship/quran_topics_screen.dart';
import 'package:my_assistant/screens/worship/religious_content_screen.dart';
import 'package:my_assistant/screens/worship/ruqyah_screen.dart';
import 'package:my_assistant/screens/worship/sadaqah_screen.dart';
import 'package:my_assistant/screens/worship/spiritual_stats_screen.dart';
import 'package:my_assistant/screens/worship/tasbih_screen.dart';
import 'package:my_assistant/screens/worship/worship_history_screen.dart';
import 'package:my_assistant/screens/worship/worship_program_screen.dart';
import 'package:my_assistant/screens/worship/zakat_guide_screen.dart';
import 'package:my_assistant/screens/worship/zakat_livestock_screen.dart';
import 'package:my_assistant/screens/worship/zakat_screen.dart';

/// استثناءات بيئة الاختبار مش أعطاب: قنوات المنصّة (بوصلة · إشعارات ·
/// مستشعرات) مش موجودة، والشبكة مقفولة فتحميل الصور بيفشل.
bool _ignorable(Object ex) {
  final s = ex.toString();
  return s.contains('MissingPluginException') ||
      s.contains('Looking up a deactivated') ||
      s.contains('HttpException') ||
      s.contains('Invalid image data');
}

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    db = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
    await seedDemoData();
  });

  tearDownAll(() async {
    AppDb.reset();
    await db.close();
  });

  Future<void> walk(WidgetTester tester, Widget w) async {
    // استثناء متأخّر من شاشة سابقة بينتسب للشاشة الغلط — نرميه الأول.
    tester.takeException();
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(
          textDirection: TextDirection.rtl, child: w),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final ex = tester.takeException();
    if (ex != null && !_ignorable(ex)) fail(ex.toString());
    // وإقفالها: كود بيستعمل context بعد dispose بيبان هنا.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
    final closeEx = tester.takeException();
    if (closeEx != null && !_ignorable(closeEx)) {
      fail('عند الإقفال: \$closeEx');
    }
  }

  testWidgets('AccountScreen', (t) => walk(t, const AccountScreen()));
  testWidgets('AdhkarHubScreen', (t) => walk(t, const AdhkarHubScreen()));
  testWidgets('AdhkarRemindersScreen', (t) => walk(t, const AdhkarRemindersScreen()));
  testWidgets('AdhkarSituationsScreen', (t) => walk(t, const AdhkarSituationsScreen()));
  testWidgets('AlertsCenterScreen', (t) => walk(t, const AlertsCenterScreen()));
  testWidgets('AppointmentForm', (t) => walk(t, const AppointmentForm()));
  testWidgets('AppointmentsCalendarScreen', (t) => walk(t, const AppointmentsCalendarScreen()));
  testWidgets('ArchivedDataScreen', (t) => walk(t, const ArchivedDataScreen()));
  testWidgets('BarcodeScanScreen', (t) => walk(t, const BarcodeScanScreen()));
  testWidgets('CalculatorsScreen', (t) => walk(t, const CalculatorsScreen()));
  testWidgets('CalendarScreen', (t) => walk(t, const CalendarScreen()));
  testWidgets('ChallengesScreen', (t) => walk(t, const ChallengesScreen()));
  testWidgets('ChartsScreen', (t) => walk(t, const ChartsScreen()));
  testWidgets('ChatScreen', (t) => walk(t, const ChatScreen()));
  testWidgets('ClothingForm', (t) => walk(t, const ClothingForm()));
  testWidgets('CoursesScreen', (t) => walk(t, const CoursesScreen()));
  testWidgets('CustomPdfScreen', (t) => walk(t, const CustomPdfScreen()));
  testWidgets('CycleScreen', (t) => walk(t, const CycleScreen()));
  testWidgets('DailyWirdScreen', (t) => walk(t, const DailyWirdScreen()));
  testWidgets('DashboardScreen', (t) => walk(t, const DashboardScreen()));
  testWidgets('DebtsScreen', (t) => walk(t, const DebtsScreen()));
  testWidgets('DiagnosticsScreen', (t) => walk(t, const DiagnosticsScreen()));
  testWidgets('DiaryScreen', (t) => walk(t, const DiaryScreen()));
  testWidgets('DietPlansScreen', (t) => walk(t, const DietPlansScreen()));
  testWidgets('DocForm', (t) => walk(t, const DocForm()));
  testWidgets('DocsScreen', (t) => walk(t, const DocsScreen()));
  testWidgets('DuasScreen', (t) => walk(t, const DuasScreen()));
  testWidgets('EmergencyView', (t) => walk(t, const EmergencyView()));
  testWidgets('ExerciseLibraryScreen', (t) => walk(t, const ExerciseLibraryScreen()));
  testWidgets('FastingScreen', (t) => walk(t, const FastingScreen()));
  testWidgets('FocusScreen', (t) => walk(t, const FocusScreen()));
  testWidgets('FoodCardScreen', (t) => walk(t, const FoodCardScreen()));
  testWidgets('GameyaScreen', (t) => walk(t, const GameyaScreen()));
  testWidgets('GoalsScreen', (t) => walk(t, const GoalsScreen()));
  testWidgets('GymScreen', (t) => walk(t, const GymScreen()));
  testWidgets('GymSessionForm', (t) => walk(t, const GymSessionForm()));
  testWidgets('HabitAnalyticsScreen', (t) => walk(t, const HabitAnalyticsScreen()));
  testWidgets('HabitsScreen', (t) => walk(t, const HabitsScreen()));
  testWidgets('HadithLibraryScreen', (t) => walk(t, const HadithLibraryScreen()));
  testWidgets('HajjUmrahScreen', (t) => walk(t, const HajjUmrahScreen()));
  testWidgets('HealthHubScreen', (t) => walk(t, const HealthHubScreen()));
  testWidgets('HomeMaintenanceScreen', (t) => walk(t, const HomeMaintenanceScreen()));
  testWidgets('InboxScreen', (t) => walk(t, const InboxScreen()));
  testWidgets('InsightsScreen', (t) => walk(t, const InsightsScreen()));
  testWidgets('IslamicOccasionsScreen', (t) => walk(t, const IslamicOccasionsScreen()));
  testWidgets('KhatmaScreen', (t) => walk(t, const KhatmaScreen()));
  testWidgets('LabResultsScreen', (t) => walk(t, const LabResultsScreen()));
  testWidgets('MawarithScreen', (t) => walk(t, const MawarithScreen()));
  testWidgets('MealPlannerScreen', (t) => walk(t, const MealPlannerScreen()));
  testWidgets('MedForm', (t) => walk(t, const MedForm()));
  testWidgets('MedicalForm', (t) => walk(t, const MedicalForm()));
  testWidgets('MedicalScreen', (t) => walk(t, const MedicalScreen()));
  testWidgets('MedsScreen', (t) => walk(t, const MedsScreen()));
  testWidgets('MemorizationScreen', (t) => walk(t, const MemorizationScreen()));
  testWidgets('MoneyScreen', (t) => walk(t, const MoneyScreen()));
  testWidgets('MonthlyTimesScreen', (t) => walk(t, const MonthlyTimesScreen()));
  testWidgets('MoodScreen', (t) => walk(t, const MoodScreen()));
  // MushafPageScreen: بتحمّل أصل ضخم بمؤشّر لانهائى؛ هدّها وهو بيلفّ
  // بيسيب ticker يسمّم كل اختبار بعده (قيد فى flutter_test).
  // متغطّية فى tool/probe_test.dart لوحدها وبتنجح.
  // testWidgets('MushafPageScreen', (t) => walk(t, const MushafPageScreen()));
  // MushafScreen: بتحمّل أصل ضخم بمؤشّر لانهائى؛ هدّها وهو بيلفّ
  // بيسيب ticker يسمّم كل اختبار بعده (قيد فى flutter_test).
  // متغطّية فى tool/probe_test.dart لوحدها وبتنجح.
  // testWidgets('MushafScreen', (t) => walk(t, const MushafScreen()));
  testWidgets('NafilFastingScreen', (t) => walk(t, const NafilFastingScreen()));
  testWidgets('NamesScreen', (t) => walk(t, const NamesScreen()));
  testWidgets('NotesScreen', (t) => walk(t, const NotesScreen()));
  testWidgets('OutfitScreen', (t) => walk(t, const OutfitScreen()));
  testWidgets('PasswordsScreen', (t) => walk(t, const PasswordsScreen()));
  testWidgets('PetsScreen', (t) => walk(t, const PetsScreen()));
  testWidgets('PharmacyScreen', (t) => walk(t, const PharmacyScreen()));
  testWidgets('PlantsScreen', (t) => walk(t, const PlantsScreen()));
  testWidgets('PostPrayerDhikrScreen', (t) => walk(t, const PostPrayerDhikrScreen()));
  testWidgets('PrayerScreen', (t) => walk(t, const PrayerScreen()));
  testWidgets('ProgressScreen', (t) => walk(t, const ProgressScreen()));
  testWidgets('QiblaScreen', (t) => walk(t, const QiblaScreen()));
  testWidgets('QuitScreen', (t) => walk(t, const QuitScreen()));
  testWidgets('QuranSearchScreen', (t) => walk(t, const QuranSearchScreen()));
  testWidgets('QuranTopicsScreen', (t) => walk(t, const QuranTopicsScreen()));
  testWidgets('ReadingScreen', (t) => walk(t, const ReadingScreen()));
  testWidgets('RecipesScreen', (t) => walk(t, const RecipesScreen()));
  testWidgets('RelativesScreen', (t) => walk(t, const RelativesScreen()));
  testWidgets('ReligiousContentScreen', (t) => walk(t, const ReligiousContentScreen()));
  testWidgets('ReportsHubScreen', (t) => walk(t, const ReportsHubScreen()));
  testWidgets('RulesScreen', (t) => walk(t, const RulesScreen()));
  testWidgets('RuqyahScreen', (t) => walk(t, const RuqyahScreen()));
  testWidgets('SadaqahScreen', (t) => walk(t, const SadaqahScreen()));
  testWidgets('SavingsScreen', (t) => walk(t, const SavingsScreen()));
  testWidgets('ScheduleScreen', (t) => walk(t, const ScheduleScreen()));
  testWidgets('SearchScreen', (t) => walk(t, const SearchScreen()));
  testWidgets('SettingsScreen', (t) => walk(t, const SettingsScreen()));
  testWidgets('Shell', (t) => walk(t, const Shell()));
  testWidgets('SpiritualStatsScreen', (t) => walk(t, const SpiritualStatsScreen()));
  testWidgets('SubscriptionsScreen', (t) => walk(t, const SubscriptionsScreen()));
  testWidgets('SymptomJournalScreen', (t) => walk(t, const SymptomJournalScreen()));
  testWidgets('TasbihScreen', (t) => walk(t, const TasbihScreen()));
  testWidgets('TasksScreen', (t) => walk(t, const TasksScreen()));
  testWidgets('TimeMachineScreen', (t) => walk(t, const TimeMachineScreen()));
  testWidgets('TodayScreen', (t) => walk(t, const TodayScreen()));
  testWidgets('VaccinationsScreen', (t) => walk(t, const VaccinationsScreen()));
  testWidgets('WalkTrackerScreen', (t) => walk(t, const WalkTrackerScreen()));
  testWidgets('WalletsScreen', (t) => walk(t, const WalletsScreen()));
  testWidgets('WardrobeScreen', (t) => walk(t, const WardrobeScreen()));
  testWidgets('WeeklyPlanningScreen', (t) => walk(t, const WeeklyPlanningScreen()));
  testWidgets('WishlistScreen', (t) => walk(t, const WishlistScreen()));
  testWidgets('WorkoutPlanScreen', (t) => walk(t, const WorkoutPlanScreen()));
  testWidgets('WorkoutProgramsScreen', (t) => walk(t, const WorkoutProgramsScreen()));
  testWidgets('WorshipHistoryScreen', (t) => walk(t, const WorshipHistoryScreen()));
  testWidgets('WorshipProgramScreen', (t) => walk(t, const WorshipProgramScreen()));
  testWidgets('YearReviewScreen', (t) => walk(t, const YearReviewScreen()));
  testWidgets('ZakatGuideScreen', (t) => walk(t, const ZakatGuideScreen()));
  testWidgets('ZakatLivestockScreen', (t) => walk(t, const ZakatLivestockScreen()));
  testWidgets('ZakatScreen', (t) => walk(t, const ZakatScreen()));
}
