import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/db.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/measurements_repo.dart';
import '../../data/money_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// رسوم بيانية من بياناتك: نوم آخر ٣٠ يوم، مصاريف آخر ٦ شهور، الوزن.
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _loading = true;
  List<(int, double)> _sleep = [];
  List<(int, double)> _calories = [];
  List<(String, double)> _monthTotals = [];
  List<Measurement> _weights = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final db = await AppDb.instance;

    // النوم: آخر ٣٠ يوم (اليوم 0 = أقدم نقطة).
    final from = dateOnly(now).subtract(const Duration(days: 29));
    final sleepRows = await db.query('sleep_logs',
        where: 'day >= ?', whereArgs: [dayKey(from)]);
    final sleepBy = {
      for (final r in sleepRows)
        r['day'] as String: (r['hours'] as num).toDouble()
    };
    final sleep = <(int, double)>[];
    for (var i = 0; i < 30; i++) {
      final key = dayKey(from.add(Duration(days: i)));
      if (sleepBy.containsKey(key)) sleep.add((i, sleepBy[key]!));
    }

    // المصاريف: آخر ٦ شهور.
    final money = MoneyRepo();
    final monthTotals = <(String, double)>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final total = await money.totalForMonth(m.year, m.month);
      monthTotals.add((arMonth(m).split(' ').first, total));
    }

    // السعرات المحروقة: آخر ٣٠ يوم من fitness_logs.
    final calRows = await db.query('fitness_logs',
        where: 'day >= ?', whereArgs: [dayKey(from)]);
    final calBy = {
      for (final r in calRows)
        if (r['calories'] != null)
          r['day'] as String: (r['calories'] as num).toDouble()
    };
    final calories = <(int, double)>[];
    for (var i = 0; i < 30; i++) {
      final key = dayKey(from.add(Duration(days: i)));
      if (calBy.containsKey(key)) calories.add((i, calBy[key]!));
    }

    final weights =
        (await MeasurementsRepo().recent(limit: 60, type: 'وزن'))
            .reversed
            .toList();

    if (!mounted) return;
    setState(() {
      _sleep = sleep;
      _calories = calories;
      _monthTotals = monthTotals;
      _weights = weights;
      _loading = false;
    });
  }

  Future<void> _logWeight() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('سجل وزنك', 'Log your weight')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              InputDecoration(labelText: tr('الوزن (كجم)', 'Weight (kg)')),
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
      final value = parseNumber(controller.text);
      if (value != null && value > 20 && value < 400) {
        await MeasurementsRepo().add(Measurement(
          day: dayKey(DateTime.now()),
          type: 'وزن',
          value: value,
          unit: 'كجم',
        ));
        if (mounted) await _load();
      }
    }
    controller.dispose();
  }

  Widget _chartCard(BuildContext context, String title, Widget chart) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: chart),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('إحصائياتك', 'Charts')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (_sleep.length >= 3)
                  _chartCard(
                    context,
                    tr('النوم — آخر ٣٠ يوم (ساعات)', 'Sleep — last 30 days (hours)'),
                    LineChart(LineChartData(
                      minY: 0,
                      maxY: 12,
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (final (i, v) in _sleep)
                              FlSpot(i.toDouble(), v)
                          ],
                          isCurved: true,
                          color: scheme.primary,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    )),
                  )
                else
                  EmptyHint(
                      icon: Icons.bedtime_outlined,
                      text: tr('سجل نومك كام يوم وهترسملك منحناه هنا',
                          'Log sleep for a few days and its curve appears here')),
                if (_calories.length >= 3)
                  _chartCard(
                    context,
                    tr('السعرات المحروقة — آخر ٣٠ يوم',
                        'Calories burned — last 30 days'),
                    LineChart(LineChartData(
                      minY: 0,
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (final (i, v) in _calories)
                              FlSpot(i.toDouble(), v)
                          ],
                          isCurved: true,
                          color: Colors.deepOrange,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                if (_monthTotals.any((m) => m.$2 > 0))
                  _chartCard(
                    context,
                    tr('المصاريف — آخر ٦ شهور (ج.م)', 'Spending — last 6 months (EGP)'),
                    BarChart(BarChartData(
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _monthTotals[v.toInt()].$1,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < _monthTotals.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: _monthTotals[i].$2,
                              color: scheme.primary,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ]),
                      ],
                    )),
                  ),
                if (_weights.length >= 2)
                  _chartCard(
                    context,
                    tr('الوزن (كجم)', 'Weight (kg)'),
                    LineChart(LineChartData(
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < _weights.length; i++)
                              FlSpot(i.toDouble(), _weights[i].value)
                          ],
                          isCurved: false,
                          color: scheme.tertiary,
                        ),
                      ],
                    )),
                  )
                else
                  EmptyHint(
                      icon: Icons.monitor_weight_outlined,
                      text: _weights.length == 1
                          ? tr('سجل وزنك مرة كمان وهيبدأ المنحنى',
                              'Log your weight once more to start the curve')
                          : tr('سجل وزنك أول مرة من الزرار تحت\nأو قول للمايك «وزني ٩٥»',
                              'Log your weight with the button below\nor tell the mic "وزني ٩٥"')),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'weight_fab',
        onPressed: _logWeight,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: Text(tr('سجل وزنك', 'Log weight')),
      ),
    );
  }
}
