import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../core/doctor_report.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/insights_repo.dart';
import '../../data/settings_repo.dart';
import 'charts_screen.dart';
import 'chat_screen.dart';

class InsightsScreen extends StatefulWidget {
  /// لو اتمرر الدرج الجانبي، الشاشة بتشتغل كبند رئيسي (همبرجر بدل سهم الرجوع).
  final Widget? drawer;

  const InsightsScreen({super.key, this.drawer});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _loading = true;
  List<Insight> _insights = [];
  bool _hasGeminiKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await InsightsRepo().assemble();
    final key = await SettingsRepo().get('gemini_key') ?? '';
    if (!mounted) return;
    setState(() {
      _insights = buildInsights(data);
      _hasGeminiKey = key.isNotEmpty;
      _loading = false;
    });
  }

  (IconData, Color) _style(BuildContext context, InsightKind kind) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      InsightKind.correlation => (Icons.insights, scheme.primary),
      InsightKind.pattern => (Icons.calendar_view_week, scheme.tertiary),
      InsightKind.trend => (Icons.trending_up, scheme.secondary),
      InsightKind.habit => (Icons.task_alt, scheme.tertiary),
      InsightKind.celebration => (Icons.local_fire_department, Colors.deepOrange),
      InsightKind.info => (Icons.hourglass_empty, scheme.outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('رؤى المدير', 'Insights')),
        actions: [
          searchAction(context),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChartsScreen())),
            tooltip: tr('إحصائياتك', 'Charts'),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr('بجهز تقرير الدكتور...',
                      'Preparing doctor report...'))));
              try {
                await DoctorReport.generateAndShare();
              } on Exception catch (e) {
                dev.log('فشل توليد التقرير', error: e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr('حصلت مشكلة في توليد التقرير',
                          'Failed to generate the report'))));
                }
              }
            },
            tooltip: tr('تقرير للدكتور (PDF)', 'Doctor report (PDF)'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Text(
                    tr('استنتاجات محسوبة محليًا من بياناتك — بتتحدث مع كل استخدام.',
                        'Insights computed locally from your data — updated each use.'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  for (final insight in _insights)
                    Builder(builder: (context) {
                      final (icon, color) = _style(context, insight.kind);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, color: color, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(insight.text,
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.6)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'chat_fab',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatScreen())),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(_hasGeminiKey
            ? tr('اسأل مديرك', 'Ask your manager')
            : tr('المحادثة (تفعيل)', 'Chat (set up)')),
      ),
    );
  }
}
