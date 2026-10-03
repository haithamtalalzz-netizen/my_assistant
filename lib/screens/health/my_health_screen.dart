import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/day_log.dart';
import '../../data/health_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/meals_repo.dart';
import '../../data/meds_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../core/health_calc.dart';
import '../../data/lab_results_repo.dart';
import '../../data/symptoms_repo.dart';
import '../../data/vaccinations_repo.dart';
import '../../widgets/a_kit.dart';
import '../brain/charts_screen.dart';
import 'lab_results_screen.dart';
import 'symptom_journal_screen.dart';
import 'vaccinations_screen.dart';
import '../../widgets/measurement_sheet.dart';
import '../../widgets/search_action.dart';
import '../food/meal_sheet.dart';
import 'exercise_sheet.dart';
import '../gym/walk_tracker_screen.dart';
import '../../core/privacy.dart';

/// **صحتى** — قسمين واضحين وبعدهم البنود.
///
/// اللى كان قبل كده: قايمة تسع أبواب (الأدوية · الدورة · العادات · …)
/// **مافيهاش ولا رقم**. تدوس عشان تعرف. الشاشة دى بتقلب ده:
///
///   · **لازم النهاردة** — اللى المفروض تعمله انهارده وانت تعلّم عليه من
///     هنا على طول (جرعات الدوا · المياه). ده مش عرض، ده شغل.
///   · **أرقامك** — آخر وزن وضغط وسكر وخطوات ونوم وسعرات، كل واحد
///     باتجاهه. الرقم اللى مالوش قياس بيقول «—» مش صفر: الصفر بيتقرا
///     كأنه قياس، والفاضى مش نفس الحاجة.
///   · **بنودك** — الأبواب الباقية، وكل واحد بيقول رقمه.
class MyHealthScreen extends StatefulWidget {
  /// بيتنادى لمّا تدوس على بند بيفتح تبويب فى الشِل.
  final void Function(int index)? onSelectTab;

  /// البنود اللى تحت — بتيجى من السايدبار عشان الشاشة ماتعرفش بالشاشات.
  final List<HealthSection> sections;

  /// مكتبتَى «الرياضة» و«الأكل». اتشالوا من السايدبار، فبيتفتحوا من
  /// سطرهم هنا — لإن جوّاهم شاشات (مخطّط الوجبات · الأنظمة الغذائية ·
  /// الصيام) **مالهاش باب تانى فى التطبيق كله**، وحذف البند كان
  /// هييتّمها.
  final Widget Function()? exerciseHub;
  final Widget Function()? foodHub;

  const MyHealthScreen({
    super.key,
    this.onSelectTab,
    this.sections = const [],
    this.exerciseHub,
    this.foodHub,
  });

  @override
  State<MyHealthScreen> createState() => _MyHealthScreenState();
}

/// بند تحت «بنودك» — اسم وأيقونة ولون والشاشة اللى بيفتحها.
class HealthSection {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Widget Function() open;

  const HealthSection(this.icon, this.label, this.sub, this.color, this.open);
}

class _MyHealthScreenState extends State<MyHealthScreen> {
  final _meds = MedsRepo();
  final _health = HealthRepo();

  bool _loading = true;
  List<Medication> _medList = [];
  Set<String> _taken = {};
  int _waterMl = 0;
  int _waterGoalMl = 2000;
  HealthDay? _day;
  final Map<String, List<Measurement>> _vitals = {};

  /// الطول وسنة الميلاد — بيتحسب منهم مؤشر كتلة الجسم. كانوا جوّه
  /// «لوحة الصحة» اللى اتشالت من الطريق.
  double? _heightCm;
  int? _birthYear;

  /// «عملت إيه النهاردة» — الرقم جاى من مصدرين (نشاط حُرّ + جيم)،
  /// والأزرار الجاهزة بتتعلّم من اللى بتسجّله.
  ExerciseDay _exercise = const ExerciseDay(0, '');
  List<ExercisePreset> _presets = const [];
  ({int calories, String what}) _meals = (calories: 0, what: '');

  /// أعداد ورقك الطبى — بتتعرض على المربعات عشان تعرف اللى جوّه قبل
  /// ما تفتح (نفس قاعدة «فلوسى»: مافيش باب أعمى).
  int? _labs;
  int? _vaccines;
  int? _symptoms;

