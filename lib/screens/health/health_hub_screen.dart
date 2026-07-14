import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/health_repo.dart';
import '../../data/meals_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/medical_repo.dart';
import '../../data/meds_repo.dart';
import '../../data/pharmacy_repo.dart';
import '../../data/vaccinations_repo.dart';
import '../../models/models.dart';
import '../../widgets/history_calendar.dart';
import '../brain/charts_screen.dart';
import '../food/meal_sheet.dart';
import '../schedule/schedule_screen.dart';
import 'symptom_journal_screen.dart';
import 'vaccinations_screen.dart';
import '../gym/gym_screen.dart';
import '../gym/progress_screen.dart';
import '../home/pharmacy_screen.dart';
import '../medical/medical_screen.dart';

/// لوحة صحّة موحّدة — تجمع كل حاجة صحية في مكان واحد:
/// لقطة النهارده (مياه/نوم/خطوات/سعرات) + مداخل للجيم والتقدم البدني
/// والملف الطبي والصيدلية وتسجيل وجبة.
class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> {
  bool _loading = true;
  int _water = 0;
  double? _sleep;
  int _steps = 0;
  int _eatenCalories = 0;
  int _mealsCount = 0;
  int _medicalCount = 0;
  int _pharmacyExpiring = 0;
  int _vaccineDue = 0;
  int? _adherence;

  /// آخر قراءتين لكل نوع قياس (ضغط/سكر/وزن/حرارة) — للأحدث + اتجاه التغيّر.
  final Map<String, List<Measurement>> _vitals = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = dayKey(DateTime.now());
    final water = await HealthRepo().waterOn(today);
    final sleep = await HealthRepo().sleepOn(today);
    final stepsMap = await MeasurementsRepo().stepsSince(today);
    final meals = await MealsRepo().forDay(today);
    final medical = await MedicalRepo().all();
    final pharmacy = await PharmacyRepo().all();
    final adherence = await MedsRepo().adherencePercent();
    final vaccineDue = (await VaccinationsRepo().dueSoon()).length;

    final vitals = <String, List<Measurement>>{};
    for (final t in kMeasurementTypes) {
      vitals[t] = await MeasurementsRepo().recent(limit: 2, type: t);
    }

    // أدوية قربت تنتهي (خلال ٣٠ يوم) أو خلصت.
    final soon = DateTime.now().add(const Duration(days: 30));
    var expiring = 0;
    for (final it in pharmacy) {
      final e = it.expiry == null ? null : DateTime.tryParse(it.expiry!);
      if (e != null && e.isBefore(soon)) expiring++;
    }

