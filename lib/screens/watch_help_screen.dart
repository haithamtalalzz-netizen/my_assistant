// «تنبيهاتك على الساعة» — الخطوات بالترتيب، ومين بيقطعها.
//
// الشاشة دى موجودة لإن السؤال «التنبيه مابيوصلش الساعة» إجابته مش فى
// التطبيق أصلاً: التطبيق بيبعت التنبيه صح، وسامسونج بتنوّمه. فبدل ما
// نقول «شوف إعدادات الموبايل»، هنا الخطوة بالظبط — وزرار بيبعت تنبيه
// حقيقى دلوقتى عشان تبصّ على الساعة وتعرف بنفسك.
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/notifications.dart';
import '../core/privacy.dart';
import '../widgets/a_kit.dart';

class WatchHelpScreen extends StatelessWidget {
  const WatchHelpScreen({super.key});

  static const int _testNotifId = 940003;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        actions: const [PrivacyAction()],
        title: Text(tr('تنبيهاتك على الساعة', 'Alerts on your watch')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _intro(scheme),
          const SizedBox(height: 18),
          AppGroupHead(tr('١ · على الساعة', '1 · On the watch')),
          _step(
            scheme,
            Icons.watch_outlined,
            tr('وصّل الساعة بتطبيقها على الموبايل',
                'Pair the watch with its phone app'),
            tr('هواوى: Huawei Health · شاومى: Mi Fitness · سامسونج: Galaxy Wearable',
                'Huawei Health · Mi Fitness · Galaxy Wearable'),
          ),
          _step(
            scheme,
            Icons.notifications_active_outlined,
            tr('افتح «الإشعارات» جوّه تطبيق الساعة',
                'Open "Notifications" inside the watch app'),
            tr('اديله صلاحية الوصول للإشعارات، وفعّل Vida من قائمة التطبيقات',
                'Grant notification access, then enable Vida in the app list'),
          ),
          const SizedBox(height: 14),
          AppGroupHead(tr('٢ · على سامسونج — دى اللى بتقطعها',
              '2 · On Samsung — this is what breaks it')),
          _step(
            scheme,
            Icons.battery_saver,
            tr('العناية بالجهاز ثم البطارية ثم حدود الاستخدام فى الخلفية',
                'Device care, Battery, Background usage limits'),
            tr('اتأكد إن Vida ليست فى «التطبيقات النائمة» ولا «النائمة بعمق»، '
                'وضيفها فى «التطبيقات غير المقيّدة»',
                'Make sure Vida is not in Sleeping / Deep sleeping apps, '
                'and add it to Never sleeping apps'),
            danger: true,
          ),
          _step(
            scheme,
            Icons.power_settings_new,
            tr('الإعدادات ثم التطبيقات ثم Vida ثم البطارية ثم «غير مقيَّد»',
                'Settings, Apps, Vida, Battery, Unrestricted'),
            tr('من غيرها سامسونج بتوقف التطبيق بعد كام ساعة من غير ما تحس',
                'Without this Samsung stops the app after a few hours, silently'),
            danger: true,
          ),
          _step(
            scheme,
            Icons.alarm,
            tr('الإعدادات ثم التطبيقات ثم Vida ثم «المنبّهات والتذكيرات»',
                'Settings, Apps, Vida, Alarms & reminders'),
            tr('لازم تكون مسموحة، وإلا التنبيه بيتأخّر عن ميعاده',
                'Must be allowed, otherwise reminders fire late'),
          ),
          _step(
            scheme,
            Icons.do_not_disturb_on_outlined,
            tr('«عدم الإزعاج» على الموبايل أو على الساعة',
                'Do Not Disturb — on the phone or the watch'),
            tr('لو شغّال بالليل، تذكير الدوا أو المزاج مش هيبان',
                'If it is on at night, the dose or mood reminder will not show'),
          ),
          const SizedBox(height: 14),
          AppGroupHead(tr('٣ · جرّب دلوقتى', '3 · Try it now')),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('ابعت تنبيه حقيقى دلوقتى وبصّ على الساعة. لو مابانش، '
                        'ارجع لخطوة ٢.',
                        'Send a real notification now and look at your watch. '
                        'If nothing shows, go back to step 2.'),
                    style: TextStyle(fontSize: 12.5, color: scheme.outline),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(tr('ابعت تنبيه تجربة', 'Send a test')),
                    onPressed: () async {
                      await Notifications.showNow(
                        id: _testNotifId,
                        title: tr('تجربة من Vida', 'Test from Vida'),
                        body: tr('لو شايف ده على الساعة يبقى تمام',
                            'If you see this on your watch, you are set'),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr('اتبعت — بصّ على الساعة',
                            'Sent — check your watch')),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppGroupHead(tr('حاجات مش هتشتغل — وعشان إيه',
              'What will not work — and why')),
          _limit(
            scheme,
            Icons.touch_app_outlined,
            tr('زراير التنبيه مش هتبان على ساعات هواوى وشاومى',
                'Action buttons will not show on Huawei / Xiaomi watches'),
            tr('الساعات دى بتعرض نصّ التنبيه بس. الزراير اللى جوّه التنبيه '
                '(وشوش المزاج · «تمّ» · «أجّل») بتشتغل على ساعات Wear OS. '
                'يعنى تشوف من الساعة وتعلّم من الموبايل.',
                'These watches mirror the text only. Action buttons work on '
                'Wear OS watches. So: read on the watch, tap on the phone.'),
          ),
          _limit(
            scheme,
            Icons.sync_problem_outlined,
            tr('خطوات ونوم ساعة هواوى مش بتوصل Vida',
                'Huawei watch steps & sleep do not reach Vida'),
            tr('Vida بتقرا من Health Connect، وتطبيق Huawei Health مش بيدعمه — '
                'هواوى بره منظومة جوجل. ساعات سامسونج وشاومى وجارمن بتوصل عادى.',
                'Vida reads Health Connect; Huawei Health does not support it. '
                'Samsung, Xiaomi and Garmin watches sync fine.'),
          ),
          _limit(
            scheme,
            Icons.phonelink_off,
            tr('التطبيق نفسه مايتركّبش على الساعة',
                'The app itself cannot be installed on the watch'),
            tr('ساعات هواوى بتشتغل بنظامها، فمحتاجة تطبيق مكتوب من أول وجديد '
                'بلغتها — مش نقل للموجود.',
                'Huawei watches run their own OS and need an app written from '
                'scratch for it.'),
          ),
        ],
      ),
    );
  }

  Widget _intro(ColorScheme scheme) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          tr('أى ساعة بتعرض إشعارات الموبايل هتعرض تنبيهات Vida — من غير '
              'أى تركيب ولا ربط جوّه التطبيق. اللى بيقطعها غالبًا مش Vida، '
              'ده الموبايل وهو بينوّمها.',
              'Any watch that mirrors phone notifications will show Vida\'s — '
              'nothing to install. What usually breaks it is the phone putting '
              'the app to sleep.'),
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      );

  Widget _step(ColorScheme scheme, IconData icon, String title, String sub,
          {bool danger = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (danger ? scheme.error : scheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon,
                size: 17, color: danger ? scheme.error : scheme.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, height: 1.35)),
              const SizedBox(height: 3),
              Text(sub,
                  style: TextStyle(
                      fontSize: 11.5, color: scheme.outline, height: 1.45)),
            ]),
          ),
        ]),
      );

  Widget _limit(ColorScheme scheme, IconData icon, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: scheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            height: 1.35)),
                    const SizedBox(height: 3),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.outline,
                            height: 1.5)),
                  ]),
            ),
          ]),
        ),
      );
}
