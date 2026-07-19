import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/fx_rate.dart';
import '../../core/l10n.dart';

/// «سعر الدولار» — سعر USD/EGP عبر Frankfurter (مجانى بدون مفتاح)، بيتكاش يوميًا.
class FxRateScreen extends StatefulWidget {
  const FxRateScreen({super.key});

  @override
  State<FxRateScreen> createState() => _FxRateScreenState();
}

class _FxRateScreenState extends State<FxRateScreen> {
  double? _rate;
  String? _date;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _rate = await FxRate.cached();
    _date = await FxRate.cachedDate();
    if (mounted) setState(() => _loading = false);
    await _refresh(); // يحدّث فى الخلفية
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _refreshing = true);
    final r = await FxRate.latest();
    final d = await FxRate.cachedDate();
    if (!mounted) return;
    setState(() {
      _rate = r;
      _date = d;
      _refreshing = false;
    });
  }

  String _dateText() {
    if (_date == null) return '';
    final d = DateTime.tryParse(_date!);
    return d != null ? arShortDate(d) : _date!;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('سعر الدولار', 'Dollar rate')),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _refresh,
            tooltip: tr('تحديث', 'Refresh'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💵', style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 16),
                    if (_rate == null)
                      Text(
                        tr('السعر مش متوفر — اتأكد من النت وجرّب تحديث.',
                            'Rate unavailable — check your connection and refresh.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      )
                    else ...[
                      Text(tr('الدولار الأمريكى', 'US Dollar'),
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text(
                        '${arNum(_rate!.toStringAsFixed(2))} ${tr('ج.م', 'EGP')}',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(tr('لكل ١ دولار', 'per 1 USD'),
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      if (_date != null) ...[
                        const SizedBox(height: 18),
                        Text('${tr('آخر تحديث', 'Updated')}: ${_dateText()}',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Text(tr('المصدر: Frankfurter (مجانى)', 'Source: Frankfurter'),
                        style: TextStyle(
                            fontSize: 11, color: scheme.outline)),
                  ],
                ),
              ),
            ),
    );
  }
}
