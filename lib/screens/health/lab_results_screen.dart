import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/lab_results_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/wheel_date_picker.dart';

/// مؤشرات التحاليل الطبية — تتبّع نتائج التحاليل واتجاهها عبر الزمن.
class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({super.key});

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

Color _statusColor(int status, ColorScheme scheme) => switch (status) {
      < 0 => Colors.orange,
      > 0 => scheme.error,
      _ => Colors.green,
    };

String _statusLabel(int status) => switch (status) {
      < 0 => tr('تحت الطبيعى', 'Below range'),
      > 0 => tr('فوق الطبيعى', 'Above range'),
      _ => tr('طبيعى', 'Normal'),
    };

class _LabResultsScreenState extends State<LabResultsScreen> {
  final _repo = LabResultsRepo();
  bool _loading = true;
  List<LabResult> _latest = [];
  LabMonthSummary? _month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final latest = await _repo.latestPerName();
    final month = await _repo.monthSummary();
    if (!mounted) return;
    setState(() {
      _latest = latest;
      _month = month;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('مؤشرات التحاليل', 'Lab results'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _latest.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.biotech_outlined,
                          text: tr(
                              'سجّل نتائج تحاليلك — وهرسملك اتجاهها وأنبّهك لو خرجت عن الطبيعى',
                              'Log your lab results — trend charts & out-of-range alerts')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [
                        if (_month != null && !_month!.isEmpty)
                          _monthCard(context, _month!),
                        for (final r in _latest) _tile(r, scheme),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('نتيجة جديدة', 'New result'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ملخّص الشهر — بيقول اللى اتغيّر، مش بس أرقام.
  Widget _monthCard(BuildContext context, LabMonthSummary m) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🗓', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    tr('ملخّص ${arMonth(DateTime.now())}',
                        'Summary — ${arMonth(DateTime.now())}'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text(
                tr('${arNum(m.logged)} تحليل', '${arNum(m.logged)} results'),
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ]),
            const SizedBox(height: 6),
            if (m.outOfRange > 0)
              _sumLine('⚠️',
                  tr('${arNum(m.outOfRange)} خارج النطاق الطبيعى',
                      '${arNum(m.outOfRange)} out of range'),
                  scheme.error)
            else
              _sumLine('✓', tr('كلها داخل النطاق الطبيعى', 'All in range'),
                  Colors.green),
            if (m.improved.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sumLine('📈',
                  tr('اتحسّن: ${m.improved.join('، ')}',
                      'Improved: ${m.improved.join(', ')}'),
                  Colors.green),
            ],
            if (m.worsened.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sumLine('📉',
                  tr('خرج عن النطاق: ${m.worsened.join('، ')}',
                      'Went out of range: ${m.worsened.join(', ')}'),
                  scheme.error),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sumLine(String emoji, String text, Color color) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ),
      ]);

  Widget _tile(LabResult r, ColorScheme scheme) {
    final color = _statusColor(r.status, scheme);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(r.outOfRange ? Icons.warning_amber : Icons.check,
              color: color),
        ),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (r.dateTime != null) arShortDate(r.dateTime!),
          _statusLabel(r.status),
        ].join('  •  '),
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: Text(
          '${arNum(_fmt(r.value))}${r.unit.isEmpty ? '' : ' ${r.unit}'}',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: color),
        ),
        onTap: () => _openDetail(r.name),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  Future<void> _openDetail(String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _LabDetailScreen(name: name, repo: _repo)),
    );
    if (mounted) await _load();
  }

  Future<void> _form([LabResult? item, String? presetName]) async {
    final name = TextEditingController(text: item?.name ?? presetName ?? '');
    final value = TextEditingController(
        text: item == null ? '' : _fmt(item.value));
    final unit = TextEditingController(text: item?.unit ?? '');
    final low = TextEditingController(text: item?.refLow ?? '');
    final high = TextEditingController(text: item?.refHigh ?? '');
    final notes = TextEditingController(text: item?.notes ?? '');
    DateTime date = item?.dateTime ?? DateTime.now();

    void applySpec(LabTestSpec s) {
      name.text = s.name;
      if (unit.text.trim().isEmpty) unit.text = s.unit;
      if (low.text.trim().isEmpty) low.text = s.low;
      if (high.text.trim().isEmpty) high.text = s.high;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(item == null
              ? tr('نتيجة تحليل جديدة', 'New lab result')
              : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: name,
                  autofocus: item == null,
                  decoration:
                      InputDecoration(labelText: tr('اسم التحليل', 'Test name'))),
              const SizedBox(height: 6),
              // اقتراحات سريعة تملى الوحدة والنطاق.
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in kCommonLabTests)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ActionChip(
                          label: Text(s.name,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () => setD(() => applySpec(s)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: value,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          InputDecoration(labelText: tr('القيمة', 'Value'))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                      controller: unit,
                      decoration:
                          InputDecoration(labelText: tr('الوحدة', 'Unit'))),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: low,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                          labelText: tr('أدنى طبيعى', 'Ref low'))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                      controller: high,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                          labelText: tr('أعلى طبيعى', 'Ref high'))),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: Text(tr('التاريخ: ${arShortDate(date)}',
                        'Date: ${arShortDate(date)}'))),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('غيّر', 'Change')),
                  onPressed: () async {
                    final d = await pickWheelDate(
                      context,
                      initial: date,
                      first: DateTime(2010),
                      last: DateTime.now(),
                    );
                    if (d != null) setD(() => date = d);
                  },
                ),
              ]),
              TextField(
                  controller: notes,
                  decoration: InputDecoration(labelText: tr('ملاحظة', 'Note'))),
            ],
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
      ),
    );

    final v = parseNumber(value.text);
    if (saved == true && name.text.trim().isNotEmpty && v != null) {
      await _repo.save(LabResult(
        id: item?.id,
        name: name.text.trim(),
        value: v,
        unit: unit.text.trim(),
        date: dayKey(date),
        refLow: (parseNumber(low.text)?.toString()) ?? '',
        refHigh: (parseNumber(high.text)?.toString()) ?? '',
        notes: notes.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    for (final c in [name, value, unit, low, high, notes]) {
      c.dispose();
    }
  }
}

/// صفحة تفاصيل تحليل واحد: منحنى القيم عبر الزمن + شريط النطاق + السجل.
class _LabDetailScreen extends StatefulWidget {
  final String name;
  final LabResultsRepo repo;
  const _LabDetailScreen({required this.name, required this.repo});

  @override
  State<_LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<_LabDetailScreen> {
  List<LabResult> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.repo.forName(widget.name);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_rows.length >= 2) _chart(scheme) else _needMore(),
                const SizedBox(height: 16),
                Text(tr('السجل', 'History'),
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final r in _rows.reversed) _historyRow(r, scheme),
              ],
            ),
    );
  }

  Widget _needMore() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            tr('سجّل قراءتين على الأقل عشان يظهر المنحنى',
                'Log at least two readings to see the trend'),
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );

  Widget _chart(ColorScheme scheme) {
    final vals = [for (final r in _rows) r.value];
    final low = _rows.last.low, high = _rows.last.high;
    final dataMin = vals.reduce((a, b) => a < b ? a : b);
    final dataMax = vals.reduce((a, b) => a > b ? a : b);
    var minY = dataMin, maxY = dataMax;
    if (low != null && low < minY) minY = low;
    if (high != null && high > maxY) maxY = high;
    final pad = (maxY - minY).abs() * 0.15 + 1;
    minY -= pad;
    maxY += pad;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Text(
                tr('الاتجاه (${arNum(_rows.length)} قراءة)',
                    'Trend (${arNum(_rows.length)} readings)'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                minY: minY,
                maxY: maxY,
                titlesData: const FlTitlesData(
                  show: true,
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 36)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                // شريط النطاق الطبيعى كخطوط أفقية.
                extraLinesData: ExtraLinesData(horizontalLines: [
                  if (low != null)
                    HorizontalLine(
                        y: low,
                        color: Colors.green.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [6, 4]),
                  if (high != null)
                    HorizontalLine(
                        y: high,
                        color: scheme.error.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [6, 4]),
                ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final (i, v) in vals.indexed)
                        FlSpot(i.toDouble(), v)
                    ],
                    isCurved: false,
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              if (low != null)
                _legend(Colors.green,
                    tr('أدنى ${arNum(_fmtD(low))}', 'Low ${arNum(_fmtD(low))}')),
              if (high != null)
                _legend(scheme.error,
                    tr('أعلى ${arNum(_fmtD(high))}', 'High ${arNum(_fmtD(high))}')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 3, color: c),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _historyRow(LabResult r, ColorScheme scheme) {
    final color = _statusColor(r.status, scheme);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Text(
        '${arNum(_fmtD(r.value))}${r.unit.isEmpty ? '' : ' ${r.unit}'}',
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: r.notes.isEmpty ? null : Text(r.notes),
      trailing: Text(r.dateTime == null ? r.date : arShortDate(r.dateTime!)),
    );
  }

  static String _fmtD(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
