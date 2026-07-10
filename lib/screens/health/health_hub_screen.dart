import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/health_repo.dart';
import '../../data/meals_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/medical_repo.dart';
import '../../data/pharmacy_repo.dart';
import '../food/meal_sheet.dart';
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
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('لوحة الصحة', 'Health hub')),
          actions: [searchAction(context)]),
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
                          tr('${arNum(_water)} كوب', '${arNum(_water)} cups')),
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

  Widget _metric(String emoji, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
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
      ),
    );
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
