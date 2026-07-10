import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/health_service.dart';
import '../core/l10n.dart';
import '../core/prayers.dart';
import '../core/water_guard.dart';
import '../core/weather.dart';
import '../core/widget_bridge.dart';
import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/docs_repo.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/plants_repo.dart';
import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/meds_repo.dart';
import '../data/money_repo.dart';
import '../data/occasions_repo.dart';
import '../data/settings_repo.dart';
import '../data/weekly_repo.dart';
import '../data/workout_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/decorations.dart';
import 'brain/day_plan_screen.dart';
import 'food/meal_sheet.dart';
import 'food/shopping_list_screen.dart';
import 'calendar_screen.dart';
import 'home/pharmacy_screen.dart';
import 'money/quick_expense_sheet.dart';
import '../widgets/search_action.dart';
import 'schedule/appointment_form.dart';
import 'voice/voice_sheet.dart';
import 'weekly/weekly_planning_screen.dart';
import 'workout/workout_plan_screen.dart';

/// شاشة اليوم — كل حاجة النهارده في مكان واحد + ملخص "المدير".
class TodayScreen extends StatefulWidget {
  final void Function(int tabIndex)? onGoToTab;
  final Widget? drawer;

  const TodayScreen({super.key, this.onGoToTab, this.drawer});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _settings = SettingsRepo();
  final _appts = AppointmentsRepo();
  final _meds = MedsRepo();
  final _health = HealthRepo();
  final _money = MoneyRepo();
  final _docs = DocsRepo();
  final _habits = HabitsRepo();

  bool _loading = true;
  bool _editingSleep = false;
  String _name = '';
  int _waterGoal = 8;
  int _water = 0;
  double? _sleep;
  List<Appointment> _todayAppts = [];
  List<Medication> _activeMeds = [];
  Set<String> _taken = {};
  List<Habit> _habitList = [];
  Set<int> _doneHabits = {};
  Map<int, int> _streaks = {};
  double _todaySpend = 0;
  List<DocItem> _expiring = [];
  PrayerDay? _prayers;
  bool _weeklyDue = false;
  List<Appointment> _chronic = [];
  int? _steps;
  int? _calories;
  int? _restingHr;
  double? _distanceKm;
  int _calorieGoal = 0;
  bool _hardDay = false;
  List<Meal> _meals = [];
  Map<int, String> _workoutPlan = {};
  bool _workoutDone = false;
  String? _missedWorkout;
  bool _ramadan = false;
  List<Occasion> _occasionsSoon = [];
  List<RecurringBill> _dueBills = [];
  List<HomeMaintenance> _dueMaintenance = [];
  List<Plant> _duePlants = [];
  WeatherToday? _weather;

