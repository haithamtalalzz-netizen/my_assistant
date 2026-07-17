import '../core/log.dart';

import 'package:flutter/material.dart';

import '../core/doctor_report.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../core/month_report.dart';
import 'brain/charts_screen.dart';
import 'brain/insights_screen.dart';
import 'reports/custom_pdf_screen.dart';

/// لوحة التقارير — مدخل واحد لكل أنواع التقارير والتحليلات.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التقارير', 'Reports')),
          actions: [searchAction(context)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _card(
            context,
            icon: Icons.bar_chart,
            color: Colors.blue,
            title: tr('إحصائياتك', 'Charts'),
            subtitle: tr('رسوم بيانية: نوم · مصروفات · وزن',
                'Graphs: sleep · spending · weight'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChartsScreen())),
          ),
          _card(
            context,
            icon: Icons.lightbulb_outline,
            color: Colors.amber,
            title: tr('رؤى المدير', 'Insights'),
            subtitle: tr('تحليلات وأنماط من بياناتك',
                'Patterns & correlations from your data'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InsightsScreen())),
          ),
          _card(
            context,
            icon: Icons.tune,
            color: Colors.indigo,
            title: tr('تقرير مخصّص (PDF)', 'Custom report (PDF)'),
            subtitle: tr('اختار البنود ومدى التاريخ + بانر ولوجو',
                'Pick sections & date range + banner/logo'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CustomPdfScreen())),
          ),
          _card(
            context,
            icon: Icons.picture_as_pdf_outlined,
            color: Colors.deepPurple,
            title: tr('ملخص الشهر (PDF)', 'Month summary (PDF)'),
            subtitle: tr('تقرير بكل أنشطة الشهر الحالي',
                "This month's full activity report"),
            onTap: () async {
              final now = DateTime.now();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr('بجهّز تقرير الشهر...',
                      'Preparing month report...'))));
              try {
                await MonthReport.generateAndShare(now.year, now.month);
              } on Exception catch (e) {
                logError('فشل تقرير الشهر', e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          tr('حصلت مشكلة', 'Something went wrong'))));
                }
              }
            },
          ),
          _card(
            context,
            icon: Icons.medical_information_outlined,
            color: Colors.redAccent,
            title: tr('تقرير الدكتور (PDF)', 'Doctor report (PDF)'),
            subtitle: tr('قياسات وأدوية وسجل طبي للطبيب',
                'Measurements, meds & medical history'),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr('بجهّز تقرير الدكتور...',
                      'Preparing doctor report...'))));
              try {
                await DoctorReport.generateAndShare();
              } on Exception catch (e) {
                logError('فشل تقرير الدكتور', e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          tr('حصلت مشكلة', 'Something went wrong'))));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
