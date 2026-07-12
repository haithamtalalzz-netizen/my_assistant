import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/adhan_custom.dart';
import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/notifications.dart';
import '../../core/prayers.dart';
import '../../core/religion_data.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';
import 'adhkar_screen.dart';
import 'adhkar_situations_screen.dart';
import 'daily_wird_screen.dart';
import 'duas_screen.dart';
import 'fasting_screen.dart';
import 'hajj_umrah_screen.dart';
import 'hijri_age_screen.dart';
import 'islamic_occasions_screen.dart';
import 'khatma_screen.dart';
import 'mawarith_screen.dart';
import 'monthly_times_screen.dart';
import 'names_screen.dart';
import 'post_prayer_dhikr_screen.dart';
import 'quran_screen.dart';
import 'qibla_screen.dart';
import 'ruqyah_screen.dart';
import 'spiritual_stats_screen.dart';
import 'tasbih_screen.dart';
import 'zakat_screen.dart';

/// صفحة الصلاة والأذكار — مواعيد الصلاة + تتبّعها + بوصلة القبلة + أدوات دينية.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _repo = WorshipRepo();
  final _settings = SettingsRepo();
  PrayerDay? _prayers;
  PrayerDay? _tomorrow;
  String _place = '';
  Set<int> _prayed = {};
  Set<String> _sunnahDone = {};
  int _streak = 0;
  bool _adhan = false;
  String _customLabel = '';
  String? _customUri;
  String? _customChannel;
  bool _friday = true;
  bool _rawatib = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final gov = await resolvePlace(_settings);
    final now = DateTime.now();
    final prayed = await _repo.prayedToday();
    final sunnah = await _repo.sunnahDoneOn(now);
    final streak = await _repo.fullDaysStreak();
    final adhan = await _settings.adhanSoundEnabled();
    final customLabel = await _settings.adhanCustomLabel();
    final customUri = await _settings.adhanCustomUri();
    final customChannel = await _settings.adhanCustomChannel();
    final friday = await _settings.fridayReminderEnabled();
    final rawatib = await _settings.rawatibRemindersEnabled();
    if (!mounted) return;
    setState(() {
      _rawatib = rawatib;
      _place = gov.name;
      _prayers = prayerTimesFor(now, gov);
      _tomorrow = prayerTimesFor(now.add(const Duration(days: 1)), gov);
      _prayed = prayed;
      _sunnahDone = sunnah;
      _streak = streak;
      _adhan = adhan;
      _customLabel = customLabel;
      _customUri = customUri;
      _customChannel = customChannel;
      _friday = friday;
    });
  }

  Future<void> _previewSelected() async {
    await Notifications.showAdhanTest(uri: _customUri, channel: _customChannel);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('جارٍ تشغيل الأذان…', 'Playing the adhan…'))));
  }

  Future<void> _pickCustom() async {
    final label = await AdhanCustom.pickAndInstall();
    if (label == null) return;
    await PrayerScheduler.ensureScheduled();
    await _load();
    await Notifications.showAdhanTest(uri: _customUri, channel: _customChannel);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('تم اختيار: $label', 'Selected: $label'))));
  }

  Future<void> _toggleSunnah(String name) async {
    final has = _sunnahDone.contains(name);
    await _repo.toggleSunnah(DateTime.now(), name, !has);
    if (!mounted) return;
    setState(() => has ? _sunnahDone.remove(name) : _sunnahDone.add(name));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _togglePrayed(int i) async {
    final has = _prayed.contains(i);
    await _repo.togglePrayer(DateTime.now(), i, !has);
    final streak = await _repo.fullDaysStreak();
    if (!mounted) return;
    setState(() {
      has ? _prayed.remove(i) : _prayed.add(i);
      _streak = streak;
    });
  }

  String _hijri(DateTime now) {
    HijriCalendar.setLocal(AppState.isEnglish ? 'en' : 'ar');
    final h = HijriCalendar.fromDate(now);
    return tr('${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)}هـ',
        '${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)} AH');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('الصلاة والأذكار', 'Prayer & Adhkar')),
        actions: [
          IconButton(
            tooltip: tr('اتجاه القبلة', 'Qibla'),
            icon: const Icon(Icons.explore),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ],
      ),
      body: _prayers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _timesCard(now),
                const SizedBox(height: 16),
                _duaCard(now),
                const SizedBox(height: 12),
                _ayahHadithCard(now),
                const SizedBox(height: 16),
                _sunanCard(),
                const SizedBox(height: 16),
                Text(tr('أدوات دينية', 'Islamic tools'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _toolsGrid(),
                const SizedBox(height: 16),
                _reminderSettingsCard(),
              ],
            ),
    );
  }

  Widget _timesCard(DateTime now) {
    final p = _prayers!;
    var idx = p.nextIndex(now);
    var target = idx == null ? _tomorrow!.times[0] : p.times[idx];
    final isTomorrow = idx == null;
    idx ??= 0;
    final remain = target.difference(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C4677), Color(0xFF1A2942), Color(0xFF0C1423)],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text(_place, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text(_hijri(now),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isTomorrow
                  ? tr('صلاة ${prayerNameLabel(idx)} (بكرة)',
                      '${prayerNameLabel(idx)} (tomorrow)')
                  : tr('المتبقى على ${prayerNameLabel(idx)}',
                      'Time until ${prayerNameLabel(idx)}'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _fmtDur(remain),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            // الصلوات الخمس — كل واحدة معاها زر «صلّيت».
            for (var i = 0; i < kPrayerNames.length; i++) _prayerRow(i, idx),
            const SizedBox(height: 8),
            if (_streak > 0)
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    tr('${arNum(_streak)} يوم متتالى صلاة كاملة',
                        '${arNum(_streak)}-day full-prayer streak'),
                    style: const TextStyle(
                        color: Color(0xFFF3D06E), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _prayerRow(int i, int nextIdx) {
    final prayed = _prayed.contains(i);
    final isNext = i == nextIdx;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(prayerNameLabel(i),
                style: TextStyle(
                    color: isNext ? const Color(0xFF2FDE9B) : Colors.white,
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 15)),
          ),
          Text(arTime(_prayers!.times[i]),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          // زر «صلّيت».
          InkWell(
            onTap: () => _togglePrayed(i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: prayed
                    ? const Color(0xFF2FA36B)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(prayed ? Icons.check_circle : Icons.circle_outlined,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(prayed ? tr('صلّيت', 'Prayed') : tr('صلّيت؟', 'Pray?'),
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _duaCard(DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(tr('دعاء اليوم', "Today's du'a"),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(duaOfDay(now),
              style: const TextStyle(fontSize: 18, height: 1.9)),
        ],
      ),
    );
  }

  Widget _ayahHadithCard(DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(IconData icon, String title, String body) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 17, color: scheme.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      fontSize: 13.5)),
            ]),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 16.5, height: 1.9)),
          ],
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          block(Icons.book, tr('آية اليوم', 'Verse of the day'), ayahOfDay(now)),
          const Divider(height: 24),
          block(Icons.format_quote, tr('حديث اليوم', 'Hadith of the day'),
              hadithOfDay(now)),
        ],
      ),
    );
  }

  Widget _sunanCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(tr('سنن ونوافل اليوم', "Today's sunnah & nafl"),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                '${arNum(_sunnahDone.length)}/${arNum(kSunanItems.length)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in kSunanItems)
                FilterChip(
                  label: Text(s.name),
                  selected: _sunnahDone.contains(s.name),
                  showCheckmark: true,
                  tooltip: s.note.isEmpty ? null : s.note,
                  onSelected: (_) => _toggleSunnah(s.name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reminderSettingsCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: Text(tr('صوت الأذان مع التنبيه', 'Adhan sound with alerts')),
            subtitle: Text(
                tr('تنبيه صوتى قوى — اختر ملف أذان من جهازك ليصير أذانًا',
                    'A loud alert — pick your own adhan file to make it a real adhan'),
                style: const TextStyle(fontSize: 12)),
            value: _adhan,
            onChanged: (v) async {
              setState(() => _adhan = v);
              await _settings.setAdhanSound(v);
              await PrayerScheduler.ensureScheduled();
            },
          ),
          if (_adhan)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 16, end: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_customLabel.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.smartphone,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tr('صوت الأذان: $_customLabel',
                                'Adhan sound: $_customLabel'),
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      tr('لم تختر ملف أذان بعد — هيشتغل تنبيه صوتى قوى. اختر ملف أذان من جهازك ليصير أذانًا كاملًا.',
                          'No adhan file chosen yet — a loud alert plays. Pick an adhan file from your device to use a full adhan.'),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickCustom,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(_customLabel.isEmpty
                            ? tr('اختر أذان من جهازى', 'Pick adhan from device')
                            : tr('غيّر الملف', 'Change file')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewSelected,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(tr('جرّب الصوت', 'Test sound')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.mosque),
            title: Text(tr('تذكير الجمعة', 'Friday reminder')),
            subtitle: Text(
                tr('سورة الكهف + الصلاة على النبى ﷺ',
                    'Al-Kahf + salawat on the Prophet ﷺ'),
                style: const TextStyle(fontSize: 12)),
            value: _friday,
            onChanged: (v) async {
              setState(() => _friday = v);
              await _settings.setFridayReminder(v);
              await FridayReminder.ensureScheduled();
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.access_time),
            title: Text(tr('تذكير السنن الرواتب', 'Sunnah rawatib reminders')),
            subtitle: Text(
                tr('تذكير بركعتَى السنة بعد كل فرض',
                    'Reminder to pray the sunnah after each fard'),
                style: const TextStyle(fontSize: 12)),
            value: _rawatib,
            onChanged: (v) async {
              setState(() => _rawatib = v);
              await _settings.setRawatibReminders(v);
              await PrayerScheduler.ensureScheduled();
            },
          ),
        ],
      ),
    );
  }

  Widget _toolsGrid() {
    final tools = [
      _Tool(Icons.import_contacts, tr('المصحف', 'Quran'),
          const Color(0xFF1E7A5A), () => const MushafScreen()),
      _Tool(Icons.explore, tr('بوصلة القبلة', 'Qibla'), const Color(0xFF2E7D6B),
          () => const QiblaScreen()),
      _Tool(Icons.radio_button_checked, tr('المسبحة', 'Tasbih'),
          const Color(0xFF6A4C93), () => const TasbihScreen()),
      _Tool(Icons.wb_sunny, tr('أذكار الصباح', 'Morning adhkar'),
          const Color(0xFFCC8A2E), () => const AdhkarScreen(morning: true)),
      _Tool(Icons.nightlight_round, tr('أذكار المساء', 'Evening adhkar'),
          const Color(0xFF3C5A99), () => const AdhkarScreen(morning: false)),
      _Tool(Icons.star, tr('أسماء الله الحسنى', 'Names of Allah'),
          const Color(0xFF2FA36B), () => const NamesScreen()),
      _Tool(Icons.volunteer_activism, tr('أدعية مأثورة', 'Supplications'),
          const Color(0xFFB5654A), () => const DuasScreen()),
      _Tool(Icons.menu_book, tr('ختمة القرآن', 'Quran khatma'),
          const Color(0xFF1E7A5A), () => const KhatmaScreen()),
      _Tool(Icons.calendar_month, tr('مواقيت الشهر', 'Monthly times'),
          const Color(0xFF4A6FB5), () => const MonthlyTimesScreen()),
      _Tool(Icons.self_improvement, tr('أذكار بعد الصلاة', 'Post-prayer adhkar'),
          const Color(0xFF6A4C93), () => const PostPrayerDhikrScreen()),
      _Tool(Icons.wb_twilight, tr('الصيام', 'Fasting'),
          const Color(0xFFCC8A2E), () => const FastingScreen()),
      _Tool(Icons.insights, tr('إحصائيتك الروحية', 'Spiritual week'),
          const Color(0xFF3C5A99), () => const SpiritualStatsScreen()),
      _Tool(Icons.calculate, tr('حاسبة الزكاة', 'Zakat'),
          const Color(0xFF2E7D6B), () => const ZakatScreen()),
      _Tool(Icons.account_tree, tr('حاسبة المواريث', 'Inheritance'),
          const Color(0xFFB5654A), () => const MawarithScreen()),
      _Tool(Icons.event, tr('المناسبات الإسلامية', 'Islamic occasions'),
          const Color(0xFF1E7A5A), () => const IslamicOccasionsScreen()),
      _Tool(Icons.bedtime, tr('أذكار المواقف', 'Daily-life adhkar'),
          const Color(0xFF3C5A99), () => const AdhkarSituationsScreen()),
      _Tool(Icons.track_changes, tr('الوِرد اليومى', 'Daily wird'),
          const Color(0xFF2FA36B), () => const DailyWirdScreen()),
      _Tool(Icons.healing, tr('الرقية الشرعية', 'Ruqyah'),
          const Color(0xFF6A4C93), () => const RuqyahScreen()),
      _Tool(Icons.mosque, tr('العمرة والحج', 'Umrah & Hajj'),
          const Color(0xFFCC8A2E), () => const HajjUmrahScreen()),
      _Tool(Icons.cake, tr('عمرك بالهجرى', 'Hijri age'),
          const Color(0xFFB5654A), () => const HijriAgeScreen()),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) {
        final t = tools[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => t.build())),
          child: Container(
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.icon, size: 38, color: t.color),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(t.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDur(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return arNum('${two(h)}:${two(m)}:${two(s)}');
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function() build;
  _Tool(this.icon, this.label, this.color, this.build);
}
