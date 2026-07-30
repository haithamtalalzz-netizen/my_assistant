import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import 'adhkar_screen.dart';
import 'adhkar_situations_screen.dart';
import 'adhkar_reminders_screen.dart';
import 'daily_wird_screen.dart';
import 'post_prayer_dhikr_screen.dart';

/// كارت «الأذكار» الموحّد — يجمع كل أدوات الأذكار فى مكان واحد بدل ٦ كروت
/// منفصلة فى صفحة «صلاتى».
class AdhkarHubScreen extends StatelessWidget {
  const AdhkarHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_AdhkarItem>[
      _AdhkarItem(Icons.wb_sunny, tr('أذكار الصباح', 'Morning adhkar'),
          const Color(0xFFCC8A2E), () => const AdhkarScreen(morning: true)),
      _AdhkarItem(Icons.nightlight_round, tr('أذكار المساء', 'Evening adhkar'),
          const Color(0xFF3C5A99), () => const AdhkarScreen(morning: false)),
      _AdhkarItem(
          Icons.self_improvement,
          tr('أذكار بعد الصلاة', 'Post-prayer adhkar'),
          const Color(0xFF6A4C93),
          () => const PostPrayerDhikrScreen()),
      _AdhkarItem(Icons.bedtime, tr('أذكار المواقف', 'Daily-life adhkar'),
          const Color(0xFF2E7D6B), () => const AdhkarSituationsScreen()),
      _AdhkarItem(Icons.track_changes, tr('الوِرد اليومى', 'Daily wird'),
          const Color(0xFF2FA36B), () => const DailyWirdScreen()),
      _AdhkarItem(
          Icons.notifications_active,
          tr('تذكير الأذكار', 'Adhkar reminders'),
          const Color(0xFFB5654A),
          () => const AdhkarRemindersScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr('الأذكار', 'Adhkar'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          childAspectRatio: 1.15,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => it.build())),
            child: Container(
              decoration: BoxDecoration(
                color: it.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: it.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, size: 38, color: it.color),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(it.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdhkarItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function() build;
  _AdhkarItem(this.icon, this.label, this.color, this.build);
}
