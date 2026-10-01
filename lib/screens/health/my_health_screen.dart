import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/health_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/meds_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/measurement_sheet.dart';
import '../../widgets/search_action.dart';
import '../food/meal_sheet.dart';
import '../gym/walk_tracker_screen.dart';
import 'health_hub_screen.dart';
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

  const MyHealthScreen({super.key, this.onSelectTab, this.sections = const []});

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

  // ————————————————— بنودك —————————————————

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
        actions: [
          const PrivacyAction(),
          searchAction(context),
          IconButton(
            tooltip: tr('لوحة الصحة', 'Health dashboard'),
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HealthHubScreen()));
              if (mounted) await _load();
            },
          ),
        ],
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
                  AppPad(AppGroupHead(tr('أرقامك', 'Your numbers'),
                      trail: _anyNumber
                          ? null
                          : tr('دوس على أى مربّع تسجّل', 'Tap any to log'))),
                  AppPad(_numbersSection()),
                  AppPad(AppGroupHead(tr('بنودك', 'Your sections'))),
                  AppPad(Column(
                      children: [for (final s in widget.sections) _sectionRow(s)])),
                ],
              ),
            ),
    );
  }
}
