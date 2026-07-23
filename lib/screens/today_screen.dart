import 'dart:async';
import '../core/log.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/home_layout.dart';
import '../core/health_service.dart';
import '../core/attention.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../core/water_guard.dart';
import '../core/widget_bridge.dart';
import '../data/appointments_repo.dart';
import '../data/tasks_repo.dart';
import '../data/bills_repo.dart';
import '../data/debts_repo.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/inbox_repo.dart';
import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/meds_repo.dart';
import '../data/settings_repo.dart';
import '../data/wallets_repo.dart';
import '../data/workout_repo.dart';
import '../models/models.dart';
import '../widgets/decorations.dart';
import 'alerts_center_screen.dart';
import 'brain/chat_screen.dart';
import '../core/dashboard_stats.dart';
import '../core/morning_brief.dart';
import '../widgets/dash_card.dart';
import 'dashboard_screen.dart';
import 'emergency_view.dart';
import 'health/health_hub_screen.dart';
import 'food/food_card_screen.dart';
import 'gym/gym_screen.dart';

import 'money/money_screen.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';
import 'food/meal_sheet.dart';
import 'calendar_screen.dart';
import 'docs/doc_form.dart';
import 'home/pharmacy_screen.dart';
import 'quick_actions_settings_screen.dart';
import 'money/income_sheet.dart';
import 'money/quick_expense_sheet.dart';
import '../widgets/search_action.dart';
import 'schedule/appointment_form.dart';
import 'voice/voice_sheet.dart';
import 'worship/prayer_screen.dart';
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
  final _habits = HabitsRepo();

  bool _loading = true;
  bool _editingSleep = false;
  String _name = '';

  /// ترتيب/تفعيل أزرار الإضافة السريعة (قابل للتخصيص).
  List<String> _quickOrder = kDefaultQuickActions;

  /// مزامنة الخطوات التلقائية شغّالة؟ (عشان نخفي زرار الخطوات اليدوي).
  bool _stepsAuto = false;

  int _waterGoal = 8;
  int _water = 0;
  // المياه بالملى (الدقيقة) — الحلقة بتفضل بالأكواب المضغوطة، والشيت بالملى.
  int _waterMl = 0;
  int _waterGoalMl = 2000;
  double? _sleep;
  List<Appointment> _todayAppts = [];

  /// عدد المهام المستحقة — لبادج زرار «المهام».
  int _dueTasks = 0;

  /// كروت الأقسام بأرقامها الحية.
  List<DashStat> _dash = [];

  /// حالة «قفل اليوم» — بتتجمّع مساءً بس (بعد ٦م).

  /// اختصارات صف الإجراءات (٤) — من اختيار المستخدم، محفوظة فى الإعدادات.
  List<String> _shortcutKeys = _defaultShortcuts;
  List<Medication> _activeMeds = [];
  Set<String> _taken = {};
  int? _steps;
  int? _calories;
  int? _restingHr;
  double? _distanceKm;
  List<AttentionItem> _attention = [];


  /// كروت الرئيسية اللى المستخدم اختارها (فاضى = الكل).
  String? _homeCards;

  bool _ramadan = false;

  String get _today => dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // قياس زمن فتح الرئيسية — بيتسجّل فى اللوج لمتابعة الأداء.
    final sw = Stopwatch()..start();
    final now = DateTime.now();
    final day = dayKey(now);
    final name = await _settings.userName();
    final savedQuick = await _settings.get('quick_actions');
    final quickOrder = (savedQuick == null || savedQuick.trim().isEmpty)
        ? kDefaultQuickActions
        : savedQuick.split(',').where((e) => e.isNotEmpty).toList();
    final stepsAuto = await _settings.healthSyncEnabled();
    final goal = await _settings.waterGoal();
    final water = await _health.waterOn(day);
    final waterMl = await _health.waterMlOn(day);
    final waterGoalMl = await _settings.waterGoalMl();
    final sleep = await _health.sleepOn(day);
    // مزامنة Health Connect (قنوات نظام بطيئة) اتأجلت لبعد أول رسمة —
    // بتحدّث الخطوات/السعرات/النوم بـsetState خاص بيها لما توصل.
    final appts = await _appts.forDay(now);
    final meds = await _meds.all(activeOnly: true);
    final taken = await _meds.takenOn(day);
    final habits = await _habits.active();
    final streaks = <int, int>{};
    for (final h in habits) {
      streaks[h.id!] = computeStreak(await _habits.daysFor(h.id!), now);
    }
    // بانر التخطيط الأسبوعي يظهر من الجمعة للأحد لو أسبوع ده لسه مااتخططش.
    final ramadan = await _settings.ramadanMode();
    // «محتاج منك دلوقتي» + عدد الصلوات (لحلقات «يومك فى سطر»).
    final attention = await collectAttention(now);
    final dueTasks = (await TasksRepo().dueTasks(now)).length;
    final dash = await collectDashboard(now);
    final shortcutsRaw = await SettingsRepo().get('home_shortcuts') ?? '';
    // «قفل اليوم» بيظهر مساءً بس — مانحمّلوش الصبح.
    final homeCards = await _settings.get(kHomeCardsSetting);
    if (!mounted) return;
    setState(() {
      _attention = attention;
      _dueTasks = dueTasks;
      _dash = dash;
      final sc = shortcutsRaw.split(',').where((e) => e.isNotEmpty).toList();
      _shortcutKeys = sc.isEmpty ? _defaultShortcuts : sc;
      _homeCards = homeCards;
      _name = name;
      _quickOrder = quickOrder;
      _stepsAuto = stepsAuto;
      _waterGoal = goal;
      _water = water;
      _waterMl = waterMl;
      _waterGoalMl = waterGoalMl;
      _sleep = sleep;
      _todayAppts = appts;
      _activeMeds = meds;
      _taken = taken;
      _ramadan = ramadan;
      _editingSleep = false;
      _loading = false;
    });
    sw.stop();
    logInfo('فتح الرئيسية: ${sw.elapsedMilliseconds}ms');
    unawaited(WidgetBridge.push());
    // مزامنة الصحة بعد أول رسمة — أبطأ جزء فى التحميل القديم.
    if (stepsAuto) unawaited(_syncHealth(day, now));
  }

  /// مزامنة Health Connect (خطوات/سعرات/نبض/مسافة/نوم/تمرين) — بتشتغل بعد
  /// ما الشاشة تترسم عشان قنوات النظام البطيئة ماتعطّلش فتح الرئيسية.
  Future<void> _syncHealth(String day, DateTime now) async {
    try {
      final steps = await HealthService.stepsToday();
      // بنخزن الخطوات يوميًا عشان الرؤى وتقرير الدكتور.
      if (steps != null && steps > 0) {
        await MeasurementsRepo().upsertSteps(day, steps);
      }
      // مقاييس الساعة الذكية (كلها best-effort — أي واحدة مش متاحة ترجع null).
      final calories = await HealthService.activeCaloriesToday();
      final restingHr = await HealthService.restingHeartRate();
      final distanceKm = await HealthService.distanceTodayKm();
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
      double? autoSleep;
      if (_sleep == null) {
        // النوم بييجي تلقائيًا من Health Connect لو مفيش تسجيل يدوي.
        autoSleep = await HealthService.lastNightSleepHours();
        if (autoSleep != null) await _health.setSleep(day, autoSleep);
      }
      if (!mounted) return;
      setState(() {
        _steps = steps ?? _steps;
        _calories = calories ?? _calories;
        _restingHr = restingHr ?? _restingHr;
        _distanceKm = distanceKm ?? _distanceKm;
        if (autoSleep != null) _sleep = autoSleep;
      });
    } on Exception catch (e, st) {
      logError('فشل مزامنة الصحة', e, st);
    }
  }

  Future<void> _changeWater(int delta) async {
    HapticFeedback.selectionClick();
    final next = await _health.addWater(_today, delta);
    if (mounted) setState(() => _water = next);
    unawaited(WidgetBridge.push());
    unawaited(WaterGuard.ensureScheduled());
  }

  /// يزود/يقلل المياه بالملى ويحدّث الحالة (المصدر الأساسى دلوقتى).
  Future<void> _changeWaterMl(int deltaMl) async {
    HapticFeedback.selectionClick();
    final next = await _health.addWaterMl(_today, deltaMl);
    if (mounted) {
      setState(() {
        _waterMl = next;
        _water = (next / 250).round();
      });
    }
    unawaited(WidgetBridge.push());
    unawaited(WaterGuard.ensureScheduled());
  }

  Future<void> _setWaterMl(int ml) async {
    final next = await _health.setWaterMl(_today, ml);
    if (mounted) {
      setState(() {
        _waterMl = next;
        _water = (next / 250).round();
      });
    }
    unawaited(WidgetBridge.push());
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
    HapticFeedback.selectionClick();
    await _meds.setTaken(medId, _today, slot, taken);
    if (!mounted) return;
    setState(() {
      final key = '$medId|$slot';
      taken ? _taken.add(key) : _taken.remove(key);
    });
  }

  /// جرس «مركز التنبيهات» جنب البحث — بيفتح شاشة التنبيهات وعليه عدّاد
  /// باللى محتاج منك دلوقتى.
  ///
  /// ده كمان بيسدّ ثغرة: الرئيسية الجديدة مفيهاش شريط «محتاج منك دلوقتي»،
  /// فالجرس بقى الطريق المضمون لأى حاجة متأخرة من غير ما يزحم الشاشة.
  Widget _alertsAction(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = _attention.length;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: tr('التنبيهات', 'Alerts'),
          // أصفر ثابت مش من الثيم: الجرس لازم يشدّ العين فى الوضعين
          // (فاتح وغامق)، والكهرماني ده مقروء على الاتنين.
          color: const Color(0xFFFFC107),
          icon: Icon(n > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none),
          onPressed: () => _reloadAfter(() => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsCenterScreen()),
              )),
        ),
        if (n > 0)
          PositionedDirectional(
            top: 8,
            end: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  // فوق ٩ بيبقى «٩+» — العدّاد بيوسّع الأيقونة ويكسر الصف.
                  n > 9 ? tr('٩+', '9+') : arNum(n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('الرئيسية', 'Home')),
        actions: [_alertsAction(context), searchAction(context)],
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

  // الرئيسية بقت شكل واحد («على مزاجك») — الأشكال التانية اتلغت.
  Widget _body(BuildContext context) => _bodyCustom(context);

  /// ٩) «على مزاجك» — الرئيسية اللى المستخدم بيبنيها بنفسه:
  /// ترحيب وتاريخ · إجراءات سريعة يختارها · كروت يختارها، وكل كارت
  /// بيفتح صفحته. الاتنين فيهم ＋ بيعدّل الاختيار من الرئيسية على طول.
  Widget _bodyCustom(BuildContext context) {
    final chosen = selectedHomeCards(
        _dash.map((d) => d.key).toList(), _homeCards);
    final cards = [
      for (final k in chosen)
        ..._dash.where((d) => d.key == k),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // الترحيب هنا بالمظهر العادى عن قصد (اختيار المستخدم) — التدرّج
          // بيفضل للأشكال التانية.
          _header(context),
          const SizedBox(height: 16),
          _customSectionHeader(
            context,
            tr('إجراءات سريعة', 'Quick actions'),
            onAdd: _editQuickActions,
          ),
          const SizedBox(height: 8),
          _quickActions(context),
          const SizedBox(height: 18),
          _customSectionHeader(
            context,
            tr('كروتك', 'Your cards'),
            onAdd: _editHomeCards,
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            _emptyCardsHint(context)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              // طول ثابت بدل childAspectRatio: على شاشة واسعة (تابلت) الـ٣
              // كروت بيبقوا عريضين، والنسبة بتضرب الطول فى العرض الكبير ده
              // فيطلعوا ضخام وفاضيين من جوه. mainAxisExtent بيثبّت الطول
              // مهما اتّسعت الشاشة.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 124,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) => DashCardTile(
                stat: cards[i],
                onOpen: (screen) => _reloadAfter(() => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => screen))),
              ),
            ),
        ],
      ),
    );
  }

  /// عنوان قسم فى «على مزاجك» + زرار ＋ للتعديل.
  Widget _customSectionHeader(BuildContext context, String title,
      {required VoidCallback onAdd}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const Spacer(),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          tooltip: tr('اختار اللى تحبه', 'Pick what you want'),
          icon: const Icon(Icons.add, size: 20),
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _emptyCardsHint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
        children: [
          const Text('🗂', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('دوس ＋ واختار الكروت اللى تحب تشوفها هنا.',
                  'Tap ＋ and pick the cards you want here.'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// ＋ الإجراءات السريعة — بيفتح نفس شاشة التخصيص الموجودة (اختيار +
  /// ترتيب بالسحب) بدل ما نبنى واحدة تانية.
  Future<void> _editQuickActions() async {
    final all = [
      for (final a in quickActionCatalog())
        (key: a.key, icon: a.icon, label: a.label),
    ];
    final picked = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuickActionsSettingsScreen(
            all: all, enabledOrder: _quickOrder),
      ),
    );
    if (picked == null) return;
    await _settings.set('quick_actions', picked.join(','));
    if (mounted) await _load();
  }

  /// ＋ الكروت — اختيار أى كروت تظهر فى الرئيسية.
  Future<void> _editHomeCards() async {
    final all = _dash.map((d) => (key: d.key, title: d.title)).toList();
    final current = selectedHomeCards(
        all.map((e) => e.key).toList(), _homeCards).toSet();
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _HomeCardsPicker(all: all, selected: current),
    );
    if (picked == null) return;
    // ترتيب الاختيار بيتبع الترتيب الطبيعى للكروت — أبسط وأثبت من ترتيب
    // بيتغيّر حسب أنهى واحد المستخدم دوس عليه الأول.
    final ordered =
        all.map((e) => e.key).where(picked.contains).toList();
    await _settings.set(kHomeCardsSetting, ordered.join(','));
    if (mounted) await _load();
  }

  /// لوحة تشغيل سريعة — تايلز ملوّنة في كارت واحد (زي الموكاب).
  // ---- إجراءات سريعة فورية ----

  Future<void> _quickInbox() async {
    final ctrl = TextEditingController();
    final now = DateTime.now();
    final times = <({String label, DateTime? at})>[
      (label: tr('بدون', 'None'), at: null),
      (label: tr('بعد ساعة', 'in 1h'), at: now.add(const Duration(hours: 1))),
      (label: tr('بعد ساعتين', 'in 2h'), at: now.add(const Duration(hours: 2))),
      (label: tr('بكرة ٩ص', 'Tmrw 9am'), at: DateTime(now.year, now.month, now.day + 1, 9)),
      (label: tr('الليلة ٩م', 'Tonight 9pm'), at: DateTime(now.year, now.month, now.day, 21)),
    ];
    var sel = 0;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 4, bottom: _sheetBottom(ctx)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.push_pin_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('تذكير سريع', 'Quick reminder'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                      hintText: tr('اكتب اللي عايز تفتكره...', 'What to remember...')),
                ),
                const SizedBox(height: 12),
                Text(tr('نبّهني:', 'Remind me:'), style: TextStyle(color: scheme.outline)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < times.length; i++)
                      ChoiceChip(
                          label: Text(times[i].label),
                          selected: sel == i,
                          onSelected: (_) => setSheet(() => sel = i)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('حفظ', 'Save'))),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final text = ctrl.text.trim();
      final id = await InboxRepo().add(text);
      final when = times[sel].at;
      if (when != null && when.isAfter(DateTime.now()) && !kIsWeb) {
        await Notifications.scheduleOnce(
          id: 1100000 + (id % 100000),
          title: tr('تذكير', 'Reminder'),
          body: text,
          when: when,
        );
        _snack(tr('هفكّرك ${arTime(when)} 📌', "I'll remind you at ${arTime(when)} 📌"));
      } else {
        _snack(tr('اتحطّت في الوارد 📝', 'Saved to inbox 📝'));
      }
      if (mounted) await _load();
    }
  }

  Future<void> _quickMeasurement() async {
    var type = kMeasurementTypes.first;
    final v1 = TextEditingController();
    final v2 = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 4,
                bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.monitor_heart_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('قياس سريع', 'Quick measurement'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in kMeasurementTypes)
                      ChoiceChip(
                          label: Text(t),
                          selected: type == t,
                          onSelected: (_) => setSheet(() => type = t)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: v1,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: type == 'ضغط'
                                ? tr('الانقباضي', 'Systolic')
                                : tr('القيمة', 'Value')),
                      ),
                    ),
                    if (type == 'ضغط') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: v2,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: tr('الانبساطي', 'Diastolic')),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('حفظ', 'Save'))),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true) {
      final a = parseNumber(v1.text);
      if (a == null) return;
      await MeasurementsRepo().add(Measurement(
        day: dayKey(DateTime.now()),
        type: type,
        value: a,
        value2: type == 'ضغط' ? parseNumber(v2.text) : null,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتسجّل القياس 📏', 'Measurement saved 📏'))));
      await _load();
    }
  }

  Future<void> _reloadAfter(Future<void> Function() f) async {
    await f();
    if (mounted) await _load();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// مسافة سفلية آمنة للشبابيك (كيبورد + شريط تنقل النظام).
  double _sheetBottom(BuildContext ctx, [double base = 20]) =>
      base +
      MediaQuery.of(ctx).viewInsets.bottom +
      MediaQuery.of(ctx).viewPadding.bottom;

  /// شباك تمرين النهاردة — عنوانه + زر «اتعمل» (أو يوم راحة + تعديل الخطة).
  Future<void> _openWorkoutSheet() async {
    final now = DateTime.now();
    final repo = WorkoutRepo();
    final title = (await repo.plan())[now.weekday];
    final done = await repo.doneOn(dayKey(now));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.fitness_center, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('تمرين النهاردة', "Today's workout"),
                    style: Theme.of(ctx).textTheme.titleMedium),
              ]),
              const SizedBox(height: 16),
              if (title == null || title.isEmpty) ...[
                Text(tr('مفيش تمرين متجدول النهاردة — يوم راحة 💪',
                    'No workout today — rest day 💪')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openWorkoutPlan();
                  },
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: Text(tr('عدّل خطة التمرين', 'Edit workout plan')),
                ),
              ] else ...[
                Text(title,
                    style: Theme.of(ctx)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                if (done)
                  Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(tr('اتعمل خلاص ✅', 'Done ✅')),
                  ])
                else
                  FilledButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await repo.setDone(dayKey(now), true, title: title);
                      if (mounted) await _load();
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack(tr('علّمت التمرين ✅', 'Workout marked ✅'));
                    },
                    icon: const Icon(Icons.check),
                    label: Text(tr('علّمته اتعمل', 'Mark done')),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// شباك الخطوات — شيبس جاهزة + رقم مخصّص.
  Future<void> _openStepsSheet() async {
    final ctrl = TextEditingController();
    final day = dayKey(DateTime.now());
    Future<void> save(int steps) async {
      await MeasurementsRepo().upsertSteps(day, steps);
      if (mounted) await _load();
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.directions_walk, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('خطوات النهاردة', "Today's steps"),
                    style: Theme.of(ctx).textTheme.titleMedium),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in [2000, 4000, 6000, 8000, 10000, 12000, 15000])
                    ActionChip(
                      label: Text(arNum(s)),
                      onPressed: () async {
                        await save(s);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack(tr('اتسجّلت الخطوات 🚶', 'Steps saved 🚶'));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr('رقم مخصّص', 'Custom')),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final v = parseNumber(ctrl.text);
                    if (v == null || v <= 0) return;
                    await save(v.toInt());
                    if (ctx.mounted) Navigator.pop(ctx);
                    _snack(tr('اتسجّلت الخطوات 🚶', 'Steps saved 🚶'));
                  },
                  child: Text(tr('حفظ', 'Save')),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  /// شباك الفواتير المستحقة — تعلّم منها اللي اتدفع.
  Future<void> _openBillsSheet() async {
    final due = await BillsRepo().due(DateTime.now());
    if (due.isEmpty) {
      _snack(tr('مفيش فواتير مستحقة', 'No bills due'));
      return;
    }
    if (!mounted) return;
    final bills = List.of(due);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    Icon(Icons.receipt_long_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(tr('فواتير مستحقة', 'Bills due'),
                        style: Theme.of(ctx).textTheme.titleMedium),
                  ]),
                ),
                const SizedBox(height: 8),
                if (bills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(tr('كله اتدفع 👌', 'All paid 👌')),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final b in bills)
                            ListTile(
                              leading: const Icon(Icons.receipt_outlined),
                              title: Text(b.name),
                              subtitle: Text(egp(b.amount)),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  await BillsRepo().markPaid(b.id!);
                                  bills.remove(b);
                                  if (mounted) await _load();
                                  setSheet(() {});
                                },
                                child: Text(tr('دفعت', 'Paid')),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _quickHabit() async {
    final repo = HabitsRepo();
    final habits = await repo.active();
    if (habits.isEmpty) {
      _snack(tr('مفيش عادات مسجلة', 'No habits yet'));
      return;
    }
    final day = dayKey(DateTime.now());
    var done = await repo.doneOn(day);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 4,
                bottom: 16 +
                    MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Icon(Icons.task_alt, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(tr('علّم عاداتك', 'Mark habits'),
                        style: Theme.of(ctx).textTheme.titleMedium),
                  ]),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final h in habits)
                          CheckboxListTile(
                            value: done.contains(h.id),
                            title: Text(h.name),
                            onChanged: (_) async {
                              HapticFeedback.selectionClick();
                              await repo.toggle(h.id!, day);
                              done = await repo.doneOn(day);
                              if (mounted) await _load();
                              setSheet(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addShoppingItem() async {
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 4, bottom: _sheetBottom(ctx)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.add_shopping_cart_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('إضافة للتسوق', 'Add to shopping'),
                    style: Theme.of(ctx).textTheme.titleMedium),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(hintText: tr('الصنف...', 'Item...')),
                onSubmitted: (_) => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(tr('إضافة', 'Add'))),
              ),
            ],
          ),
        );
      },
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await MealsRepo().addShoppingItem(ctrl.text.trim());
      _snack(tr('اتضاف للتسوق 🛒', 'Added to shopping 🛒'));
    }
  }

  Future<void> _walletTransfer() async {
    final list = await WalletsRepo().allWithBalances();
    if (list.length < 2) {
      _snack(tr('محتاج محفظتين على الأقل', 'Need at least 2 wallets'));
      return;
    }
    var fromId = list.first.wallet.id!;
    var toId = list[1].wallet.id!;
    final amt = TextEditingController();
    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 4, bottom: _sheetBottom(ctx)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.swap_horiz, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('تحويل بين المحافظ', 'Transfer'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: fromId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('من', 'From')),
                  items: [
                    for (final e in list)
                      DropdownMenuItem(
                          value: e.wallet.id,
                          child: Text('${e.wallet.name} — ${egp(e.balance)}',
                              overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: (v) => setSheet(() {
                    fromId = v!;
                    if (toId == fromId) {
                      toId = list.firstWhere((e) => e.wallet.id != fromId).wallet.id!;
                    }
                  }),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: toId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('إلى', 'To')),
                  items: [
                    for (final e in list)
                      DropdownMenuItem(
                          value: e.wallet.id,
                          enabled: e.wallet.id != fromId,
                          child: Text('${e.wallet.name} — ${egp(e.balance)}',
                              overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: (v) => setSheet(() => toId = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amt,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('المبلغ', 'Amount')),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed:
                          fromId == toId ? null : () => Navigator.pop(ctx, true),
                      child: Text(tr('تحويل', 'Transfer'))),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true) {
      final a = parseNumber(amt.text);
      if (a == null || a <= 0 || fromId == toId) return;
      await WalletsRepo().transfer(fromId, toId, a);
      _snack(tr('تمّ التحويل 💳', 'Transferred 💳'));
      if (mounted) await _load();
    }
  }

  Future<void> _quickDebt() async {
    final person = TextEditingController();
    final amt = TextEditingController();
    var dir = 'لى';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 4, bottom: _sheetBottom(ctx)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.handshake_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('دَين / سلفة', 'Debt / loan'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                TextField(controller: person, decoration: InputDecoration(labelText: tr('الاسم', 'Person'))),
                const SizedBox(height: 8),
                TextField(controller: amt, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('المبلغ', 'Amount'))),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'لى', label: Text(tr('ليا', 'Owed to me'))),
                    ButtonSegment(value: 'عليا', label: Text(tr('عليا', 'I owe'))),
                  ],
                  selected: {dir},
                  onSelectionChanged: (s) => setSheet(() => dir = s.first),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('حفظ', 'Save'))),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true) {
      final a = parseNumber(amt.text);
      if (a == null || a <= 0 || person.text.trim().isEmpty) return;
      await DebtsRepo().add(Debt(
        person: person.text.trim(),
        amount: a,
        direction: dir,
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('اتسجّل 🤝', 'Saved 🤝'))));
      await _load();
    }
  }

  /// شباك المياه — كوباية + أزرار −/+ زي كارت المياه في نص الصفحة.
  Future<void> _openWaterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          final frac = _waterGoalMl > 0 ? _waterMl / _waterGoalMl : 0.0;
          String litres(int ml) => (ml / 1000).toStringAsFixed(
              ml % 1000 == 0 ? 0 : (ml % 100 == 0 ? 1 : 2));
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.water_drop_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('المياه', 'Water'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الإجمالى بالملى + الهدف باللتر بالظبط.
                          Text('${arNum(_waterMl)} ${tr('مل', 'mL')}',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                              tr('من ${arNum(litres(_waterGoalMl))} لتر '
                                  '(${arNum(_waterGoalMl)} مل)',
                                  'of ${arNum(litres(_waterGoalMl))} L '
                                  '(${arNum(_waterGoalMl)} mL)'),
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    WaterGlass(fraction: frac.clamp(0.0, 1.0)),
                  ],
                ),
                const SizedBox(height: 14),
                // أزرار سريعة بمقادير شائعة.
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final ml in const [100, 200, 250, 500])
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text('${arNum(ml)} ${tr('مل', 'mL')}'),
                      onPressed: () async {
                        await _changeWaterMl(ml);
                        setSheet(() {});
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 15),
                    label: Text(tr('كمية', 'Custom')),
                    onPressed: () async {
                      final ml = await _askMl(ctx);
                      if (ml != null) {
                        await _changeWaterMl(ml);
                        setSheet(() {});
                      }
                    },
                  ),
                  if (_waterMl > 0)
                    ActionChip(
                      avatar: const Icon(Icons.remove, size: 16),
                      label: Text('${arNum(250)} ${tr('مل', 'mL')}'),
                      onPressed: () async {
                        await _changeWaterMl(-250);
                        setSheet(() {});
                      },
                    ),
                ]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // تعديل مياه يوم فائت (نفس نمط الصلاة والعادات).
                    TextButton.icon(
                      icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                      label: Text(tr('يوم فائت', 'Past day')),
                      onPressed: () => _editPastWater(ctx),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.tune, size: 15),
                      label: Text(tr('حدّد الإجمالى', 'Set total')),
                      onPressed: () async {
                        final ml = await _askMl(ctx, initial: _waterMl);
                        if (ml != null) {
                          await _setWaterMl(ml);
                          setSheet(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// تعديل مياه يوم فائت: تنقّل بين الأيام + تحديد الإجمالى بالملى ليومه.
  Future<void> _editPastWater(BuildContext ctx) async {
    var day = DateTime.now().subtract(const Duration(days: 1));
    await showModalBottomSheet<void>(
      context: ctx,
      showDragHandle: true,
      builder: (c2) => StatefulBuilder(
        builder: (c2, setSheet) {
          final today = DateTime.now();
          final atYesterday =
              dayKey(day) == dayKey(today.subtract(const Duration(days: 1)));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('مياه يوم فائت', 'Past-day water'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: today.difference(day).inDays >= 30
                            ? null
                            : () => setSheet(() =>
                                day = day.subtract(const Duration(days: 1))),
                      ),
                      Text(arFullDate(day),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: atYesterday
                            ? null
                            : () => setSheet(
                                () => day = day.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                  FutureBuilder<int>(
                    key: ValueKey(dayKey(day)),
                    future: _health.waterMlOn(dayKey(day)),
                    builder: (_, snap) {
                      final ml = snap.data ?? 0;
                      return Column(children: [
                        Text('${arNum(ml)} ${tr('مل', 'mL')}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          for (final add in const [250, 500])
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 15),
                              label:
                                  Text('${arNum(add)} ${tr('مل', 'mL')}'),
                              onPressed: () async {
                                await _health.addWaterMl(dayKey(day), add);
                                setSheet(() {});
                              },
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.edit, size: 14),
                            label: Text(tr('حدّد', 'Set')),
                            onPressed: () async {
                              final v = await _askMl(c2, initial: ml);
                              if (v != null) {
                                await _health.setWaterMl(dayKey(day), v);
                                setSheet(() {});
                              }
                            },
                          ),
                        ]),
                      ]);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) await _load();
  }

  /// إدخال كمية بالملى (رقم).
  Future<int?> _askMl(BuildContext ctx, {int? initial}) async {
    final c = TextEditingController(text: initial == null ? '' : '$initial');
    final v = await showDialog<int>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(tr('الكمية بالملى', 'Amount in mL')),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('مثال: ٣٠٠', 'e.g. 300')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(d, (parseNumber(c.text) ?? 0).round()),
              child: Text(tr('تمام', 'OK'))),
        ],
      ),
    );
    c.dispose();
    return (v == null || v <= 0) ? null : v;
  }

  /// شباك النوم — اختيار عدد الساعات بالشيبس زي كارت النوم.
  Future<void> _openSleepSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bedtime_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('نمت كام ساعة امبارح؟', 'Hours slept last night?')),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var h = 1; h <= 24; h++)
                    ChoiceChip(
                      label: Text(arNum(h)),
                      selected: _sleep == h.toDouble(),
                      onSelected: (_) async {
                        await _setSleep(h.toDouble());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// شباك جرعات الدوا — كل دواء بمواعيده كشيبس تعلّم منها المتاخد.
  Future<void> _openDoseSheet() async {
    if (_activeMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('مفيش أدوية مسجلة', 'No meds logged'))));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: 20 +
                    MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.medication_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(tr('علّم الجرعات', 'Mark doses'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in _activeMeds) ...[
                          Text(m.name,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          if (m.times.isEmpty)
                            Text(tr('من غير مواعيد', 'No dose times'),
                                style: TextStyle(color: scheme.outline))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final s in m.times)
                                  FilterChip(
                                    label: Text(s),
                                    selected: _taken.contains('${m.id}|$s'),
                                    onSelected: (v) async {
                                      await _toggleMed(m.id!, s, v);
                                      setSheet(() {});
                                    },
                                  ),
                              ],
                            ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// كل الإجراءات السريعة المتاحة (المستخدم بيختار اللي يظهر وترتيبه).
  List<_QuickAct> _allActions(BuildContext context) {
    final handlers = <String, VoidCallback>{
      'water': _openWaterSheet,
      'dose': _openDoseSheet,
      'workout': _openWorkoutSheet,
      'sleep': _openSleepSheet,
      'steps': _openStepsSheet,
      'habit': _quickHabit,
      'meal': () => _reloadAfter(() => showMealSheet(context)),
      'expense': () => _reloadAfter(() => showQuickExpenseSheet(context)),
      'income': () => _reloadAfter(() => showIncomeSheet(context)),
      'transfer': _walletTransfer,
      'bill_paid': _openBillsSheet,
      'debt': _quickDebt,
      'measure': _quickMeasurement,
      'reminder': _quickInbox,
      'shopping': _addShoppingItem,
      'doc': () => _reloadAfter(() => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DocForm()))),
      'voice': () => _reloadAfter(_openVoice),
      'manager': () => _reloadAfter(() => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ChatScreen()))),
      'appointment': () => _reloadAfter(() => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AppointmentForm()))),
      'calendar': () => _reloadAfter(() => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()))),
      'pharmacy': () => _reloadAfter(() => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PharmacyScreen()))),
    };
    return [
      for (final e in quickActionCatalog())
        _QuickAct(e.key, e.icon, e.label, e.color, handlers[e.key] ?? () {}),
    ];
  }

  Future<void> _openQuickCustomize() async {
    final metas = [
      for (final e in quickActionCatalog())
        (key: e.key, icon: e.icon, label: e.label)
    ];
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuickActionsSettingsScreen(
            all: metas, enabledOrder: _quickOrder),
      ),
    );
    if (result != null) {
      await SettingsRepo().set('quick_actions', result.join(','));
      if (mounted) setState(() => _quickOrder = result);
    }
  }

  /// كتالوج اختصارات الصف — المستخدم بيختار منها ٤ ويرتّبهم (زى «خصّص الأزرار»).
  /// كل اختصار: مفتاح + أيقونة + اسم (قصير عشان مايتقصّش) + الفتح + مصدر البادج.
  List<({
    String key,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    int badge,
  })> _shortcutCatalog(BuildContext context) {
    final all = {for (final a in _allActions(context)) a.key: a};
    void open(Widget s) =>
        _reloadAfter(() => Navigator.push(context, MaterialPageRoute(builder: (_) => s)));
    return [
      (key: 'money', icon: Icons.account_balance_wallet_outlined,
          label: tr('الفلوس', 'Money'), color: Colors.teal,
          onTap: () => open(const MoneyScreen()), badge: 0),
      (key: 'agenda', icon: Icons.event_available_outlined,
          label: tr('مواعيد', 'Agenda'), color: Colors.blue,
          onTap: () => open(const ScheduleScreen()), badge: _todayAppts.length),
      (key: 'tasks', icon: Icons.checklist_outlined,
          label: tr('المهام', 'Tasks'), color: Colors.orange,
          onTap: () => open(const TasksScreen()), badge: _dueTasks),
      (key: 'voice', icon: Icons.mic_none, label: tr('صوت', 'Voice'),
          color: Colors.blueAccent, onTap: all['voice']?.onTap ?? () {}, badge: 0),
      (key: 'health', icon: Icons.favorite_outline, label: tr('الصحة', 'Health'),
          color: Colors.pink, onTap: () => open(const HealthHubScreen()), badge: 0),
      (key: 'prayer', icon: Icons.mosque_outlined, label: tr('الصلاة', 'Prayer'),
          color: const Color(0xFF2FA36B), onTap: () => open(const PrayerScreen()),
          badge: 0),
      (key: 'food', icon: Icons.restaurant_menu_outlined,
          label: tr('الأكل', 'Food'), color: Colors.deepOrange,
          onTap: () => open(const FoodCardScreen()), badge: 0),
      (key: 'dashboard', icon: Icons.dashboard_outlined,
          label: tr('لوحة', 'Board'), color: Colors.indigo,
          onTap: () => open(const DashboardScreen()), badge: 0),
      (key: 'gym', icon: Icons.fitness_center, label: tr('رياضة', 'Gym'),
          color: Colors.green, onTap: () => open(const GymScreen()), badge: 0),
    ];
  }

  // المهام اتشالت من الاختصارات الافتراضية (بطلب المستخدم) — لسه فى
  // الكتالوج فتتضاف تانى من «تخصيص الاختصارات».
  static const List<String> _defaultShortcuts = [
    'money', 'agenda', 'voice', 'health'
  ];

  /// صف الإجراءات: المدير · ➕ إضافة (المميّز) · [٤ اختصارات قابلة للتخصيص]
  /// وتحتهم شريط الطوارئ. كل أزرار الإضافة اتلمّت جوه الـ➕ عشان الصفحة تفضى.
  Widget _quickActions(BuildContext context) {
    final all = {for (final a in _allActions(context)) a.key: a};
    final catalog = {for (final s in _shortcutCatalog(context)) s.key: s};
    // أول ٤ من اختيار المستخدم (اللى لسه موجود فى الكتالوج).
    final chosen = [
      for (final k in _shortcutKeys)
        if (catalog.containsKey(k)) catalog[k]!
    ].take(4).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  child:
                      _managerStrip(context, all['manager']?.onTap ?? () {})),
              const SizedBox(width: 8),
              // موجز صباحى صوتى — بيقرا يومك بالـTTS.
              SizedBox(
                width: 46,
                height: 46,
                child: IconButton.filledTonal(
                  tooltip: tr('اسمع موجز يومك', 'Hear your day brief'),
                  icon: Icon(
                      _speaking ? Icons.stop : Icons.volume_up_outlined,
                      size: 20),
                  onPressed: _speakBrief,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // ➕ أول اليمين، وبعده الاختصارات المختارة.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _addBtn(context)),
                for (final s in chosen)
                  Expanded(
                    child: _actBtn(
                      icon: s.icon,
                      label: s.label,
                      color: s.color,
                      badge: s.badge,
                      onTap: s.onTap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // زرار صغير لتخصيص الاختصارات الـ٤.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _customizeShortcuts,
                icon: const Icon(Icons.tune, size: 15),
                label: Text(tr('تخصيص الاختصارات', 'Customize shortcuts'),
                    style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero),
              ),
            ),
            _emergencyStrip(context),
          ],
        ),
      ),
    );
  }

  /// شاشة اختيار وترتيب الاختصارات الـ٤ (بتستخدم نفس شاشة «خصّص الأزرار»).
  Future<void> _customizeShortcuts() async {
    final catalog = _shortcutCatalog(context);
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuickActionsSettingsScreen(
          all: [
            for (final s in catalog)
              (key: s.key, icon: s.icon, label: s.label)
          ],
          enabledOrder: _shortcutKeys,
        ),
      ),
    );
    if (result == null) return;
    // على الأقل واحد؛ لو فضّى نرجع للافتراضى.
    final keys = result.isEmpty ? _defaultShortcuts : result;
    await SettingsRepo().set('home_shortcuts', keys.join(','));
    if (mounted) setState(() => _shortcutKeys = keys);
  }

  FlutterTts? _tts;
  bool _speaking = false;

  /// بيقرا الموجز الصباحى صوتياً (أو يوقفه لو شغّال).
  Future<void> _speakBrief() async {
    try {
      if (_speaking) {
        await _tts?.stop();
        if (mounted) setState(() => _speaking = false);
        return;
      }
      setState(() => _speaking = true);
      final text = await buildMorningBrief();
      _tts ??= FlutterTts();
      await _tts!.setLanguage(AppState.isEnglish ? 'en-US' : 'ar');
      _tts!.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      await _tts!.speak(text);
    } on Exception catch (e) {
      logError('فشل الموجز الصوتى', e);
      if (mounted) setState(() => _speaking = false);
    }
  }

  /// «اسأل مديرك» — زرار بعرض الشاشة فوق صف الإجراءات.
  Widget _managerStrip(BuildContext context, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: const Icon(Icons.psychology_outlined, size: 20),
        label: _noCut(tr('اسأل مديرك', 'Ask your manager'),
            size: 14, weight: FontWeight.w800),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.14),
          foregroundColor: scheme.brightness == Brightness.dark
              ? Colors.deepPurple.shade200
              : Colors.deepPurple.shade700,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// نص مايتقصّش أبداً بأى لغة: `FittedBox` **بيصغّر الخط بدل ما يقطع**
  /// (مهم لأن الإنجليزى أطول من العربى — «Appointments» مقابل «المواعيد»).
  Widget _noCut(String text,
          {double size = 11,
          Color? color,
          FontWeight weight = FontWeight.normal,
          int maxLines = 1}) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: maxLines,
          softWrap: maxLines > 1,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size, color: color, fontWeight: weight),
        ),
      );

  /// زرار عادى مضغوط + بادج اختيارى (٠ = مفيش بادج).
  Widget _actBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badge > 0)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      child: Text(
                        arNum(badge),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 15,
              width: double.infinity,
              child: _noCut(label, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  /// الزرار الرئيسى: أكبر ومليان بلون الهوية — بيفتح كل أزرار الإضافة.
  Widget _addBtn(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _openAddSheet,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: scheme.onPrimary, size: 30),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 15,
              width: double.infinity,
              child: _noCut(tr('إضافة', 'Add'),
                  size: 11.5, color: scheme.primary, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  /// شريط الطوارئ — بعرض الشاشة بس رفيع (مش بياكل مساحة يومية).
  Widget _emergencyStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EmergencyView())),
        icon: Icon(Icons.emergency_outlined, size: 18, color: scheme.error),
        label: Text(tr('الطوارئ', 'Emergency'),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// شيت الإضافة: كل أزرار الإضافة بترتيب المستخدم من «خصّص الأزرار السريعة».
  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // بيطول لأعلى الشاشة تقريباً عشان البنود كلها تبان مرة واحدة.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final all = {for (final a in _allActions(context)) a.key: a};
        final shown = [
          for (final k in _quickOrder)
            // الخطوات اليدوى بيتخفى لما المزامنة التلقائية شغّالة.
            if (all.containsKey(k) && !(k == 'steps' && _stepsAuto)) all[k]!
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(tr('إضافة سريعة', 'Quick add'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(tr('خصّص', 'Customize')),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openQuickCustomize();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // ٣ فى الصف — الكروت بتطلع أكبر وأوضح، والعرض متحسوب من
                // المساحة الفعلية عشان يظبط على أى شاشة.
                Flexible(
                  child: LayoutBuilder(
                    builder: (ctx2, box) {
                      const perRow = 3;
                      final w = box.maxWidth / perRow;
                      return SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            for (final a in shown)
                              SizedBox(
                                width: w,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    a.onTap();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: a.color
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Icon(a.icon,
                                              color: a.color, size: 30),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          // سطرين: «فاتورة اتدفعت» تتقسم بدل
                                          // ما الخط يتصغّر لـ٥٤%.
                                          height: 34,
                                          width: double.infinity,
                                          child: _noCut(a.label,
                                              size: 13,
                                              maxLines: 2,
                                              color: scheme.onSurface,
                                              weight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // ignore: unused_element  (اتشال من الرئيسية بطلب المستخدم — متساب لإعادة الاستخدام)
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

  // ignore: unused_element  (اتشال من الرئيسية بطلب المستخدم — متساب لإعادة الاستخدام)
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

  // ignore: unused_element  (اتشال من الرئيسية — الخطوات في قسم الساعة الذكية)
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

}

/// إجراء سريع متاح على شاشة اليوم (بيتخزّن اختياره وترتيبه في الإعدادات).
class _QuickAct {
  final String key;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAct(this.key, this.icon, this.label, this.color, this.onTap);
}

/// شيت اختيار كروت الرئيسية — المستخدم بيعلّم اللى يحبه يشوفه.
///
/// بيرجّع مجموعة المفاتيح المختارة، أو null لو اتلغى. لو المستخدم شال
/// الكل بترجع فاضية — والرئيسية ساعتها بتعرض تلميح «دوس ＋» بدل شبكة
/// فاضية بلا تفسير.
class _HomeCardsPicker extends StatefulWidget {
  final List<({String key, String title})> all;
  final Set<String> selected;

  const _HomeCardsPicker({required this.all, required this.selected});

  @override
  State<_HomeCardsPicker> createState() => _HomeCardsPickerState();
}

class _HomeCardsPickerState extends State<_HomeCardsPicker> {
  late Set<String> _sel = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('اختار كروتك', 'Pick your cards'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _sel = _sel.length ==
                          widget.all.length
                      ? <String>{}
                      : widget.all.map((e) => e.key).toSet()),
                  child: Text(_sel.length == widget.all.length
                      ? tr('شيل الكل', 'Clear all')
                      : tr('اختار الكل', 'Select all')),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in widget.all)
                  CheckboxListTile(
                    value: _sel.contains(c.key),
                    onChanged: (v) => setState(() =>
                        v == true ? _sel.add(c.key) : _sel.remove(c.key)),
                    secondary: Icon(
                      dashLook(c.key)?.icon ?? Icons.dashboard_outlined,
                      color: dashLook(c.key)?.color,
                    ),
                    title: Text(c.title),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _sel),
                child: Text(tr('حفظ', 'Save')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