  String get _today => dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final day = dayKey(now);
    final name = await _settings.userName();
    final goal = await _settings.waterGoal();
    final water = await _health.waterOn(day);
    var sleep = await _health.sleepOn(day);
    int? steps;
    int? calories;
    int? restingHr;
    double? distanceKm;
    if (await _settings.healthSyncEnabled()) {
      steps = await HealthService.stepsToday();
      // بنخزن الخطوات يوميًا عشان الرؤى وتقرير الدكتور.
      if (steps != null && steps > 0) {
        await MeasurementsRepo().upsertSteps(day, steps);
      }
      // مقاييس الساعة الذكية (كلها best-effort — أي واحدة مش متاحة ترجع null).
      calories = await HealthService.activeCaloriesToday();
      restingHr = await HealthService.restingHeartRate();
      distanceKm = await HealthService.distanceTodayKm();
      // بنخزن السعرات والمسافة يوميًا عشان الرؤى وتقرير الدكتور.
      await MeasurementsRepo()
          .upsertFitness(day, calories: calories, distanceKm: distanceKm);
      // لو الساعة سجّلت تمرين النهارده، نعلّم تمرين اليوم «اتعمل» تلقائيًا.
      final gymWorkouts = await HealthService.workoutsToday();
      if (gymWorkouts != null && gymWorkouts > 0) {
        final wRepo = WorkoutRepo();
        if (!await wRepo.doneOn(day)) {
          final planTitle = (await wRepo.plan())[now.weekday] ?? '';
          await wRepo.setDone(day, true, title: planTitle);
        }
      }
      if (sleep == null) {
        // النوم بييجي تلقائيًا من Health Connect لو مفيش تسجيل يدوي.
        final auto = await HealthService.lastNightSleepHours();
        if (auto != null) {
          await _health.setSleep(day, auto);
          sleep = auto;
        }
      }
    }
    final appts = await _appts.forDay(now);
    final meds = await _meds.all(activeOnly: true);
    final taken = await _meds.takenOn(day);
    final habits = await _habits.active();
    final doneHabits = await _habits.doneOn(day);
    final streaks = <int, int>{};
    for (final h in habits) {
      streaks[h.id!] = computeStreak(await _habits.daysFor(h.id!), now);
    }
    final spend = await _money.totalForDay(day);
    final expiring = await _docs.expiringSoon();
    final prayers =
        prayerTimesFor(now, governorateByName(await _settings.governorateName()));
    // بانر التخطيط الأسبوعي يظهر من الجمعة للأحد لو أسبوع ده لسه مااتخططش.
    final weekendDay = now.weekday == DateTime.friday ||
        now.weekday == DateTime.saturday ||
        now.weekday == DateTime.sunday;
    final weeklyDue = weekendDay &&
        await WeeklyRepo().forWeek(currentWeekKey(now)) == null;
    final chronic = await _appts.chronicallyPostponed();
    final meals = await MealsRepo().forDay(day);
    final calorieGoal = await _settings.calorieGoal();
    final hardDay = await _settings.hardDayMode();
    final workoutRepo = WorkoutRepo();
    final workoutPlan = await workoutRepo.plan();
    final workoutDone = await workoutRepo.doneOn(day);
    final missedWorkout = await workoutRepo.missedYesterdaySuggestion(now);
    final ramadan = await _settings.ramadanMode();
    final occasionsSoon = await OccasionsRepo().upcomingWithinWindow(now);
    final dueBills = await BillsRepo().due(now);
    final dueMaintenance = await HomeMaintenanceRepo().due(now);
    final duePlants = await PlantsRepo().due(now);
    if (!mounted) return;
    setState(() {
      _name = name;
      _waterGoal = goal;
      _water = water;
      _sleep = sleep;
      _todayAppts = appts;
      _activeMeds = meds;
      _taken = taken;
      _habitList = habits;
      _doneHabits = doneHabits;
      _streaks = streaks;
      _todaySpend = spend;
      _expiring = expiring;
      _prayers = prayers;
      _weeklyDue = weeklyDue;
      _chronic = chronic;
      _steps = steps;
      _calories = calories;
      _restingHr = restingHr;
      _distanceKm = distanceKm;
      _calorieGoal = calorieGoal;
      _hardDay = hardDay;
      _meals = meals;
      _workoutPlan = workoutPlan;
      _workoutDone = workoutDone;
      _missedWorkout = missedWorkout;
      _ramadan = ramadan;
      _occasionsSoon = occasionsSoon;
      _dueBills = dueBills;
      _dueMaintenance = dueMaintenance;
      _duePlants = duePlants;
      _editingSleep = false;
      _loading = false;
    });
    unawaited(WidgetBridge.push());
    // الطقس best-effort — بيتحدث لوحده لما يوصل من غير ما يعطل الشاشة.
    unawaited(_loadWeather());
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.today();
    if (w != null && mounted) setState(() => _weather = w);
  }

  String _summaryText() {
    final parts = <String>[];
    if (_ramadan) parts.add(tr('رمضان كريم.', 'Ramadan Kareem.'));
    if (_weather != null) parts.add(_weather!.summaryLine());
    if (_dueMaintenance.isNotEmpty) {
      parts.add(_dueMaintenance.length == 1
          ? tr('صيانة مستحقة: ${_dueMaintenance.first.name}.',
              'Maintenance due: ${_dueMaintenance.first.name}.')
          : tr('${arNum(_dueMaintenance.length)} صيانات بيت مستحقة.',
              '${arNum(_dueMaintenance.length)} home maintenance items due.'));
    }
    if (_duePlants.isNotEmpty) {
      parts.add(_duePlants.length == 1
          ? tr('🪴 ${_duePlants.first.name} محتاجة مياه.',
              '🪴 ${_duePlants.first.name} needs water.')
          : tr('🪴 ${arNum(_duePlants.length)} نباتات محتاجة مياه.',
              '🪴 ${arNum(_duePlants.length)} plants need water.'));
    }
    for (final o in _occasionsSoon.take(1)) {
      final days = o
          .nextOccurrence(DateTime.now())
          .difference(dateOnly(DateTime.now()))
          .inDays;
      final label = o.person.isEmpty ? o.title : '${o.title} ${o.person}';
      parts.add(days == 0
          ? tr('$label النهارده!', '$label today!')
          : days == 1
              ? tr('$label بكرة — جهز نفسك.', '$label tomorrow — get ready.')
              : tr('$label بعد ${arNum(days)} أيام.',
                  '$label in ${arNum(days)} days.'));
    }
    if (_missedWorkout != null) {
      parts.add(tr('تمرين امبارح ($_missedWorkout) فاتك — تعوضه النهارده؟',
          "Yesterday's workout ($_missedWorkout) was missed — make it up today?"));
    }
    if (_todayAppts.isEmpty) {
      parts.add(tr('مفيش مواعيد النهارده.', 'No appointments today.'));
    } else if (_todayAppts.length == 1) {
      parts.add(tr('عندك موعد واحد النهارده: ${_todayAppts.first.title}.',
          'One appointment today: ${_todayAppts.first.title}.'));
    } else {
      parts.add(tr('عندك ${arNum(_todayAppts.length)} مواعيد النهارده.',
          'You have ${arNum(_todayAppts.length)} appointments today.'));
    }
    final totalSlots =
        _activeMeds.fold<int>(0, (sum, m) => sum + m.times.length);
    final remaining = totalSlots - _taken.length;
    if (remaining > 0) {
      parts.add(remaining == 1
          ? tr('فاضل جرعة دوا واحدة.', 'One medication dose left.')
          : tr('فاضل ${arNum(remaining)} جرعات دوا.',
              '${arNum(remaining)} medication doses left.'));
    }
    if (_chronic.isNotEmpty) {
      final a = _chronic.first;
      parts.add(tr(
          '«${a.title}» اتأجل ${arNum(a.postponeCount)} مرات — نقسمه لخطوات أصغر؟',
          '"${a.title}" postponed ${arNum(a.postponeCount)}× — split into smaller steps?'));
    }
    if (_sleep != null && _sleep! < 6) {
      parts.add(tr('نومك امبارح كان قليل — حاول تنام بدري.',
          'You slept little last night — try to sleep earlier.'));
    }
    if (_expiring.isNotEmpty) {
      parts.add(_expiring.length == 1
          ? tr('في مستند محتاج تجديد.', 'A document needs renewing.')
          : tr('في ${arNum(_expiring.length)} مستندات محتاجة تجديد.',
              '${arNum(_expiring.length)} documents need renewing.'));
    }
    return parts.take(3).join(' ');
  }

  Future<void> _changeWater(int delta) async {
    final next = await _health.addWater(_today, delta);
    if (mounted) setState(() => _water = next);
    unawaited(WidgetBridge.push());
    unawaited(WaterGuard.ensureScheduled());
  }

  Future<void> _openVoice() async {
    final logged = await showVoiceSheet(context);
    if (logged == true && mounted) await _load();
  }

  Future<void> _setSleep(double hours) async {
    await _health.setSleep(_today, hours);
    if (mounted) {
      setState(() {
        _sleep = hours;
        _editingSleep = false;
      });
    }
  }

  Future<void> _toggleMed(int medId, String slot, bool taken) async {
    await _meds.setTaken(medId, _today, slot, taken);
    if (!mounted) return;
    setState(() {
      final key = '$medId|$slot';
      taken ? _taken.add(key) : _taken.remove(key);
    });
  }

  Future<void> _toggleHabit(Habit h) async {
    final done = await _habits.toggle(h.id!, _today);
    final streak = computeStreak(await _habits.daysFor(h.id!), DateTime.now());
    if (!mounted) return;
    setState(() {
      done ? _doneHabits.add(h.id!) : _doneHabits.remove(h.id!);
      _streaks[h.id!] = streak;
    });
  }

  Future<void> _quickExpense() async {
    final added = await showQuickExpenseSheet(context);
    if (added == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('اليوم', 'Today')),
        actions: [searchAction(context)],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _header(context),
          const SizedBox(height: 12),
          _heroAndSummary(context),
          const SizedBox(height: 12),
          _quickActions(context),
          const SizedBox(height: 12),
          if (_weeklyDue) ...[
            _weeklyBanner(context),
            const SizedBox(height: 12),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _waterCard(context)),
              const SizedBox(width: 12),
              Expanded(child: _sleepCard(context)),
              if (_steps != null) ...[
                const SizedBox(width: 12),
                Expanded(child: _stepsCard(context)),
              ],
              ],
            ),
          ),
          if (_hasFitnessData) ...[
            SectionHeader(tr('من ساعتك الذكية', 'From your smartwatch')),
            _fitnessSection(context),
          ],
          if (_dueBills.isNotEmpty) ...[
            SectionHeader(tr('فواتير مستحقة', 'Bills due')),
            _dueBillsCard(context),
          ],
          if (_expiring.isNotEmpty) ...[
            SectionHeader(tr('مستندات محتاجة تجديد', 'Documents to renew')),
            _expiringCard(context),
          ],
          SectionHeader(tr("مواعيد النهارده", "Today's appointments"),
              trailing: _seeAll(1)),
          if (_todayAppts.isEmpty)
            EmptyHint(
                icon: Icons.event_available,
                text: tr('مفيش مواعيد النهارده', 'No appointments today'))
          else
            ..._todayAppts.map((a) => _apptTile(context, a)),
          SectionHeader(tr("أدوية النهارده", "Today's medications")),
          if (_activeMeds.isEmpty)
            EmptyHint(
                icon: Icons.medication_outlined,
                text: tr('مفيش أدوية متسجلة — ضيفها من تبويب الجدول',
                    'No medications — add them from the Schedule tab'))
          else
            ..._medTiles(context),
          SectionHeader(tr('التمرين', 'Workout'),
              trailing: TextButton(
                  onPressed: _openWorkoutPlan,
                  child: Text(tr('الخطة', 'Plan')))),
          _workoutCard(context),
          SectionHeader(tr("وجبات النهارده", "Today's meals"),
              trailing: _mealsActions(context)),
          if (_meals.isEmpty)
            EmptyHint(
                icon: Icons.restaurant_outlined,
                text: tr("لسه ماسجلتش وجبات النهارده",
                    "No meals logged today yet"))
          else
            ..._meals.map((m) => _mealTile(context, m)),
          if (_showNutrition) _nutritionCard(context),
          SectionHeader(tr("عادات النهارده", "Today's habits"),
              trailing: _seeAll(3)),
          if (_habitList.isEmpty)
            EmptyHint(
                icon: Icons.task_alt,
                text: tr('لسه مفيش عادات — ابدأ بعادة واحدة بسيطة',
                    'No habits yet — start with one simple habit'))
          else
            _habitChips(context),
          SectionHeader(tr("فلوس النهارده", "Today's money"),
              trailing: _seeAll(2)),
          _moneyCard(context),
        ],
      ),
    );
  }

  Widget _seeAll(int tab) => TextButton(
      onPressed: () => widget.onGoToTab?.call(tab),
      child: Text(tr('الكل', 'All')));

  /// شريط بحث بارز (زي طارة) — بيفتح البحث الشامل الحي.
  /// بانر وضع «يوم صعب» — بيهدّي بدل الضغط.
  Widget _hardDayBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.spa_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  tr('وضع يوم صعب شغّال — خد يومك براحتك، مفيش ضغط النهارده 🌿',
                      "Hard-day mode on — take it easy, no pressure today 🌿"),
                  style: TextStyle(color: scheme.onSecondaryContainer)),
            ),
          ],
        ),
      ),
    );
  }

  /// كارت الصلاة + ملخص المدير — جنب بعض على الشاشات العريضة، فوق بعض على الضيقة.
  Widget _heroAndSummary(BuildContext context) {
    if (_hardDay) {
      return Column(
        children: [_hardDayBanner(context), _summaryCard(context)],
      );
    }
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth >= 640) {
          // نفس الحجم بالظبط: ارتفاع ثابت + stretch.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 250,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _prayerHeroCard(context, fill: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _summaryCard(context)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            _prayerHeroCard(context),
            _summaryCard(context),
          ],
        );
      },
    );
  }

  /// بطاقة «دلوقتي» — أقرب حاجة جاية (موعد/صلاة) + العد التنازلي.
  /// كارت الصلاة الرئيسي (البطل) — خلفية ليلية متدرجة + هلال + عدّاد تنازلي حي.
  Widget _prayerHeroCard(BuildContext context, {bool fill = false}) {
    final now = DateTime.now();
    final p = _prayers;
    if (p == null) return _nowCard(context);
    final idx = p.nextIndex(now);
    if (idx == null) return _nowCard(context);
    final when = p.times[idx];
    final name = prayerNameLabel(idx);
    // نسبة التقدّم بين الصلاة اللي فاتت والجاية (للشريط).
    final prevT =
        idx > 0 ? p.times[idx - 1] : when.subtract(const Duration(hours: 6));
    final total = when.difference(prevT).inSeconds;
    final elapsed = now.difference(prevT).inSeconds;
    final frac = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: fill ? 0 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: fill ? double.infinity : 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C4677), Color(0xFF1A2942), Color(0xFF0C1423)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 18,
                left: 22,
                child: Icon(Icons.nightlight_round,
                    color: Color(0xFFF3D06E), size: 34),
              ),
              Positioned(
                bottom: -10,
                left: -8,
                child: Icon(Icons.mosque,
                    size: 104, color: Colors.white.withValues(alpha: 0.06)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('المتبقي على', 'Time until'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13)),
                        Text(tr('صلاة $name', '$name prayer'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        _CountdownText(
                          target: when,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 5,
                            width: 210,
                            color: Colors.white.withValues(alpha: 0.18),
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: frac,
                              child: const ColoredBox(
                                  color: Color(0xFF2FDE9B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // مواعيد الصلاة جوّه الكارت (أسفله) — الصلاة الجاية مميّزة.
                    Row(
                      children: [
                        for (var i = 0; i < kPrayerNames.length; i++)
                          Expanded(
                            child: Column(
                              children: [
                                Text(prayerNameLabel(i),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: i == idx
                                            ? const Color(0xFF2FDE9B)
                                            : Colors.white
                                                .withValues(alpha: 0.65),
                                        fontSize: 10.5,
                                        fontWeight: i == idx
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                                const SizedBox(height: 2),
                                Text(arTime(p.times[i]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: i == idx
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.7),
                                        fontSize: 11,
                                        fontWeight: i == idx
                                            ? FontWeight.w700
                                            : FontWeight.w500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nowCard(BuildContext context) {
    final now = DateTime.now();
    ({DateTime when, IconData icon, String label})? best;
    void consider(DateTime w, IconData i, String l) {
      if (w.isAfter(now) && (best == null || w.isBefore(best!.when))) {
        best = (when: w, icon: i, label: l);
      }
    }

    for (final a in _todayAppts) {
      if (!a.done && a.when.isAfter(now)) {
        consider(a.when, Icons.event, tr('موعد: ${a.title}', a.title));
      }
    }
    if (_prayers != null) {
      final idx = _prayers!.nextIndex(now);
      if (idx != null) {
        consider(_prayers!.times[idx], Icons.access_time_filled,
            tr('صلاة ${prayerNameLabel(idx)}', '${prayerNameLabel(idx)} prayer'));
      }
    }
    if (best == null) return const SizedBox.shrink();
    final b = best!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(b.icon, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('اللي جاي دلوقتي', 'Up next'),
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.7))),
                  Text(b.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(arTime(b.when),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer)),
                Text(_humanDuration(b.when.difference(now)),
                    style: TextStyle(
                        fontSize: 11, color: scheme.onPrimaryContainer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _humanDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (d.inMinutes < 1) return tr('دلوقتي', 'now');
    if (h == 0) return tr('بعد ${arNum(m)} د', 'in ${arNum(m)}m');
    if (m == 0) return tr('بعد ${arNum(h)} ساعة', 'in ${arNum(h)}h');
    return tr('بعد ${arNum(h)}س و${arNum(m)}د', 'in ${arNum(h)}h ${arNum(m)}m');
  }

  /// لوحة تشغيل سريعة — تايلز ملوّنة في كارت واحد (زي الموكاب).
  Widget _quickActions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Future<void> reloadAfter(Future<void> Function() f) async {
      await f();
      if (mounted) await _load();
    }

    Widget tile(IconData icon, String label, Color color, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SizedBox(
              width: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurface)),
                ],
              ),
            ),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              tile(Icons.medication_outlined, tr('الصيدلية', 'Pharmacy'),
                  Colors.purple,
                  () => reloadAfter(() => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PharmacyScreen())))),
              tile(Icons.calendar_month_outlined, tr('التقويم', 'Calendar'),
                  Colors.teal,
                  () => reloadAfter(() => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen())))),
              tile(Icons.event_available_outlined, tr('موعد', 'Appointment'),
                  Colors.blue,
                  () => reloadAfter(() => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AppointmentForm())))),
              tile(Icons.mic_none, tr('بصوتك', 'Voice'), scheme.primary,
                  () => reloadAfter(_openVoice)),
              tile(Icons.restaurant_outlined, tr('وجبة', 'Meal'),
                  Colors.orange, () => reloadAfter(() => showMealSheet(context))),
              tile(Icons.account_balance_wallet_outlined,
                  tr('مصروف', 'Expense'), Colors.redAccent,
                  () => reloadAfter(() => showQuickExpenseSheet(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _name.isEmpty
              ? greetingFor(now)
              : tr('${greetingFor(now)} يا $_name',
                  '${greetingFor(now)}, $_name'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800, color: scheme.primary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: scheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${arFullDate(now)} — ${_hijriLine(now)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.outline)),
            ),
          ],
        ),
      ],
    );
  }

  String _hijriLine(DateTime now) {
    HijriCalendar.setLocal(AppState.isEnglish ? 'en' : 'ar');
    final h = HijriCalendar.fromDate(now);
    return tr('${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)}هـ',
        '${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)} AH');
  }

  Widget _summaryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      // لمسة زجاجية: تدرّج شفاف خفيف + حدّ مضيء رفيع.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primaryContainer.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('ملخص مديرك لليوم', "Your manager's brief"),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_summaryText(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onPrimaryContainer)),
                const SizedBox(height: 8),
                ActionChip(
                  avatar: Icon(Icons.route_outlined,
                      size: 18, color: scheme.primary),
                  label: Text(tr('رتبلي باقي اليوم', 'Plan the rest of my day')),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DayPlanScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.event_repeat, color: scheme.onSecondaryContainer),
        title: Text(tr('وقت التخطيط الأسبوعي', 'Weekly planning time'),
            style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600)),
        subtitle: Text(
            tr('١٠ دقايق تراجع أسبوعك وتجهز الجاي',
                '10 minutes to review your week and plan ahead'),
            style: TextStyle(color: scheme.onSecondaryContainer)),
        trailing: Icon(Icons.chevron_left, color: scheme.onSecondaryContainer),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WeeklyPlanningScreen()));
          if (mounted) await _load();
        },
      ),
    );
  }

  Widget _waterCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frac = _waterGoal > 0 ? _water / _waterGoal : 0.0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      _ramadan
                          ? tr('مياه (فطار→سحور)', 'Water (iftar→suhoor)')
                          : tr('المياه', 'Water'),
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${arNum(_water)} / ${arNum(_waterGoal)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Row(
                        children: [
                          _roundBtn(Icons.remove, scheme,
                              _water == 0 ? null : () => _changeWater(-1)),
                          const SizedBox(width: 8),
                          _roundBtn(Icons.add, scheme, () => _changeWater(1),
                              filled: true),
                        ],
                      ),
                    ],
                  ),
                ),
                WaterGlass(fraction: frac),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, ColorScheme scheme, VoidCallback? onTap,
      {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          border: filled ? null : Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null
                ? scheme.outline.withValues(alpha: 0.4)
                : (filled ? scheme.onPrimary : scheme.onSurface)),
      ),
    );
  }

  Widget _sleepCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showChips = _sleep == null || _editingSleep;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bedtime_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(tr('نوم امبارح', 'Last night')),
              ],
            ),
            const SizedBox(height: 4),
            if (showChips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var h = 1; h <= 24; h++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ActionChip(
                          label: Text(arNum(h)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _setSleep(h.toDouble()),
                        ),
                      ),
                  ],
                ),
              )
            else ...[
              Text(
                  tr('${arNum(_sleep! == _sleep!.roundToDouble() ? _sleep!.toInt() : _sleep!)} ساعات',
                      '${arNum(_sleep! == _sleep!.roundToDouble() ? _sleep!.toInt() : _sleep!)} hours'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(
                  onPressed: () => setState(() => _editingSleep = true),
                  child: Text(tr('تعديل', 'Edit'))),
            ],
            const SizedBox(height: 2),
            SleepWave(color: scheme.primary),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(tr('ساعات', 'hours'),
                  style: TextStyle(fontSize: 11, color: scheme.outline)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWorkoutPlan() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()));
    if (mounted) await _load();
  }

  Widget _workoutCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayWorkout = _workoutPlan[DateTime.now().weekday];
    if (todayWorkout != null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.fitness_center,
              color: _workoutDone ? scheme.primary : scheme.outline),
          title: Text(todayWorkout),
          subtitle: Text(_workoutDone
              ? tr('اتعمل — عاش!', 'Done — nice!')
              : tr('لسه ماتعملش', 'Not done yet')),
          trailing: FilledButton.tonal(
            onPressed: () async {
              await WorkoutRepo().setDone(_today, !_workoutDone,
                  title: todayWorkout);
              if (mounted) await _load();
            },
            child: Text(_workoutDone ? tr('اتعمل ✓', 'Done ✓') : tr('تم؟', 'Done?')),
          ),
        ),
      );
    }
    if (_missedWorkout != null) {
      return Card(
        margin: EdgeInsets.zero,
        color: scheme.tertiaryContainer,
        child: ListTile(
          leading: Icon(Icons.fitness_center,
              color: scheme.onTertiaryContainer),
          title: Text(
              tr('تمرين امبارح ($_missedWorkout) فاتك',
                  "Yesterday's workout ($_missedWorkout) was missed"),
              style: TextStyle(color: scheme.onTertiaryContainer)),
          trailing: FilledButton.tonal(
            onPressed: () async {
              await WorkoutRepo()
                  .setDone(_today, true, title: _missedWorkout!);
              if (mounted) await _load();
            },
            child: Text(tr('اعمله النهارده', 'Do it today')),
          ),
        ),
      );
    }
    if (_workoutPlan.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.fitness_center, color: scheme.outline),
          title: Text(tr('لسه مفيش خطة تمرين', 'No workout plan yet')),
          trailing: TextButton(
              onPressed: _openWorkoutPlan, child: Text(tr('حددها', 'Set it'))),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.self_improvement, color: scheme.outline),
        title: Text(tr('النهارده راحة', 'Rest day today')),
      ),
    );
  }

  Widget _mealsActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShoppingListScreen()));
          },
          tooltip: tr('قائمة التسوق', 'Shopping list'),
          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
        ),
        TextButton(
          onPressed: () async {
            final added = await showMealSheet(context);
            if (added == true && mounted) await _load();
          },
          child: Text(tr('سجل وجبة', 'Log meal')),
        ),
      ],
    );
  }

  int get _eatenCalories =>
      _meals.fold<double>(0, (s, m) => s + (m.calories ?? 0)).round();

  bool get _showNutrition =>
      _calorieGoal > 0 ||
      _calories != null ||
      _meals.any((m) => m.calories != null);

  Widget _nutritionCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eaten = _eatenCalories;
    final burned = _calories ?? 0;
    final net = eaten - burned;
    final remaining = _calorieGoal > 0 ? _calorieGoal + burned - eaten : null;

    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.outline)),
              const SizedBox(height: 2),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.balance, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tr('الميزان الغذائي', 'Nutrition balance'),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                    onPressed: _editCalorieGoal,
                    child: Text(_calorieGoal > 0
                        ? tr('هدف: ${arNum(_calorieGoal)}', 'Goal: ${arNum(_calorieGoal)}')
                        : tr('حدد هدف', 'Set goal'))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                cell(tr('أكلت 🍽', 'Eaten 🍽'), arNum(eaten), scheme.primary),
                cell(tr('حرقت 🔥', 'Burned 🔥'), arNum(burned),
                    Colors.deepOrange),
                cell(tr('الصافي', 'Net'), arNum(net),
                    net >= 0 ? scheme.onSurface : Colors.green),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: 8),
              Text(
                  remaining >= 0
                      ? tr('متبقّي من هدفك: ${arNum(remaining)} سعرة',
                          '${arNum(remaining)} kcal left of your goal')
                      : tr('عدّيت هدفك بـ ${arNum(-remaining)} سعرة',
                          '${arNum(-remaining)} kcal over your goal'),
                  style: TextStyle(
                      fontSize: 12,
                      color: remaining >= 0 ? Colors.green : scheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editCalorieGoal() async {
    final controller = TextEditingController(
        text: _calorieGoal > 0 ? _calorieGoal.toString() : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('هدف السعرات اليومي', 'Daily calorie goal')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: tr('السعرات (مثلًا: 2000)', 'Calories (e.g. 2000)'),
              helperText: tr('سيبه فاضي عشان تلغي الهدف',
                  'Leave empty to clear the goal')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    if (saved == true) {
      final value = int.tryParse(controller.text.trim());
      await _settings.set(
          'calorie_goal', value == null || value <= 0 ? '' : '$value');
      if (mounted) await _load();
    }
    controller.dispose();
  }

  Widget _mealTile(BuildContext context, Meal m) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(mealSlotLabel(m.slot),
              style: TextStyle(
                  color: scheme.onSecondaryContainer, fontSize: 12)),
        ),
        title: Text(m.description),
        subtitle: m.calories == null
            ? null
            : Text(tr('${arNum(m.calories!.toInt())} سعرة تقريبًا',
                '~${arNum(m.calories!.toInt())} kcal')),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: tr('حذف', 'Delete'),
          onPressed: () async {
            await MealsRepo().delete(m.id!);
            if (mounted) await _load();
          },
        ),
      ),
    );
  }

  Widget _stepsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_walk, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(tr('الخطوات', 'Steps')),
              ],
            ),
            const SizedBox(height: 4),
            Text(arNum(_steps ?? 0),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Text(tr('تلقائي', 'Auto'),
                  style: TextStyle(fontSize: 11, color: scheme.outline)),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasFitnessData =>
      _calories != null || _restingHr != null || _distanceKm != null;

  Widget _fitnessSection(BuildContext context) {
    final cards = <Widget>[
      if (_calories != null)
        _fitnessMetricCard(
          context,
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
          value: arNum(_calories!),
          label: tr('سعرة محروقة', 'calories burned'),
        ),
      if (_restingHr != null)
        _fitnessMetricCard(
          context,
          icon: Icons.favorite,
          color: Colors.redAccent,
          value: arNum(_restingHr!),
          label: tr('نبضة/دقيقة', 'bpm'),
        ),
      if (_distanceKm != null)
        _fitnessMetricCard(
          context,
          icon: Icons.straighten,
          color: Colors.teal,
          value: arNum(_distanceKm!.toStringAsFixed(_distanceKm! >= 10 ? 0 : 1)),
          label: tr('كيلومتر', 'km'),
        ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: cards);
  }

  Widget _fitnessMetricCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 32 - 20) / 3,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: scheme.outline)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dueBillsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            for (final b in _dueBills)
              ListTile(
                dense: true,
                leading: Icon(Icons.receipt_long_outlined,
                    color: scheme.onTertiaryContainer),
                title: Text(b.name,
                    style: TextStyle(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(egp(b.amount),
                    style:
                        TextStyle(color: scheme.onTertiaryContainer)),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    await BillsRepo().markPaid(b.id!);
                    if (mounted) await _load();
                  },
                  child: Text(tr('اتدفعت ✓', 'Paid ✓')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _expiringCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final d in _expiring)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d.title,
                          style: TextStyle(color: scheme.onTertiaryContainer)),
                    ),
                    Text(
                      _expiryLabel(today, DateTime.parse(d.expiry!)),
                      style: TextStyle(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _expiryLabel(DateTime today, DateTime expiry) {
    final days = dateOnly(expiry).difference(today).inDays;
    if (days < 0) return tr('منتهي', 'Expired');
    if (days == 0) return tr('ينتهي النهارده', 'Expires today');
    return tr('باقي ${arNum(days)} يوم', '${arNum(days)} days left');
  }

  Widget _apptTile(BuildContext context, Appointment a) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.event, color: scheme.onSecondaryContainer),
        ),
        title: Text(a.title),
        subtitle: Text('${arTime(a.when)} • ${apptCategoryLabel(a.category)}'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          tooltip: tr('تم', 'Done'),
          onPressed: () async {
            await _appts.setDone(a.id!, true);
            if (mounted) await _load();
          },
        ),
      ),
    );
  }

  List<Widget> _medTiles(BuildContext context) {
    final tiles = <Widget>[];
    for (final m in _activeMeds) {
      for (final slot in m.times) {
        final key = '${m.id}|$slot';
        tiles.add(Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: CheckboxListTile(
            value: _taken.contains(key),
            onChanged: (v) => _toggleMed(m.id!, slot, v ?? false),
            title: Text(m.name),
            subtitle: Text(
                '${arTimeOfSlot(slot)}${m.dosage.isEmpty ? '' : ' • ${m.dosage}'}'),
          ),
        ));
      }
    }
    return tiles;
  }

  Widget _habitChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final h in _habitList)
          FilterChip(
            selected: _doneHabits.contains(h.id),
            onSelected: (_) => _toggleHabit(h),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(h.name),
                if ((_streaks[h.id] ?? 0) > 0) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.local_fire_department,
                      size: 16, color: Colors.deepOrange),
                  Text(arNum(_streaks[h.id]!)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _moneyCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr("مصاريف النهارده", "Today's spending"),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                  Text(egp(_todaySpend),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _quickExpense,
              icon: const Icon(Icons.add),
              label: Text(tr('سجل مصروف', 'Log expense')),
            ),
          ],
        ),
      ),
    );
  }
}

/// عدّاد تنازلي حي (HH:MM:SS) بيتحدّث كل ثانية — widget مستقل عشان يعيد بناء
/// النص بس مش الشاشة كلها.
class _CountdownText extends StatefulWidget {
  final DateTime target;
  final TextStyle? style;

  const _CountdownText({required this.target, this.style});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var diff = widget.target.difference(DateTime.now());
    if (diff.isNegative) diff = Duration.zero;
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return Text(arNum('$h:$m:$s'), style: widget.style);
  }
}
