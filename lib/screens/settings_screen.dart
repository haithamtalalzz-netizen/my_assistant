import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/backup.dart';
import '../core/db.dart';
import '../core/evening.dart';
import '../core/health_service.dart';
import '../core/home_sections.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../core/prayers.dart';
import '../core/seed_demo.dart';
import '../core/theme.dart';
import '../core/widget_bridge.dart';
import '../data/settings_repo.dart';
import '../widgets/common.dart';
import '../widgets/location_fields.dart';
import 'quick_actions_settings_screen.dart';

const List<String> kBloodTypes = [
  '', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsRepo();
  final _auth = LocalAuthentication();
  final _name = TextEditingController();
  final _budget = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _geminiKey = TextEditingController();
  bool _geminiSendHealth = true;
  int _waterGoal = 8;
  bool _appLock = false;
  bool _prayerNotifs = true;
  bool _healthSync = false;
  bool _ramadan = false;
  bool _hardDay = false;
  bool _travel = false;
  bool _eveningSummary = true;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 30);
  String _blood = '';
  String _governorate = 'القاهرة';
  String? _customLoc; // مدينة عالمية مخصّصة (null = محافظة)
  Set<String> _hiddenHome = {}; // عناصر الرئيسية المخفية
  String _notifMode = 'both';
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _settings.userName();
    final goal = await _settings.waterGoal();
    final budget = await _settings.monthlyBudget();
    final appLock = await _settings.appLockEnabled();
    final prayerNotifs = await _settings.prayerNotificationsEnabled();
    final healthSync = await _settings.healthSyncEnabled();
    final governorate = await _settings.governorateName();
    final customLoc = await _settings.customLocation();
    final hiddenHome = await _settings.hiddenHomeSections();
    final ramadan = await _settings.ramadanMode();
    final hardDay = await _settings.hardDayMode();
    final travel = await _settings.travelMode();
    final eveningSummary = await _settings.eveningSummaryEnabled();
    final eveningTimeParts = (await _settings.eveningTime()).split(':');
    final blood = await _settings.get('emergency_blood') ?? '';
    final allergies = await _settings.get('emergency_allergies') ?? '';
    final conditions = await _settings.get('emergency_conditions') ?? '';
    final contactName = await _settings.get('emergency_contact_name') ?? '';
    final contactPhone = await _settings.get('emergency_contact_phone') ?? '';
    final geminiKey = await _settings.get('gemini_key') ?? '';
    final geminiSendHealth = await _settings.get('gemini_send_health') != '0';
    final notifMode = await _settings.get('notif_mode') ?? 'both';
    if (!mounted) return;
    setState(() {
      _notifMode = notifMode;
      _name.text = name;
      _waterGoal = goal;
      _budget.text = budget > 0 ? budget.toStringAsFixed(0) : '';
      _appLock = appLock;
      _prayerNotifs = prayerNotifs;
      _healthSync = healthSync;
      _governorate = governorate;
      _customLoc = customLoc?.label;
      _hiddenHome = hiddenHome;
      _ramadan = ramadan;
      _hardDay = hardDay;
      _travel = travel;
      _eveningSummary = eveningSummary;
      _eveningTime = TimeOfDay(
        hour: int.tryParse(eveningTimeParts[0]) ?? 21,
        minute: eveningTimeParts.length > 1
            ? int.tryParse(eveningTimeParts[1]) ?? 30
            : 30,
      );
      _blood = kBloodTypes.contains(blood) ? blood : '';
      _allergies.text = allergies;
      _conditions.text = conditions;
      _contactName.text = contactName;
      _contactPhone.text = contactPhone;
      _geminiKey.text = geminiKey;
      _geminiSendHealth = geminiSendHealth;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _geminiKey.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    await _settings.set('user_name', _name.text.trim());
    await _settings.set('water_goal', '$_waterGoal');
    final budget = parseNumber(_budget.text);
    await _settings.set(
        'monthly_budget', budget == null || budget <= 0 ? '' : '$budget');
    await _settings.set('governorate', _governorate);
    await _settings.set('prayer_notifications', _prayerNotifs ? '1' : '0');
    await _settings.set('ramadan_mode', _ramadan ? '1' : '0');
    await _settings.set('hard_day_mode', _hardDay ? '1' : '0');
    await _settings.set('travel_mode', _travel ? '1' : '0');
    await _settings.set('evening_summary', _eveningSummary ? '1' : '0');
    await _settings.set('evening_time',
        '${_eveningTime.hour.toString().padLeft(2, '0')}:${_eveningTime.minute.toString().padLeft(2, '0')}');
    await _settings.set('emergency_blood', _blood);
    await _settings.set('emergency_allergies', _allergies.text.trim());
    await _settings.set('emergency_conditions', _conditions.text.trim());
    await _settings.set('emergency_contact_name', _contactName.text.trim());
    await _settings.set('emergency_contact_phone', _contactPhone.text.trim());
    await _settings.set('gemini_key', _geminiKey.text.trim());
    await _settings.set('gemini_send_health', _geminiSendHealth ? '1' : '0');
    await PrayerScheduler.ensureScheduled();
    await EveningScheduler.ensureScheduled();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _toggleHealthSync(bool enable) async {
    if (!enable) {
      await _settings.set('health_sync', '0');
      if (mounted) setState(() => _healthSync = false);
      return;
    }
    if (!await HealthService.available()) {
      _toast(tr('Health Connect مش متاح — اتأكد إنه متسطب ومحدّث من المتجر',
          'Health Connect unavailable — install/update it from the store'));
      return;
    }
    final granted = await HealthService.requestPermissions();
    if (!granted) {
      _toast(tr('محتاج إذن قراءة بيانات الساعة عشان المزامنة تشتغل',
          'Health read permission is needed for sync'));
      return;
    }
    await _settings.set('health_sync', '1');
    if (mounted) setState(() => _healthSync = true);
    _toast(tr('المزامنة اتفعّلت — بيانات ساعتك هتظهر في شاشة اليوم',
        'Sync on — your watch data will show on Today'));
  }

  /// تفعيل أو إلغاء القفل بيتطلب بصمة ناجحة الأول — في الحالتين.
  Future<void> _toggleAppLock(bool enable) async {
    try {
      if (!await _auth.isDeviceSupported()) {
        _toast(tr('الجهاز ده مافيهوش بصمة أو قفل شاشة مفعّل',
            'This device has no fingerprint or screen lock set'));
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: enable
            ? tr('أكد هويتك لتفعيل القفل', 'Confirm identity to enable lock')
            : tr('أكد هويتك لإلغاء القفل', 'Confirm identity to disable lock'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!ok) return;
      await _settings.set('app_lock', enable ? '1' : '0');
      if (mounted) setState(() => _appLock = enable);
      _toast(enable
          ? tr('القفل بالبصمة اتفعّل', 'Biometric lock enabled')
          : tr('القفل اتلغى', 'Lock disabled'));
    } on PlatformException catch (e) {
      dev.log('فشل تغيير حالة القفل', error: e);
      _toast(tr('حصلت مشكلة في البصمة — جرب تاني',
          'Biometric error — try again'));
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await BackupService.exportBackup();
    } on Exception catch (e) {
      dev.log('فشل تصدير النسخة الاحتياطية', error: e);
      _toast(tr('حصلت مشكلة أثناء التصدير', 'Export failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final sure = await confirmAction(
      context,
      title: tr('استعادة نسخة احتياطية', 'Restore backup'),
      message: tr(
          'الاستعادة هتستبدل كل البيانات الحالية بالكامل ببيانات النسخة. متأكد؟',
          'Restore will fully replace all current data with the backup. Sure?'),
      confirmLabel: tr('استعادة', 'Restore'),
    );
    if (!sure) return;
    setState(() => _busy = true);
    try {
      final done = await BackupService.restoreBackup();
      if (done) {
        _toast(tr('تمت الاستعادة بنجاح', 'Restored successfully'));
        if (mounted) Navigator.pop(context, true);
      }
    } on FormatException catch (e) {
      _toast(e.message);
    } on Exception catch (e) {
      dev.log('فشلت الاستعادة', error: e);
      _toast(tr('حصلت مشكلة أثناء الاستعادة', 'Restore failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _languageControl(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(tr('اللغة', 'Language'))),
        DropdownButton<String>(
          value: AppState.locale.value.languageCode,
          items: const [
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) {
            if (v != null) AppState.setLanguage(v);
          },
        ),
      ],
    );
  }

  Widget _themeControl(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.brightness_6_outlined,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(tr('المظهر', 'Theme'))),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto, size: 18),
                tooltip: tr('حسب النظام', 'System')),
            ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode, size: 18),
                tooltip: tr('فاتح', 'Light')),
            ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode, size: 18),
                tooltip: tr('غامق', 'Dark')),
          ],
          selected: {AppState.themeMode.value},
          onSelectionChanged: (s) => AppState.setThemeMode(s.first),
        ),
      ],
    );
  }

  Future<void> _openQuickActionsSettings() async {
    final saved = await SettingsRepo().get('quick_actions');
    final order = (saved == null || saved.trim().isEmpty)
        ? kDefaultQuickActions
        : saved.split(',').where((e) => e.isNotEmpty).toList();
    if (!mounted) return;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuickActionsSettingsScreen(
          all: [
            for (final e in quickActionCatalog())
              (key: e.key, icon: e.icon, label: e.label)
          ],
          enabledOrder: order,
        ),
      ),
    );
    if (result != null) {
      await SettingsRepo().set('quick_actions', result.join(','));
    }
  }

  Widget _accentControl(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- لون الهوية ----
        Row(children: [
          Icon(Icons.palette_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Text(tr('لون الهوية', 'Accent color'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: AppState.accentKey,
          builder: (context, current, _) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in kAccentPresets.entries)
                _colorSwatch(
                  color: entry.value.primary,
                  label: entry.value.label,
                  selected: current == entry.key,
                  onTap: () => AppState.setAccent(entry.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // ---- لون الخلفية (الوضع الغامق) ----
        Row(children: [
          Icon(Icons.format_paint_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tr('لون الخلفية (الوضع الغامق)', 'Background (dark mode)'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: AppState.bgKey,
          builder: (context, current, _) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in kBgPresets.entries)
                _colorSwatch(
                  color: entry.value.bg,
                  label: entry.value.label,
                  selected: current == entry.key,
                  onTap: () => AppState.setBg(entry.key),
                  ring: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorSwatch({
    required Color color,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool ring = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : (ring ? scheme.outlineVariant : Colors.transparent),
              width: selected ? 3 : 1.5,
            ),
          ),
          child: selected
              ? Icon(Icons.check,
                  size: 17,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('الإعدادات', 'Settings'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionHeader(tr('المظهر واللغة', 'Appearance & language')),
                _languageControl(context),
                const SizedBox(height: 12),
                _themeControl(context),
                const SizedBox(height: 12),
                _accentControl(context),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: Text(tr('خصّص الأزرار السريعة', 'Customize quick actions')),
                  subtitle: Text(tr('اختار اللي يظهر في الرئيسية وترتيبه',
                      'Pick what shows on Today & its order')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _openQuickActionsSettings,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration:
                      InputDecoration(labelText: tr('اسمك', 'Your name')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: Text(tr('هدف المياه اليومي (كوباية)',
                            'Daily water goal (glasses)'))),
                    DropdownButton<int>(
                      value: _waterGoal,
                      items: [
                        for (var i = 4; i <= 15; i++)
                          DropdownMenuItem(value: i, child: Text(arNum(i))),
                      ],
                      onChanged: (v) =>
                          setState(() => _waterGoal = v ?? _waterGoal),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _budget,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: tr('ميزانية الشهر (ج.م) — سيبها فاضية لو مش عايز',
                          'Monthly budget (EGP) — leave empty to skip')),
                ),
                SectionHeader(tr('الموقع والصلاة', 'Location & prayer')),
                if (_customLoc != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.place,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                              '${tr('موقعك الحالي', 'Current location')}: $_customLoc',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                LocationFields(
                  initialCityLabel: _customLoc,
                  onPicked: (place) async {
                    await _settings.setCustomLocation(
                        place.lat, place.lng, place.label);
                    if (mounted) setState(() => _customLoc = place.label);
                    unawaited(PrayerScheduler.ensureScheduled());
                    unawaited(WidgetBridge.push());
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('إشعارات الأذان', 'Adhan notifications')),
                  subtitle: Text(tr('تنبيه عند كل صلاة بحساب فلكي محلي',
                      'Alert at each prayer via local astronomical calc')),
                  value: _prayerNotifs,
                  onChanged: (v) => setState(() => _prayerNotifs = v),
                ),
                SectionHeader(tr('الصفحة الرئيسية', 'Home screen')),
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: Text(tr('إظهار وإخفاء عناصر الرئيسية',
                        'Show / hide home sections')),
                    subtitle: Text(
                        tr('اختار اللي يظهر — كل عنصر لوحده',
                            'Pick what shows — each independently'),
                        style: const TextStyle(fontSize: 12)),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final key in kHomeSectionKeys)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(homeSectionLabel(key)),
                          value: !_hiddenHome.contains(key),
                          onChanged: (show) async {
                            await _settings.setHomeSectionHidden(key, !show);
                            setState(() {
                              if (show) {
                                _hiddenHome.remove(key);
                              } else {
                                _hiddenHome.add(key);
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                SectionHeader(tr('الإشعارات', 'Notifications')),
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tr('صوت واهتزاز', 'Sound & vibration'))),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: 'sound',
                            icon: const Icon(Icons.volume_up, size: 18),
                            tooltip: tr('صوت', 'Sound')),
                        ButtonSegment(
                            value: 'vibration',
                            icon: const Icon(Icons.vibration, size: 18),
                            tooltip: tr('اهتزاز', 'Vibration')),
                        ButtonSegment(
                            value: 'both',
                            icon: const Icon(Icons.notifications_active,
                                size: 18),
                            tooltip: tr('الاثنين', 'Both')),
                      ],
                      selected: {_notifMode},
                      onSelectionChanged: (s) async {
                        final mode = s.first;
                        setState(() => _notifMode = mode);
                        await _settings.set('notif_mode', mode);
                        await Notifications.applyChannelMode(mode);
                      },
                    ),
                  ],
                ),
                SectionHeader(tr('الصحة', 'Health')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      tr('مزامنة الساعة الذكية', 'Sync smartwatch')),
                  subtitle: Text(tr(
                      'خطوات ونوم وسعرات ونبض ومسافة تلقائيًا من أي ساعة عبر Health Connect',
                      'Steps, sleep, calories, heart rate & distance — auto from any watch via Health Connect')),
                  value: _healthSync,
                  onChanged: _toggleHealthSync,
                ),
                SectionHeader(tr('الأوضاع', 'Modes')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('وضع رمضان', 'Ramadan mode')),
                  subtitle: Text(tr(
                      'وجبات سحور وفطار + تلميحات مياه من الفطار للسحور',
                      'Suhoor/iftar meals + water hints from iftar to suhoor')),
                  value: _ramadan,
                  onChanged: (v) => setState(() => _ramadan = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('وضع «يوم صعب»', 'Hard-day mode')),
                  subtitle: Text(tr(
                      'يهدّي التطبيق ويخفي الضغط والمهام — خليك مرتاح النهارده',
                      'Softens the app & hides pressure — take it easy today')),
                  value: _hardDay,
                  onChanged: (v) => setState(() => _hardDay = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('وضع السفر', 'Travel mode')),
                  subtitle: Text(tr(
                      'يوقف تذكيرات الروتين (تمرين/مياه/سلاسل) مؤقتًا',
                      'Pauses routine reminders (workout/water/streaks)')),
                  value: _travel,
                  onChanged: (v) => setState(() => _travel = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('ملخص بكرة المسائي', 'Evening tomorrow summary')),
                  subtitle: Text(tr("إشعار كل ليلة بمواعيد وتمرين بكرة",
                      "Nightly notice of tomorrow's appointments & workout")),
                  value: _eveningSummary,
                  onChanged: (v) => setState(() => _eveningSummary = v),
                ),
                if (_eveningSummary)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('وقت الملخص المسائي', 'Evening summary time')),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: _eveningTime);
                        if (picked != null) {
                          setState(() => _eveningTime = picked);
                        }
                      },
                      child: Text(arTime(DateTime(2000, 1, 1,
                          _eveningTime.hour, _eveningTime.minute))),
                    ),
                  ),
                SectionHeader(tr('كارت الطوارئ', 'Emergency card')),
                DropdownButtonFormField<String>(
                  initialValue: _blood,
                  decoration:
                      InputDecoration(labelText: tr('فصيلة الدم', 'Blood type')),
                  items: [
                    for (final b in kBloodTypes)
                      DropdownMenuItem(
                          value: b,
                          child: Text(
                              b.isEmpty ? tr('غير محددة', 'Not set') : b)),
                  ],
                  onChanged: (v) => setState(() => _blood = v ?? _blood),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _allergies,
                  decoration: InputDecoration(
                      labelText:
                          tr('حساسيات (أدوية أو أكل)', 'Allergies (meds/food)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _conditions,
                  decoration: InputDecoration(
                      labelText: tr('أمراض مزمنة', 'Chronic conditions')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contactName,
                        decoration: InputDecoration(
                            labelText:
                                tr('شخص للطوارئ', 'Emergency contact')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _contactPhone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: tr('رقمه', 'Phone')),
                      ),
                    ),
                  ],
                ),
                SectionHeader(
                    tr('محادثة المدير (Gemini — مجاني)', 'Chat (Gemini — free)')),
                TextField(
                  controller: _geminiKey,
                  decoration: InputDecoration(
                      labelText: tr(
                          'مفتاح Gemini (من aistudio.google.com — ببلاش)',
                          'Gemini key (from aistudio.google.com — free)')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('مشاركة بيانات الصحة في المحادثة',
                      'Share health data in chat')),
                  subtitle: Text(tr(
                      'لو اتقفلت: الأدوية والنوم والقياسات مش هيتبعتوا مع أسئلتك',
                      'If off: meds, sleep & measurements are not sent')),
                  value: _geminiSendHealth,
                  onChanged: (v) => setState(() => _geminiSendHealth = v),
                ),
                SectionHeader(tr('الأمان', 'Security')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('قفل التطبيق بالبصمة', 'Biometric app lock')),
                  subtitle: Text(tr(
                      'يتطلب بصمة عند الفتح وبعد غياب دقيقة — كارت الطوارئ بيفضل متاح من غير قفل',
                      'Fingerprint on open & after 1 min away — emergency card stays unlocked')),
                  value: _appLock,
                  onChanged: _toggleAppLock,
                ),
                SectionHeader(tr('النسخ الاحتياطي', 'Backup')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: Text(tr('تصدير نسخة احتياطية', 'Export backup')),
                  subtitle: Text(tr('ملف واحد فيه كل بياناتك وصور مستنداتك',
                      'One file with all your data & document images')),
                  onTap: _busy ? null : _export,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_backup_restore),
                  title: Text(tr('استعادة نسخة احتياطية', 'Restore backup')),
                  subtitle: Text(tr('هتستبدل البيانات الحالية بالكامل',
                      'Replaces all current data')),
                  onTap: _busy ? null : _restore,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(tr('شارك آخر نسخة تلقائية',
                      'Share latest auto-backup')),
                  subtitle: Text(tr('بتتعمل نسخة أسبوعيًا لوحدها — بنحتفظ بآخر ٤',
                      'Weekly auto-backup — last 4 kept')),
                  onTap: _busy
                      ? null
                      : () async {
                          final file = await AutoBackup.latest();
                          if (file == null) {
                            _toast(tr(
                                'لسه مفيش نسخ تلقائية — أول نسخة بتتعمل مع أول فتحة بعد أسبوع',
                                'No auto-backup yet — first one is made a week after first open'));
                            return;
                          }
                          await Share.shareXFiles([XFile(file.path)],
                              text: 'My Assistant backup');
                        },
                ),
                SectionHeader(tr('للمطوّرين', 'Developer')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science_outlined),
                  title:
                      Text(tr('إضافة بيانات وهمية', 'Add demo data')),
                  subtitle: Text(tr(
                      'بيملأ كل البنود ببيانات تجريبية عشان تجرّب التطبيق',
                      'Fills every section with sample data to try the app')),
                  onTap: _busy ? null : _seedDemo,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_sweep_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(tr('مسح كل البيانات', 'Clear all data')),
                  subtitle: Text(tr(
                      'بيمسح كل بياناتك ويبقى التطبيق فاضي (الثيم واللغة بيفضلوا)',
                      'Deletes all your data; keeps theme & language')),
                  onTap: _busy ? null : () => _wipe(keepAccount: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_off_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(
                      tr('مسح الحساب والبدء من جديد', 'Reset account')),
                  subtitle: Text(tr(
                      'بيمسح كل البيانات + الاسم والإعدادات ويرجّع التطبيق للبداية',
                      'Deletes everything incl. name & settings — fresh start')),
                  onTap: _busy ? null : () => _wipe(keepAccount: false),
                ),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(tr('حفظ', 'Save'))),
              ],
            ),
    );
  }

  Future<void> _seedDemo() async {
    setState(() => _busy = true);
    try {
      final count = await seedDemoData();
      if (!mounted) return;
      _toast(tr('اتضافت $count عنصر تجريبي — اقفل وافتح التطبيق',
          'Added $count demo items — restart the app'));
    } on Exception catch (e) {
      dev.log('فشل توليد البيانات التجريبية', error: e);
      if (mounted) _toast(tr('حصلت مشكلة', 'Something went wrong'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wipe({required bool keepAccount}) async {
    final sure = await confirmAction(
      context,
      title: keepAccount
          ? tr('مسح كل البيانات', 'Clear all data')
          : tr('مسح الحساب', 'Reset account'),
      message: keepAccount
          ? tr('متأكد؟ كل بياناتك هتتمسح نهائيًا ومش هتقدر ترجّعها.',
              'Sure? All your data will be permanently deleted.')
          : tr('متأكد؟ كل حاجة هتتمسح والتطبيق هيرجع للبداية.',
              'Sure? Everything will be erased and the app resets.'),
      confirmLabel: tr('امسح', 'Delete'),
    );
    if (!sure) return;
    setState(() => _busy = true);
    try {
      await Notifications.cancelAll();
      await AppDb.wipeAllData(keepSettings: keepAccount);
      if (!keepAccount) await AppState.load();
      if (mounted) {
        _toast(tr('اتمسح — اقفل وافتح التطبيق', 'Done — restart the app'));
      }
    } on Exception catch (e) {
      dev.log('فشل المسح', error: e);
      if (mounted) _toast(tr('حصلت مشكلة', 'Something went wrong'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
