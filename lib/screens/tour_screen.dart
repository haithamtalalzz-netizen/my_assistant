import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/settings_repo.dart';

/// شريحة واحدة فى الجولة التعريفية.
class TourSlide {
  final IconData icon;
  final String title;
  final String body;
  const TourSlide(this.icon, this.title, this.body);
}

List<TourSlide> tourSlides() => [
      TourSlide(
        Icons.waving_hand_outlined,
        tr('أهلاً بيك فى مساعدي 👋', 'Welcome to My Assistant 👋'),
        tr(
            'ده مديرك الشخصى — بيلمّ حياتك كلها فى مكان واحد: مواعيدك وفلوسك وصحتك وعباداتك. كل بياناتك محفوظة على تليفونك بس، مفيش أى حاجة بتتبعت لأى سيرفر.',
            'Your personal manager — appointments, money, health & worship in one place. All your data stays on your phone; nothing is sent to any server.'),
      ),
      TourSlide(
        Icons.home_outlined,
        tr('الرئيسية', 'Home'),
        tr(
            'ملخّص يومك: الصلاة الجاية، مواعيدك، فواتيرك، ومهامك. تقدر تخفى أو تظهر أى كارت من الإعدادات، وتضيف بسرعة بأزرار الإضافة السريعة.',
            "Your day at a glance: next prayer, appointments, bills & tasks. Show/hide any card from settings, and add fast with quick-add buttons."),
      ),
      TourSlide(
        Icons.menu,
        tr('القايمة الجانبية', 'The sidebar'),
        tr(
            'اسحب من على اليمين (أو دوس ☰) تلاقى كل الأقسام: المواعيد · الفلوس · الصحة · الرياضة · النظام الغذائى · البيت · تطوّرى · الصلاة والأذكار وغيرهم.',
            'Swipe from the edge (or tap ☰) for all sections: Appointments · Money · Health · Fitness · Diet · Home · Growth · Prayer and more.'),
      ),
      TourSlide(
        Icons.notifications_active_outlined,
        tr('التذكيرات', 'Reminders'),
        tr(
            'التطبيق بيفكّرك بمواعيدك وأدويتك وفواتيرك ومستنداتك — كله بيتحسب على تليفونك. من الإشعار نفسه تقدر تقول «تم» أو «أجّل ساعة».',
            'Reminders for appointments, meds, bills & documents — all computed on your phone. From the notification itself: "Done" or "+1h".'),
      ),
      TourSlide(
        Icons.psychology_outlined,
        tr('اسأل مديرك', 'Ask your manager'),
        tr(
            'اسأله بالعربى عن أى حاجة فى بياناتك، ويقدر يرتّبلك يومك ويطلعلك رؤى («لاحظت إن نومك بيقلّ لما تصرف أكتر»). كل ده بيشتغل محلى.',
            'Ask in Arabic about your data, get your day planned, and receive insights ("your sleep drops when you spend more"). All runs locally.'),
      ),
      TourSlide(
        Icons.lock_outline,
        tr('خصوصيتك وبياناتك', 'Your privacy'),
        tr(
            'كل حاجة محلية ومجانية: تقدر تقفل التطبيق ببصمتك، تاخد نسخة احتياطية zip، أو تصدّر كل بياناتك Excel/CSV — من الإعدادات ← النسخ الاحتياطى.',
            'Local & free: lock the app with your fingerprint, take a zip backup, or export everything to Excel/CSV — Settings → Backup.'),
      ),
    ];

/// جولة تعريفية بتتعرض مرة واحدة أول تشغيل — وتتعاد من الإعدادات.
class TourScreen extends StatefulWidget {
  /// بيتنادى لما الجولة تخلص أو المستخدم يتخطاها.
  final VoidCallback onDone;

  const TourScreen({super.key, required this.onDone});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SettingsRepo().set('tour_seen', '1');
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slides = tourSlides();
    final last = _page == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(tr('تخطّى', 'Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 56, color: scheme.primary),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // نقط الصفحات.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _ctrl.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(last
                      ? tr('يلا نبدأ 🚀', "Let's go 🚀")
                      : tr('التالى', 'Next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