  String get _today => dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await _meds.all(activeOnly: true);
    final taken = await _meds.takenOn(_today);
    final ml = await _health.waterMlOn(_today);
    final goal = await SettingsRepo().waterGoalMl();
    final day = await _health.dayReport(_today);
    final st = SettingsRepo();
    final heightCm = double.tryParse(await st.get('height_cm') ?? '');
    final birthYear = int.tryParse(await st.get('birth_year') ?? '');
    final exercise = await DayLog.exerciseToday();
    final presets = await DayLog.presets();
    final meals = await DayLog.mealsToday();
    final labs = (await LabResultsRepo().all()).length;
    final vaccines = (await VaccinationsRepo().all()).length;
    final symptoms = (await SymptomsRepo().recent()).length;
    final vitals = <String, List<Measurement>>{};
    for (final t in kMeasurementTypes) {
      vitals[t] = await MeasurementsRepo().recent(limit: 2, type: t);
    }
    if (!mounted) return;
    setState(() {
      _medList = meds;
      _taken = taken;
      _waterMl = ml;
      _waterGoalMl = goal <= 0 ? 2000 : goal;
      _day = day;
      _heightCm = heightCm;
      _birthYear = birthYear;
      _exercise = exercise;
      _presets = presets;
      _meals = meals;
      _labs = labs;
      _vaccines = vaccines;
      _symptoms = symptoms;
      _vitals
        ..clear()
        ..addAll(vitals);
      _loading = false;
    });
  }

  // ————————————————— لازم النهاردة —————————————————

  /// كل جرعة اليوم كبند لوحدها: (الدوا، وقتها، اتاخدت؟).
  List<(Medication, String, bool)> get _doses => [
        for (final m in _medList)
          for (final t in m.times) (m, t, _taken.contains('${m.id}|$t')),
      ];

  bool get _waterDone => _waterMl >= _waterGoalMl;

  /// هل وقت الجرعة دى عدّى؟
  ///
  /// 🔴 جرعة الساعة ٩ بالليل مش «متأخرة» الساعة ٣ العصر. تلوينها أحمر
  /// بيخلّى الشاشة تصرخ على حاجة لسه ماجاش وقتها — نفس اللى كان بيحصل
  /// فى الصلاة لما كان ينفع تعلّم عليها قبل أذانها.
  bool _slotPassed(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    final now = DateTime.now();
    return now.isAfter(DateTime(now.year, now.month, now.day, h, m));
  }

  /// (اللى اتعمل، الإجمالى) — الجرعات + المياه.
  (int, int) get _todayScore {
    final d = _doses;
    final done = d.where((e) => e.$3).length + (_waterDone ? 1 : 0);
    return (done, d.length + 1);
  }

  Future<void> _toggleDose(Medication m, String slot, bool taken) async {
    await _meds.setTaken(m.id!, _today, slot, !taken);
    await _load();
  }

  Future<void> _addWaterCup() async {
    await _health.addWaterMl(_today, 250);
    await _load();
  }

  Widget _todoRow(
      {required IconData icon,
      required String title,
      String? note,
      required String trail,
      required Color trailColor,
      required bool done,
      required VoidCallback onTap,
      bool divider = true}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: divider
            ? BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.7))))
            : null,
        child: Row(children: [
          Icon(done ? Icons.check_circle : Icons.circle_outlined,
              size: 23, color: done ? scheme.primary : scheme.outline),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? scheme.outline : scheme.onSurface)),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, color: scheme.onSurfaceVariant)),
                  ],
                ]),
          ),
          const SizedBox(width: 8),
          Text(trail,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: trailColor)),
          const SizedBox(width: 4),
          Icon(icon, size: 15, color: scheme.outline),
        ]),
      ),
    );
  }

  Widget _todaySection() {
    final scheme = Theme.of(context).colorScheme;
    final doses = _doses;
    return AppCard(Column(children: [
      for (var i = 0; i < doses.length; i++)
        _todoRow(
          icon: Icons.medication_outlined,
          title: '${doses[i].$1.name} ${doses[i].$1.dosage}'.trim(),
          note: doses[i].$3
              ? tr('اتاخدت ${arTimeOfSlot(doses[i].$2)}',
                  'taken at ${arTimeOfSlot(doses[i].$2)}')
              : _slotPassed(doses[i].$2)
                  ? tr('كان المفروض ${arTimeOfSlot(doses[i].$2)}',
                      'was due at ${arTimeOfSlot(doses[i].$2)}')
                  : tr('لسه ماجاش وقتها', 'Not due yet'),
          trail: doses[i].$3
              ? tr('اتاخدت', 'Taken')
              : _slotPassed(doses[i].$2)
                  ? tr('فاتت', 'Missed')
                  : arTimeOfSlot(doses[i].$2),
          trailColor: doses[i].$3
              ? scheme.primary
              : _slotPassed(doses[i].$2)
                  ? scheme.error
                  : scheme.onSurfaceVariant,
          done: doses[i].$3,
          onTap: () => _toggleDose(doses[i].$1, doses[i].$2, doses[i].$3),
        ),
      _todoRow(
        icon: Icons.water_drop_outlined,
        title: tr('اشرب ${arNum(_waterGoalMl ~/ 250)} أكواب مياه',
            'Drink ${arNum(_waterGoalMl ~/ 250)} cups'),
        note: _waterDone
            ? tr('خلّصت هدف النهاردة', "Today's goal met")
            : tr('فاضل ${arNum(((_waterGoalMl - _waterMl) / 250).ceil())} كوباية',
                '${arNum(((_waterGoalMl - _waterMl) / 250).ceil())} cups left'),
        trail: tr('${arNum(_waterMl ~/ 250)} من ${arNum(_waterGoalMl ~/ 250)}',
            '${arNum(_waterMl ~/ 250)} of ${arNum(_waterGoalMl ~/ 250)}'),
        trailColor: _waterDone ? scheme.primary : scheme.tertiary,
        done: _waterDone,
        // دوسة = كوباية. ده الفرق بين شاشة بتتفرّج وشاشة بتشتغل.
        onTap: _addWaterCup,
        divider: false,
      ),
    ]));
  }

  // ————————————————— أرقامك —————————————————

  /// آخر قياس من نوع + اتجاهه مقارنةً باللى قبله.
  (String value, String? trend, bool up)? _vital(String type) {
    final list = _vitals[type] ?? const [];
    if (list.isEmpty) return null;
    final latest = list.first;
    final prev = list.length > 1 ? list[1] : null;
    final v = latest.value2 == null
        ? _num(latest.value)
        : '${_num(latest.value)}/${_num(latest.value2!)}';
    if (prev == null || prev.value == latest.value) return (v, null, false);
    final diff = latest.value - prev.value;
    return (v, _num(diff.abs()), diff > 0);
  }

  static String _num(double d) =>
      arNum(d == d.roundToDouble() ? d.round().toString() : d.toStringAsFixed(1));

  /// مربّع رقم. [goodWhenUp] = هل الطلوع حاجة كويسة؟
  /// (الوزن والضغط والسكر: النزول أحسن. الخطوات: الطلوع أحسن.)
  ///
  /// المربّع **بيتداس**: شاشة بتعرض أرقام من غير ما تسجّل منها بتخلّيك
  /// تدوّر على مكان التسجيل فى شاشة تانية، والنتيجة إنك ماتسجّلش.
  Widget _sq(IconData icon, Color tint, String? value, String label,
      {String? trend,
      bool up = false,
      bool goodWhenUp = false,
      VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;
    final good = up == goodWhenUp;
    return Expanded(
      child: Material(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tint.withValues(alpha: 0.22))),
        child: Column(children: [
          Icon(icon, size: 17, color: tint),
          const SizedBox(height: 6),
          // «—» مش «0»: الصفر بيتقرا كأنه قياس اتاخد وطلع صفر.
          Text(value ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant)),
          if (trend != null) ...[
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(up ? Icons.north_east : Icons.south_east,
                  size: 10, color: good ? scheme.primary : scheme.error),
              const SizedBox(width: 2),
              Text(trend,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: good ? scheme.primary : scheme.error)),
            ]),
          ],
        ]),
          ),
        ),
      ),
    );
  }

  Future<void> _logMeasurement(String type) async {
    if (!await openMeasurementSheet(context, type)) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('اتسجّل القياس', 'Measurement saved'))));
    await _load();
  }

  Future<void> _logSleep() async {
    if (!await openSleepSheet(context)) return;
    if (mounted) await _load();
  }

  /// فيه أى رقم متسجّل أصلاً؟ لو لأ الشاشة بتقول اعمل إيه بدل ما
  /// تسيبك قدّام ستّ شرطات.
  bool get _anyNumber =>
      (_day?.steps ?? 0) > 0 ||
      (_day?.calories ?? 0) > 0 ||
      _day?.sleep != null ||
      _vitals.values.any((l) => l.isNotEmpty);

  Widget _numbersSection() {
    final d = _day;
    final weight = _vital('وزن');
    final bp = _vital('ضغط');
    final sugar = _vital('سكر');
    return Column(children: [
      Row(children: [
        _sq(Icons.monitor_weight_outlined, const Color(0xFF3B82F6),
            weight?.$1, tr('كيلو', 'kg'),
            trend: weight?.$2,
            up: weight?.$3 ?? false,
            onTap: () => _logMeasurement('وزن')),
        const SizedBox(width: 9),
        _sq(Icons.favorite_outline, const Color(0xFFF43F5E), bp?.$1,
            tr('ضغط', 'BP'),
            onTap: () => _logMeasurement('ضغط')),
        const SizedBox(width: 9),
        _sq(Icons.bloodtype_outlined, const Color(0xFFF59E0B), sugar?.$1,
            tr('سكر', 'Sugar'),
            trend: sugar?.$2,
            up: sugar?.$3 ?? false,
            onTap: () => _logMeasurement('سكر')),
      ]),
      const SizedBox(height: 9),
      Row(children: [
        _sq(Icons.directions_walk, const Color(0xFF10B981),
            (d?.steps ?? 0) > 0 ? arMoney(d!.steps) : null,
            tr('خطوة', 'steps'),
            goodWhenUp: true, onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WalkTrackerScreen()));
          if (mounted) await _load();
        }),
        const SizedBox(width: 9),
        _sq(
            Icons.bedtime_outlined,
            const Color(0xFF8B5CF6),
            d?.sleep == null
                ? null
                : tr('${_num(d!.sleep!)} س', '${_num(d.sleep!)} h'),
            tr('نوم', 'sleep'),
            goodWhenUp: true,
            onTap: _logSleep),
        const SizedBox(width: 9),
        _sq(Icons.local_fire_department_outlined, const Color(0xFFFF6F00),
            (d?.calories ?? 0) > 0 ? arMoney(d!.calories) : null,
            tr('سعرة', 'kcal'), onTap: () async {
          if (await showMealSheet(context) == true && mounted) await _load();
        }),
      ]),
    ]);
  }

  // ————————————————— عملت إيه النهاردة —————————————————

  /// سطر بيقول اللى اتسجّل بالكلام، ومعاه أزرار بتسجّل **بدوسة واحدة**.
  ///
  /// السطر بدل المربّع لإن المربّع بيقول رقم: «٤٠ د» مابتقولش مشيت ولا
  /// لعبت حديد، و«١٤٥٠ سعرة» مابتقولش أكلت إيه.
  Widget _doneRow({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    String? big,
    required List<(String, VoidCallback)> chips,
    required VoidCallback onMore,
    VoidCallback? onOpenHub,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: onOpenHub,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (onOpenHub != null)
                          Icon(Icons.chevron_left,
                              size: 17, color: scheme.outline),
                      ]),
                      const SizedBox(height: 2),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ]),
              ),
            ),
            if (big != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(big,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: color)),
              ),
            IconButton(
              tooltip: tr('ورقة التسجيل الكاملة', 'Full form'),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.add_circle_outline, size: 21, color: color),
              onPressed: onMore,
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final (label, tap) in chips)
              _chip(label, color, tap),
            _chip(tr('غير كده…', 'Other…'), scheme.outline, onMore,
                faded: true),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color, VoidCallback onTap,
          {bool faded = false}) =>
      Material(
        color: color.withValues(alpha: faded ? 0.08 : 0.13),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: faded
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : color)),
          ),
        ),
      );

  /// الزرار بيكتب على طول — فلازم يبقى فيه «تراجع»، وإلا دوسة بالغلط
  /// بتخلّى الرقم كدب ومفيش طريقة تصلّحه من هنا.
  void _undoBar(String text, Future<void> Function() undo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      action: SnackBarAction(
        label: tr('تراجع', 'Undo'),
        onPressed: () async {
          await undo();
          if (mounted) await _load();
        },
      ),
    ));
  }

  Future<void> _quickExercise(ExercisePreset p) async {
    final id = await DayLog.logExercise(p);
    await _load();
    _undoBar(tr('اتسجّل: ${p.label}', 'Logged: ${p.label}'),
        () => DayLog.undoExercise(id));
  }

  Future<void> _openHub(Widget Function() build) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => build()));
    if (mounted) await _load();
  }

  Future<void> _openExerciseSheet() async {
    final id = await showExerciseSheet(context);
    if (id == null || !mounted) return;
    await _load();
    _undoBar(tr('اتسجّلت التمرينة', 'Workout logged'),
        () => DayLog.undoExercise(id));
  }

  Future<void> _quickMeal(String slot) async {
    final id = await DayLog.repeatMeal(slot);
    // أول مرة فى الخانة دى: مفيش حاجة نكرّرها، فبنفتح الورقة بدل ما
    // نسجّل حاجة من دماغنا.
    if (id == null) {
      if (!mounted) return;
      if (await showMealSheet(context) == true && mounted) await _load();
      return;
    }
    final prev = await DayLog.lastMealForSlot(slot);
    await _load();
    _undoBar(
        tr('اتسجّل: $slot — ${prev?.description ?? ''}',
            'Logged: $slot — ${prev?.description ?? ''}'),
        () => DayLog.undoMeal(id));
  }

  Widget _doneSection() {
    return Column(children: [
      _doneRow(
        icon: Icons.fitness_center,
        color: const Color(0xFF8B5CF6),
        title: tr('رياضة', 'Exercise'),
        sub: _exercise.isEmpty
            ? tr('دوس على زرار جاهز، أو «＋» تكتب تمرينة',
                'Tap a preset, or + to write one')
            : _exercise.calories > 0
                ? tr('${_exercise.what} · حرقت ${arMoney(_exercise.calories)}',
                    '${_exercise.what} · ${arMoney(_exercise.calories)} burned')
                : _exercise.what,
        big: _exercise.isEmpty
            ? null
            : tr('${arNum(_exercise.minutes)} د', '${_exercise.minutes}m'),
        chips: [
          for (final p in _presets) (p.label, () => _quickExercise(p)),
        ],
        onMore: _openExerciseSheet,
        onOpenHub: widget.exerciseHub == null ? null : () => _openHub(widget.exerciseHub!),
      ),
      _doneRow(
        icon: Icons.restaurant_outlined,
        color: const Color(0xFF10B981),
        title: tr('أكلت', 'Ate'),
        sub: _meals.what.isEmpty
            ? tr('الزرار بيكرّر آخر مرة أكلتها فى الخانة دى',
                'A tap repeats your last meal in that slot')
            : _meals.what,
        big: _meals.calories <= 0 ? null : arMoney(_meals.calories),
        chips: [
          for (final slot in kMealSlots) (slot, () => _quickMeal(slot)),
        ],
        onMore: () async {
          if (await showMealSheet(context) == true && mounted) await _load();
        },
        onOpenHub: widget.foodHub == null ? null : () => _openHub(widget.foodHub!),
      ),
    ]);
  }

  // ————————————————— بنودك —————————————————

  /// **كتلة الجسم + الرسوم** — كانوا جوّه «لوحة الصحة»، وهى بقت مكرّرة
  /// مع الشاشة دى (نفس المياه والنوم والخطوات والقياسات). فاللى كان
  /// حصرى فيها نزل هنا، واللوحة اتشالت من الطريق.
  Widget _bmiRow() {
    final scheme = Theme.of(context).colorScheme;
    final list = _vitals['وزن'] ?? const <Measurement>[];
    final w = list.isEmpty ? null : list.first.value;
    final ready = w != null && _heightCm != null && _heightCm! > 0;
    final v = ready ? bmi(w, _heightCm!) : 0.0;
    // النطاق المعروض ١٥→٣٥: برّه كده الشريط بيتسطّح ومابيقولش حاجة.
    final pct = ((v - 15) / 20).clamp(0.0, 1.0);
    final c = !ready
        ? scheme.outline
        : (v < 18.5 || v >= 30)
            ? scheme.error
            : v < 25
                ? scheme.primary
                : const Color(0xFFF59E0B);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openBodyInfo,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        ready
                            ? tr(
                                'كتلة الجسم ${v.toStringAsFixed(1)} — ${bmiCategoryAr(v)}',
                                'BMI ${v.toStringAsFixed(1)} — ${bmiCategoryEn(v)}')
                            : tr('حدّد طولك عشان نحسب كتلة الجسم',
                                'Set your height to get BMI'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor:
                            scheme.outlineVariant.withValues(alpha: 0.6),
                        valueColor: AlwaysStoppedAnimation(c),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChartsScreen())),
              icon: const Icon(Icons.show_chart, size: 17),
              label: Text(tr('الرسوم', 'Charts'),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  /// طولك وسنة ميلادك — المدخلات اللى الـBMI محتاجها.
  Future<void> _openBodyInfo() async {
    final h = TextEditingController(
        text: _heightCm == null ? '' : _heightCm!.toStringAsFixed(0));
    final y = TextEditingController(text: _birthYear?.toString() ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('بياناتك', 'Your body')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: h,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: tr('الطول (سم)', 'Height (cm)'))),
            const SizedBox(height: 10),
            TextField(
                controller: y,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: tr('سنة الميلاد', 'Birth year'))),
          ]),
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
      if (ok != true) return;
      final st = SettingsRepo();
      final hv = parseNumber(h.text);
      final yv = int.tryParse(toEnglishDigits(y.text).trim());
      if (hv != null && hv > 0) await st.set('height_cm', hv.toString());
      if (yv != null && yv > 1900) await st.set('birth_year', yv.toString());
      if (mounted) await _load();
    } finally {
      // الـcontrollers بتتمسح فى finally: لو الحوار اتقفل بضغطة رجوع
      // كانت هتفضل شايلة ذاكرة.
      h.dispose();
      y.dispose();
    }
  }

  /// **ورقك الطبى** — تلات شاشات كان طريقها الوحيد أيقونة فى الشريط ←
  /// كارت جوّه لوحة الصحة. دوستين ورا أيقونة محدّش يعرف معناها معناها
  /// إن الشاشات دى موجودة ومش مكتشفة.
  Widget _papersRow() {
    final scheme = Theme.of(context).colorScheme;

    Widget box(String label, Color c, IconData icon, int? value,
            Widget Function() open) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Material(
              color: c.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => open()));
                  if (mounted) await _load();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.withValues(alpha: 0.25))),
                  child: Column(children: [
                    Icon(icon, size: 17, color: c),
                    const SizedBox(height: 5),
                    // «—» مش «0»: الصفر بيتقرا كأنه حاجة اتحسبت.
                    Text(value == null || value == 0 ? '—' : arNum(value),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: c)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 9.5, color: scheme.onSurfaceVariant)),
                  ]),
                ),
              ),
            ),
          ),
        );

    return Row(children: [
      box(tr('تحاليل', 'Labs'), const Color(0xFF06B6D4),
          Icons.science_outlined, _labs, () => const LabResultsScreen()),
      box(tr('تطعيمات', 'Vaccines'), const Color(0xFF10B981),
          Icons.vaccines_outlined, _vaccines,
          () => const VaccinationsScreen()),
      box(tr('أعراض', 'Symptoms'), const Color(0xFFF59E0B),
          Icons.sick_outlined, _symptoms,
          () => const SymptomJournalScreen()),
    ]);
  }

  Widget _sectionRow(HealthSection s) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => s.open()));
            if (mounted) await _load();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(s.icon, size: 19, color: s.color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(s.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5, color: scheme.onSurfaceVariant)),
                    ]),
              ),
              Icon(Icons.chevron_left, size: 19, color: scheme.outline),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (done, total) = _todayScore;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('صحتى', 'My health')),
        // زرار «لوحة الصحة» اتشال: اللوحة كانت بتعرض **نفس** اللقطة
        // والقياسات اللى فوق، واللى كان حصرى فيها (كتلة الجسم · الرسوم ·
        // الورق الطبى) نزل جوّه الشاشة دى.
        actions: [const PrivacyAction(), searchAction(context)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  AppPad(AppGroupHead(tr('لازم النهاردة', 'Today'),
                      trail: tr('${arNum(done)} من ${arNum(total)}',
                          '${arNum(done)} of ${arNum(total)}'))),
                  AppPad(_todaySection()),
                  AppPad(AppGroupHead(
                      tr('عملت إيه النهاردة', 'What you did today'))),
                  AppPad(_doneSection()),
                  AppPad(AppGroupHead(tr('أرقامك', 'Your numbers'),
                      trail: _anyNumber
                          ? null
                          : tr('دوس على أى مربّع تسجّل', 'Tap any to log'))),
                  AppPad(_numbersSection()),
                  AppPad(Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: _bmiRow())),
                  AppPad(AppGroupHead(tr('بنودك', 'Your sections'))),
                  AppPad(Column(
                      children: [for (final s in widget.sections) _sectionRow(s)])),
                  AppPad(AppGroupHead(tr('ورقك الطبى', 'Your records'))),
                  AppPad(_papersRow()),
                ],
              ),
            ),
    );
  }
}