    if (!mounted) return;
    setState(() {
      _water = water;
      _sleep = sleep;
      _steps = stepsMap[today] ?? 0;
      _eatenCalories = meals.fold<int>(
          0, (s, m) => s + (m.calories?.round() ?? 0));
      _mealsCount = meals.length;
      _medicalCount = medical.length;
      _pharmacyExpiring = expiring;
      _vaccineDue = vaccineDue;
      _adherence = adherence;
      _vitals
        ..clear()
        ..addAll(vitals);
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  /// تقويم/سجل الصحة — ترجع للأيام الماضية تشوف مياهك ونومك وقياساتك.
  void _openHistory() {
    const emoji = {'ضغط': '🩸', 'سكر': '🍬', 'وزن': '⚖️', 'حرارة': '🌡'};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryCalendar(
          title: tr('سجل الصحة', 'Health history'),
          accent: Colors.teal,
          activeDays: (y, m) => HealthRepo().activeDaysInMonth(y, m),
          dayReport: (day) async {
            final r = await HealthRepo().dayReport(dayKey(day));
            return [
              if (r.water > 0)
                HistoryRow('💧', tr('مياه', 'Water'),
                    tr('${arNum(r.water)} كوب', '${arNum(r.water)} cups')),
              if (r.sleep != null)
                HistoryRow('😴', tr('نوم', 'Sleep'),
                    tr('${arNum(r.sleep!.round())} ساعة',
                        '${arNum(r.sleep!.round())}h')),
              if (r.steps > 0)
                HistoryRow('👟', tr('خطوات', 'Steps'), arNum(r.steps)),
              if (r.calories > 0)
                HistoryRow('🍽', tr('سعرات', 'Calories'),
                    tr('${arNum(r.calories)} سعر', '${arNum(r.calories)} kcal')),
              if (r.meals > 0)
                HistoryRow('🍴', tr('وجبات', 'Meals'), arNum(r.meals)),
              for (final mm in r.measurements)
                HistoryRow(emoji[mm.type] ?? '📊', mm.type, mm.display()),
            ];
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('لوحة الصحة', 'Health hub')),
          actions: [
            searchAction(context),
            IconButton(
              onPressed: _openHistory,
              tooltip: tr('سجل الصحة', 'Health history'),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  // ---- لقطة النهارده ----
                  Text(tr('لقطة النهارده', "Today's snapshot"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                    children: [
                      _metric('💧', tr('مياه', 'Water'),
                          tr('${arNum(_water)} كوب', '${arNum(_water)} cups'),
                          onTap: _addWaterCup),
                      _metric(
                          '😴',
                          tr('نوم', 'Sleep'),
                          _sleep == null
                              ? '—'
                              : tr('${arNum(_sleep!.round())} س',
                                  '${arNum(_sleep!.round())}h')),
                      _metric('👟', tr('خطوات', 'Steps'),
                          _steps == 0 ? '—' : arNum(_steps)),
                      _metric(
                          '🍽',
                          tr('سعرات', 'Calories'),
                          _eatenCalories == 0 ? '—' : arNum(_eatenCalories)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ---- آخر القياسات ----
                  Row(
                    children: [
                      Text(tr('آخر القياسات', 'Latest vitals'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _open(const ChartsScreen()),
                        child: Text(tr('الرسوم', 'Charts')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _vitalsStrip(),
                  const SizedBox(height: 20),
                  // ---- مداخل الصحة ----
                  Text(tr('كل حاجة صحية', 'All things health'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _navCard(
                    icon: Icons.fitness_center,
                    color: Colors.deepPurple,
                    title: tr('الجيم', 'Gym'),
                    subtitle: tr('برنامجك وجلساتك وأرقامك القياسية',
                        'Your program, sessions & PRs'),
                    onTap: () => _open(const GymScreen()),
                  ),
                  _navCard(
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.teal,
                    title: tr('التقدم البدني', 'Body progress'),
                    subtitle: tr('الوزن والمقاسات وصور التغيّر',
                        'Weight, measurements & photos'),
                    onTap: () => _open(const ProgressScreen()),
                  ),
                  _navCard(
                    icon: Icons.medical_information_outlined,
                    color: Colors.redAccent,
                    title: tr('الملف الطبي', 'Medical file'),
                    subtitle: _medicalCount == 0
                        ? tr('كشوفات وتحاليل وأشعة', 'Visits, labs & imaging')
                        : tr('${arNum(_medicalCount)} سجل',
                            '${arNum(_medicalCount)} records'),
                    onTap: () => _open(const MedicalScreen()),
                  ),
                  _navCard(
                    icon: Icons.medication_outlined,
                    color: Colors.orange,
                    title: tr('صيدلية البيت', 'Home pharmacy'),
                    subtitle: tr('أدويتك وتواريخ صلاحيتها',
                        'Your meds & expiry dates'),
                    badge: _pharmacyExpiring,
                    onTap: () => _open(const PharmacyScreen()),
                  ),
                  _navCard(
                    icon: Icons.fact_check_outlined,
                    color: Colors.indigo,
                    title: tr('التزام الدواء', 'Med adherence'),
                    subtitle: _adherence == null
                        ? tr('تابع تناولك للأدوية', 'Track your meds intake')
                        : tr('التزامك آخر أسبوع: ٪${arNum(_adherence!)}',
                            "This week's adherence: ${arNum(_adherence!)}%"),
                    onTap: () => _open(const MedsScreen()),
                  ),
                  _navCard(
                    icon: Icons.sick_outlined,
                    color: Colors.brown,
                    title: tr('مفكرة الأعراض', 'Symptom journal'),
                    subtitle: tr('سجّل أعراضك بشدّتها',
                        'Log symptoms with severity'),
                    onTap: () => _open(const SymptomJournalScreen()),
                  ),
                  _navCard(
                    icon: Icons.vaccines_outlined,
                    color: Colors.teal,
                    title: tr('سجل التطعيمات', 'Vaccinations'),
                    subtitle: _vaccineDue == 0
                        ? tr('سجّل تطعيماتك وجرعاتك الجاية',
                            'Log vaccines & next doses')
                        : tr('${arNum(_vaccineDue)} جرعة قربت',
                            '${arNum(_vaccineDue)} dose(s) due soon'),
                    onTap: () => _open(const VaccinationsScreen()),
                  ),
                  _navCard(
                    icon: Icons.restaurant_menu_outlined,
                    color: Colors.green,
                    title: tr('سجّل وجبة', 'Log a meal'),
                    subtitle: _mealsCount == 0
                        ? tr('اكتب أكلك وسعراته', 'Log food & calories')
                        : tr('${arNum(_mealsCount)} وجبة النهارده',
                            '${arNum(_mealsCount)} meals today'),
                    onTap: () async {
                      await showMealSheet(context);
                      if (mounted) await _load();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _metric(String emoji, String label, String value,
      {VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: TextStyle(fontSize: 11, color: scheme.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: inner),
      ),
    );
  }

  Future<void> _addWaterCup() async {
    HapticFeedback.selectionClick();
    await HealthRepo().addWater(dayKey(DateTime.now()), 1);
    if (mounted) await _load();
  }

  /// اتجاه التغيّر بين آخر قراءتين — سهم + لون (الأقل أخضر للضغط/السكر/الوزن).
  Widget _vitalsStrip() {
    final scheme = Theme.of(context).colorScheme;
    const emoji = {'ضغط': '🩸', 'سكر': '🍬', 'وزن': '⚖️', 'حرارة': '🌡'};
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          for (final t in kMeasurementTypes)
            _vitalCard(t, emoji[t] ?? '📊', scheme),
        ],
      ),
    );
  }

  Widget _vitalCard(String type, String emoji, ColorScheme scheme) {
    final list = _vitals[type] ?? const [];
    final latest = list.isNotEmpty ? list.first : null;
    final prev = list.length > 1 ? list[1] : null;

    Widget trend = const SizedBox.shrink();
    if (latest != null && prev != null && latest.value != prev.value) {
      final up = latest.value > prev.value;
      // للضغط/السكر/الوزن: النزول أحسن (أخضر). الحرارة نحايد.
      final good = type == 'حرارة' ? null : !up;
      final color = good == null
          ? scheme.outline
          : (good ? Colors.green : scheme.error);
      trend = Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14, color: color);
    }

    return GestureDetector(
      onTap: () => _openMeasurementSheet(type),
      child: Container(
        width: 104,
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(type,
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(latest == null ? '—' : latest.display(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 2),
                trend,
              ],
            ),
            Text(
                latest == null
                    ? tr('اضغط للتسجيل', 'Tap to log')
                    : arShortDate(DateTime.parse(latest.day)),
                style: TextStyle(fontSize: 10, color: scheme.outline)),
          ],
        ),
      ),
    );
  }

  /// شباك تسجيل قياس سريع لنوع محدّد — يعيد التحميل بعد الحفظ.
  Future<void> _openMeasurementSheet(String type) async {
    final v1 = TextEditingController();
    final v2 = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
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
                Icon(Icons.monitor_heart_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('تسجيل $type', 'Log $type'),
                    style: Theme.of(ctx).textTheme.titleMedium),
              ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: v1,
                      autofocus: true,
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
    );
    if (ok == true) {
      final a = parseNumber(v1.text);
      if (a != null) {
        await MeasurementsRepo().add(Measurement(
          day: dayKey(DateTime.now()),
          type: type,
          value: a,
          value2: type == 'ضغط' ? parseNumber(v2.text) : null,
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('اتسجّل القياس 📏', 'Measurement saved 📏'))));
          await _load();
        }
      }
    }
    v1.dispose();
    v2.dispose();
  }

  Widget _navCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(arNum(badge),
                    style: TextStyle(
                        color: scheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_left),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
