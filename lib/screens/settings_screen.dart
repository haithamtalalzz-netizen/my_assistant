import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import '../core/log.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/ar.dart';
import '../core/backup.dart';
import '../core/file_out.dart';
import '../core/json_backup.dart';
import '../core/data_export.dart';
import '../core/proactive_insight.dart';
import 'tour_screen.dart';
import '../core/db.dart';
import '../core/evening.dart';
import '../core/health_service.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../core/prayers.dart';
import '../core/seed_demo.dart';
import '../core/theme.dart';
import '../core/widget_bridge.dart';
import '../data/settings_repo.dart';
import '../widgets/common.dart';
import '../widgets/location_fields.dart';
import 'diagnostics_screen.dart';
import 'archived_data_screen.dart';
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
  int _waterGoalMl = 2000;
  bool _appLock = false;
  bool _prayerNotifs = true;
  bool _healthSync = false;
  bool _ramadan = false;
  bool _hardDay = false;
  bool _travel = false;
  bool _eveningSummary = true;
  bool _proactive = true;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 30);
  String _blood = '';
  String _governorate = 'القاهرة';
  String? _customLoc; // مدينة عالمية مخصّصة (null = محافظة)
  String _notifMode = 'both';
  bool _loading = true;
  bool _busy = false;
  String? _openCat; // الفئة المفتوحة حاليًا (null = القائمة الرئيسية)
  String _catQuery = ''; // بحث في قائمة الإعدادات
  List<String> _catOrder = []; // ترتيب فئات الإعدادات (بالسحب)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _settings.userName();
    final goalMl = await _settings.waterGoalMl();
    final budget = await _settings.monthlyBudget();
    final appLock = await _settings.appLockEnabled();
    final prayerNotifs = await _settings.prayerNotificationsEnabled();
    final healthSync = await _settings.healthSyncEnabled();
    final governorate = await _settings.governorateName();
    final customLoc = await _settings.customLocation();
    final ramadan = await _settings.ramadanMode();
    final hardDay = await _settings.hardDayMode();
    final travel = await _settings.travelMode();
    final eveningSummary = await _settings.eveningSummaryEnabled();
    final proactive = await _settings.proactiveInsightEnabled();
    final eveningTimeParts = (await _settings.eveningTime()).split(':');
    final blood = await _settings.get('emergency_blood') ?? '';
    final allergies = await _settings.get('emergency_allergies') ?? '';
    final conditions = await _settings.get('emergency_conditions') ?? '';
    final contactName = await _settings.get('emergency_contact_name') ?? '';
    final contactPhone = await _settings.get('emergency_contact_phone') ?? '';
    final geminiKey = await _settings.get('gemini_key') ?? '';
    final geminiSendHealth = await _settings.get('gemini_send_health') != '0';
    final notifMode = await _settings.get('notif_mode') ?? 'both';
    final catOrder = await _settings.get('settings_order') ?? '';
    if (!mounted) return;
    setState(() {
      _notifMode = notifMode;
      _catOrder =
          catOrder.split(',').where((e) => e.isNotEmpty).toList();
      _name.text = name;
      _waterGoalMl = goalMl;
      _budget.text = budget > 0 ? budget.toStringAsFixed(0) : '';
      _appLock = appLock;
      _prayerNotifs = prayerNotifs;
      _healthSync = healthSync;
      _governorate = governorate;
      _customLoc = customLoc?.label;
      _ramadan = ramadan;
      _hardDay = hardDay;
      _travel = travel;
      _eveningSummary = eveningSummary;
      _proactive = proactive;
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

  /// يحفظ الحقول المجمّعة — بيتنادى عند الرجوع من أي صفحة فئة.
  Future<void> _persist() async {
    await _settings.set('user_name', _name.text.trim());
    await _settings.setWaterGoalMl(_waterGoalMl);
    final budget = parseNumber(_budget.text);
    await _settings.set(
        'monthly_budget', budget == null || budget <= 0 ? '' : '$budget');
    await _settings.set('governorate', _governorate);
    await _settings.set('prayer_notifications', _prayerNotifs ? '1' : '0');
    await _settings.set('ramadan_mode', _ramadan ? '1' : '0');
    await _settings.set('hard_day_mode', _hardDay ? '1' : '0');
    await _settings.set('travel_mode', _travel ? '1' : '0');
    await _settings.set('evening_summary', _eveningSummary ? '1' : '0');
    await _settings.set('proactive_insight', _proactive ? '1' : '0');
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
    await ProactiveInsight.ensureScheduled();
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
      logError('فشل تغيير حالة القفل', e);
      _toast(tr('حصلت مشكلة في البصمة — جرب تاني',
          'Biometric error — try again'));
    }
  }


  /// نسخة JSON — **الوحيدة اللى بتشتغل على الويب** (SQL خالص من غير ملفات).
  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final json = await JsonBackup.exportAll();
      final n = JsonBackup.rowCountOf(json);
      await deliverFile(
          'my_assistant_${dayKey(DateTime.now())}.json',
          'application/json',
          utf8.encode(json));
      _toast(tr('اتصدّر ${arNum(n)} سجل', 'Exported ${arNum(n)} records'));
    } on Exception catch (e, st) {
      logError('فشل تصدير JSON', e, st);
      _toast(tr('حصلت مشكلة أثناء التصدير', 'Export failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreJson() async {
    if (_busy) return;
    // بنقرا الملف الأول ونقول للمستخدم فيه كام سجل قبل ما يأكّد.
    final picked = await FilePicker.pickFiles(withData: true);
    if (picked == null) return;
    final f = picked.files.single;
    String? content;
    try {
      if (f.bytes != null) {
        content = utf8.decode(f.bytes!); // الويب بيدّى bytes مش path
      } else if (f.path != null) {
        content = await File(f.path!).readAsString();
      }
    } on Exception catch (e) {
      logError('فشلت قراءة ملف الاستعادة', e);
    }
    if (content == null) {
      _toast(tr('مقدرتش أقرا الملف', "Couldn't read the file"));
      return;
    }
    final n = JsonBackup.rowCountOf(content);
    if (!mounted) return;
    final sure = await confirmAction(
      context,
      title: tr('استعادة من JSON', 'Restore from JSON'),
      message: tr(
          'هيتم استبدال بيانات الأقسام اللى فى الملف (${arNum(n)} سجل). متأكد؟',
          'Sections present in the file will be replaced (${arNum(n)} records). Sure?'),
      confirmLabel: tr('استعادة', 'Restore'),
    );
    if (!sure) return;
    setState(() => _busy = true);
    try {
      final done = await JsonBackup.importAll(content);
      _toast(tr('اترجّع ${arNum(done)} سجل', 'Restored ${arNum(done)} records'));
      if (mounted) Navigator.pop(context, true);
    } on FormatException catch (e) {
      _toast(e.message);
    } on Exception catch (e, st) {
      logError('فشلت استعادة JSON', e, st);
      _toast(tr('حصلت مشكلة أثناء الاستعادة', 'Restore failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await BackupService.exportBackup();
    } on Exception catch (e) {
      logError('فشل تصدير النسخة الاحتياطية', e);
      _toast(tr('حصلت مشكلة أثناء التصدير', 'Export failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// إعادة عرض الجولة التعريفية (بتقفل نفسها لما تخلص).
  Future<void> _replayTour() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => TourScreen(onDone: () => Navigator.pop(ctx)),
      ),
    );
  }

  Future<void> _exportData() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final n = await DataExport.exportAll();
      _toast(tr('اتصدّر ${arNum(n)} قسم كملفات CSV',
          'Exported ${arNum(n)} sections as CSV'));
    } on Exception catch (e) {
      logError('فشل تصدير كل البيانات', e);
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
      logError('فشلت الاستعادة', e);
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

  Widget _scheduleControl(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary:
              Icon(Icons.nightlight_outlined, color: scheme.primary),
          title: Text(tr('وضع ليلي مجدول', 'Scheduled dark mode')),
          subtitle: Text(tr('يتحوّل غامق/فاتح تلقائيًا فى وقت تحدده',
              'Auto dark/light at your chosen times')),
          value: AppState.scheduleEnabled,
          onChanged: (v) async {
            await AppState.setSchedule(enabled: v);
            if (mounted) setState(() {});
          },
        ),
        if (AppState.scheduleEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: tr('يبدأ الغامق', 'Dark from'),
                    value: AppState.darkFrom,
                    onPick: (t) async {
                      await AppState.setSchedule(from: t);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeField(
                    label: tr('يرجع فاتح', 'Light from'),
                    value: AppState.darkTo,
                    onPick: (t) async {
                      await AppState.setSchedule(to: t);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required Future<void> Function(String) onPick,
  }) {
    final parts = value.split(':');
    final tod = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      onPressed: () async {
        final picked = await showTimePicker(context: context, initialTime: tod);
        if (picked == null) return;
        final hm =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        await onPick(hm);
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // بند ألوان الهوية — الألوان جواه.
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(tr('ألوان الهوية', 'Accent colors')),
            shape: const Border(),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
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
            ],
          ),
        ),
        // بند ألوان الخلفية — الغامق + الفاتح مدموجين جواه.
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            leading: const Icon(Icons.format_paint_outlined),
            title: Text(tr('ألوان الخلفية', 'Background colors')),
            shape: const Border(),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _bgSubLabel(context, Icons.dark_mode_outlined,
                  tr('الوضع الغامق', 'Dark mode')),
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
              const SizedBox(height: 18),
              _bgSubLabel(context, Icons.light_mode_outlined,
                  tr('الوضع الفاتح', 'Light mode')),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: AppState.bgLightKey,
                builder: (context, current, _) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final entry in kLightBgPresets.entries)
                      _colorSwatch(
                        color: entry.value.bg,
                        label: entry.value.label,
                        selected: current == entry.key,
                        onTap: () => AppState.setBgLight(entry.key),
                        ring: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bgSubLabel(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 18, color: scheme.primary),
      const SizedBox(width: 8),
      Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: scheme.outline)),
    ]);
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

  // فئات الإعدادات (بالترتيب) — كل واحدة تفتح صفحتها. kw = كلمات بحث إضافية.
  List<({String key, String title, IconData icon, String? sub, String kw})>
      _categories() => [
            (key: 'appearance', title: tr('المظهر واللغة', 'Appearance & language'), icon: Icons.palette_outlined, sub: tr('اللغة والثيم والألوان', 'Language, theme & colors'), kw: 'لغة عربي انجليزي ثيم غامق فاتح لون الوان مظهر theme dark light color'),
            (key: 'general', title: tr('عام', 'General'), icon: Icons.tune, sub: tr('المياه والميزانية', 'Water & budget'), kw: 'مياه ماء هدف ميزانية فلوس water budget'),
            (key: 'location', title: tr('الموقع والصلاة', 'Location & prayer'), icon: Icons.place_outlined, sub: tr('مدينتك وإشعارات الأذان', 'City & adhan alerts'), kw: 'موقع مدينة دولة صلاة اذان طقس location city prayer adhan weather'),
            (key: 'notifications', title: tr('الإشعارات', 'Notifications'), icon: Icons.notifications_active_outlined, sub: tr('صوت واهتزاز', 'Sound & vibration'), kw: 'اشعار صوت اهتزاز تنبيه notification sound vibration'),
            (key: 'health', title: tr('الصحة', 'Health'), icon: Icons.favorite_outline, sub: tr('مزامنة الساعة الذكية', 'Smartwatch sync'), kw: 'صحة ساعة خطوات نوم مزامنة health watch steps'),
            (key: 'modes', title: tr('الأوضاع', 'Modes'), icon: Icons.toggle_on_outlined, sub: tr('رمضان / يوم صعب / سفر', 'Ramadan / hard-day / travel'), kw: 'رمضان سفر يوم صعب ملخص ramadan travel'),
            (key: 'emergency', title: tr('كارت الطوارئ', 'Emergency card'), icon: Icons.medical_services_outlined, sub: tr('بيانات طبية للطوارئ', 'Emergency medical info'), kw: 'طوارئ دم حساسية امراض جهة اتصال emergency blood'),
            (key: 'chat', title: tr('محادثة المدير', 'Manager chat'), icon: Icons.psychology_outlined, sub: tr('Gemini — مجاني', 'Gemini — free'), kw: 'محادثة ذكاء gemini chat مفتاح key'),
            (key: 'security', title: tr('الأمان', 'Security'), icon: Icons.lock_outline, sub: tr('قفل بالبصمة', 'Biometric lock'), kw: 'امان قفل بصمة security lock fingerprint'),
            (key: 'backup', title: tr('النسخ الاحتياطي', 'Backup'), icon: Icons.backup_outlined, sub: tr('تصدير واستعادة', 'Export & restore'), kw: 'نسخة احتياطية تصدير استعادة backup export restore'),
            (key: 'developer', title: tr('متقدّم', 'Advanced'), icon: Icons.build_outlined, sub: tr('أدوات متقدمة (بيانات تجريبية / مسح)', 'Advanced tools (demo data / reset)'), kw: 'متقدم مطور تجريبي مسح حذف developer advanced reset'),
          ];

  String _catTitle(String key) =>
      _categories().firstWhere((c) => c.key == key).title;

  /// الفئات بعد الفلترة بالبحث.
  List<({String key, String title, IconData icon, String? sub, String kw})>
      _filteredCategories() {
    final q = _catQuery.trim().toLowerCase();
    if (q.isEmpty) return _categories();
    return _categories()
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.sub ?? '').toLowerCase().contains(q) ||
            c.kw.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _backToHub() async {
    await _persist();
    if (mounted) setState(() => _openCat = null);
  }

  /// الفئات بالترتيب المحفوظ (السحب) — أي فئة جديدة تروح الآخر.
  List<({String key, String title, IconData icon, String? sub, String kw})>
      _orderedCategories() {
    final all = _categories();
    final byKey = {for (final c in all) c.key: c};
    final result =
        <({String key, String title, IconData icon, String? sub, String kw})>[];
    for (final k in _catOrder) {
      final c = byKey[k];
      if (c != null) result.add(c);
    }
    for (final c in all) {
      if (!_catOrder.contains(c.key)) result.add(c);
    }
    return result;
  }

  // onReorderItem: newIndex بيكون مضبوط بالفعل (من غير طرح 1).
  void _reorderCats(int oldIndex, int newIndex) {
    final keys = _orderedCategories().map((c) => c.key).toList();
    final k = keys.removeAt(oldIndex);
    keys.insert(newIndex, k);
    setState(() => _catOrder = keys);
    _settings.set('settings_order', keys.join(','));
  }

  Widget _catTile(
      ({String key, String title, IconData icon, String? sub, String kw}) c,
      {int? index}) {
    return ListTile(
      key: ValueKey(c.key),
      leading: Icon(c.icon),
      title: Text(c.title),
      subtitle: c.sub == null
          ? null
          : Text(c.sub!, style: const TextStyle(fontSize: 12)),
      trailing: index != null
          ? ReorderableDragStartListener(
              index: index, child: const Icon(Icons.drag_handle))
          : const Icon(Icons.chevron_left),
      onTap: () => setState(() => _openCat = c.key),
    );
  }

  Widget _hubBody() {
    final scheme = Theme.of(context).colorScheme;
    final searching = _catQuery.trim().isNotEmpty;
    final filtered = _filteredCategories();
    final ordered = _orderedCategories();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: TextField(
            onChanged: (v) => setState(() => _catQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr('ابحث في الإعدادات', 'Search settings'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: searching
              ? (filtered.isEmpty
                  ? Center(
                      child: Text(tr('مفيش نتيجة', 'No match'),
                          style: TextStyle(color: scheme.outline)))
                  : ListView(children: [for (final c in filtered) _catTile(c)]))
              : ReorderableListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  onReorderItem: _reorderCats,
                  children: [
                    for (var i = 0; i < ordered.length; i++)
                      _catTile(ordered[i], index: i),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _resetSettings() async {
    final sure = await confirmAction(
      context,
      title: tr('إعادة ضبط الإعدادات', 'Reset settings'),
      message: tr(
          'هترجع كل الإعدادات (الثيم والألوان والإشعارات والأوضاع وترتيب الفئات...) للافتراضي. بياناتك (المواعيد/الفلوس/إلخ) مش هتتمس.',
          'All settings (theme, colors, notifications, modes, order...) return to default. Your data is kept.'),
      confirmLabel: tr('إعادة ضبط', 'Reset'),
    );
    if (!sure) return;
    await AppState.setThemeMode(ThemeMode.dark);
    await AppState.setAccent('mint');
    await AppState.setBg('midnight');
    await AppState.setBgLight('paper');
    await _settings.set('home_hidden', '');
    await _settings.set('settings_order', '');
    await _settings.set('ramadan_mode', '0');
    await _settings.set('hard_day_mode', '0');
    await _settings.set('travel_mode', '0');
    await _settings.set('notif_mode', 'both');
    await _settings.set('prayer_notifications', '1');
    await _settings.set('evening_summary', '1');
    await Notifications.applyChannelMode('both');
    await _load();
    if (mounted) {
      setState(() {
        _openCat = null;
        _catQuery = '';
      });
    }
    _toast(tr('اترجعت الإعدادات للافتراضي ✓', 'Settings reset to default ✓'));
  }

  @override
  Widget build(BuildContext context) {
    final inCat = _openCat != null;
    return PopScope(
      canPop: !inCat,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && inCat) await _backToHub();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(inCat ? _catTitle(_openCat!) : tr('الإعدادات', 'Settings')),
          leading: inCat
              ? IconButton(
                  icon: const BackButtonIcon(), onPressed: _backToHub)
              : null,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _openCat == null
                ? _hubBody()
                : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                if (_openCat == 'appearance') ...[
                _languageControl(context),
                const SizedBox(height: 12),
                _themeControl(context),
                const SizedBox(height: 8),
                _scheduleControl(context),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.slideshow_outlined),
                  title: Text(tr('شوف الجولة التعريفية', 'Replay the tour')),
                  subtitle: Text(tr('جولة سريعة على أقسام التطبيق',
                      'A quick tour of the app sections')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _replayTour,
                ),
                ],
                if (_openCat == 'general') ...[
                // الاسم اتنقل لصفحة «حسابي» في السايدبار (من فوق).
                Row(
                  children: [
                    Expanded(
                        child: Text(tr('هدف المياه اليومي',
                            'Daily water goal'))),
                    DropdownButton<int>(
                      value: const [1000, 1500, 2000, 2500, 3000, 3500, 4000]
                              .contains(_waterGoalMl)
                          ? _waterGoalMl
                          : 2000,
                      items: [
                        for (final ml in const [
                          1000, 1500, 2000, 2500, 3000, 3500, 4000
                        ])
                          DropdownMenuItem(
                              value: ml,
                              child: Text(tr(
                                  '${arNum((ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1))} لتر ($ml مل)',
                                  '${arNum((ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1))} L ($ml mL)'))),
                      ],
                      onChanged: (v) =>
                          setState(() => _waterGoalMl = v ?? _waterGoalMl),
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
                ],
                if (_openCat == 'location') ...[
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
                ],
                if (_openCat == 'notifications') ...[
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
                ],
                if (_openCat == 'health') ...[
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
                ],
                if (_openCat == 'modes') ...[
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('رؤية استباقية من المدير',
                      'Proactive manager insight')),
                  subtitle: Text(tr(
                      'إشعار الصبح «مديرك لاحظ إن…» بأهم ملاحظة من تحليل بياناتك',
                      "Morning notice: your manager's top insight from your data")),
                  value: _proactive,
                  onChanged: (v) => setState(() => _proactive = v),
                ),
                ],
                if (_openCat == 'emergency') ...[
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
                ],
                if (_openCat == 'chat') ...[
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
                ],
                if (_openCat == 'security') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('قفل التطبيق بالبصمة', 'Biometric app lock')),
                  subtitle: Text(tr(
                      'يتطلب بصمة عند الفتح وبعد غياب دقيقة — كارت الطوارئ بيفضل متاح من غير قفل',
                      'Fingerprint on open & after 1 min away — emergency card stays unlocked')),
                  value: _appLock,
                  onChanged: _toggleAppLock,
                ),
                ],
                if (_openCat == 'backup') ...[
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
                const Divider(height: 20),
                // نسخة JSON — الوحيدة اللى بتشتغل فى المتصفح كمان.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.data_object),
                  title: Text(tr('تصدير نسخة JSON', 'Export JSON backup')),
                  subtitle: Text(tr(
                      kIsWeb
                          ? 'كل بياناتك فى ملف واحد — بينزّل على جهازك'
                          : 'كل بياناتك فى ملف واحد (من غير الصور) — يشتغل على الويب كمان',
                      'All your data in one file (no images)')),
                  onTap: _busy ? null : _exportJson,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(tr('استعادة من JSON', 'Restore from JSON')),
                  subtitle: Text(tr(
                      'بيستبدل الأقسام اللى فى الملف بس — الباقى زى ما هو',
                      'Replaces only the sections present in the file')),
                  onTap: _busy ? null : _restoreJson,
                ),
                const Divider(height: 20),
                if (!kIsWeb) ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(tr('تصدير كل البيانات (Excel/CSV)',
                      'Export all data (Excel/CSV)')),
                  subtitle: Text(tr(
                      'ملف zip فيه CSV لكل قسم — يفتح فى Excel (للأرشفة/القراءة)',
                      'A zip with a CSV per section — opens in Excel (archive/read)')),
                  onTap: _busy ? null : _exportData,
                ),
                if (!kIsWeb) ListTile(
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
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(tr('استرجاع البيانات المؤرشفة',
                      'Recover archived data')),
                  subtitle: Text(tr(
                      'بنود اتشالت من التطبيق — بياناتها محفوظة وتقدر تصدّرها',
                      'Removed sections — their data is kept and can be exported')),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ArchivedDataScreen())),
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(tr('شارك التشخيص', 'Share diagnostics')),
                  subtitle: Text(tr(
                      'سجل الأخطاء المحلى — شوفه قبل ما تشاركه، مافيهوش بياناتك',
                      'Local error log — review it before sharing, no personal data')),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiagnosticsScreen())),
                ),
                ],
                if (_openCat == 'developer') ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt),
                  title: Text(
                      tr('إعادة ضبط الإعدادات للافتراضي', 'Reset settings to default')),
                  subtitle: Text(tr(
                      'الثيم والألوان والإشعارات والأوضاع والترتيب — من غير مسح بياناتك',
                      'Theme, colors, notifications, modes & order — your data is kept')),
                  onTap: _busy ? null : _resetSettings,
                ),
                const Divider(),
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
                  leading: const Icon(Icons.restart_alt),
                  title: Text(tr('مسح وإضافة بيانات وهمية من جديد',
                      'Reset & re-add demo data')),
                  subtitle: Text(tr(
                      'بيمسح البيانات الحالية الأول وبعدين يملأ من جديد — من غير تكرار',
                      'Wipes current data first, then fills fresh — no duplicates')),
                  onTap: _busy ? null : _reseedDemo,
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
                ],
              ],
            ),
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
      logError('فشل توليد البيانات التجريبية', e);
      if (mounted) _toast(tr('حصلت مشكلة', 'Something went wrong'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// مسح ثم بذر فى خطوة واحدة.
  ///
  /// البذّار بيضيف من غير ما يمسح، فتشغيله مرتين كان بيضاعف البيانات —
  /// وده حصل فعلاً. الزرار ده بيقفل الباب: بيمسح الأول وبعدين يملأ.
  /// المسح بيحافظ على الإعدادات (الاسم والثيم واللغة).
  Future<void> _reseedDemo() async {
    final sure = await confirmAction(
      context,
      title: tr('مسح وإضافة من جديد', 'Reset & re-add'),
      message: tr(
          'هيتمسح كل اللى مسجّل دلوقتى (بياناتك الحقيقية كمان لو فيه) وبعدين '
          'يتملى ببيانات تجريبية. مش هينفع ترجّعه.',
          'Everything currently saved (including real data) will be deleted, '
          'then refilled with demo data. This cannot be undone.'),
      confirmLabel: tr('امسح وابدأ', 'Reset'),
    );
    if (!sure) return;
    setState(() => _busy = true);
    try {
      await Notifications.cancelAll();
      await AppDb.wipeAllData(keepSettings: true);
      final count = await seedDemoData();
      if (!mounted) return;
      _toast(tr('اتمسح واتضاف $count عنصر — اقفل وافتح التطبيق',
          'Reset — $count demo items added. Restart the app'));
    } on Exception catch (e) {
      logError('فشل المسح والبذر', e);
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
      logError('فشل المسح', e);
      if (mounted) _toast(tr('حصلت مشكلة', 'Something went wrong'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
