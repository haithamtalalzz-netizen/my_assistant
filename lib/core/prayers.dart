import 'package:adhan_dart/adhan_dart.dart';

import '../data/settings_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

/// أسماء الصلوات الخمس بالترتيب — نفس ترتيب [PrayerDay.times].
/// تُستخدم في الإشعارات (تفضل عربي دائمًا) — للعرض استخدم [prayerNameLabel].
const List<String> kPrayerNames = ['الفجر', 'الضهر', 'العصر', 'المغرب', 'العشا'];

const List<String> _kPrayerNamesEn = [
  'Fajr',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

/// اسم الصلاة للعرض حسب اللغة الحالية.
String prayerNameLabel(int index) => tr(kPrayerNames[index], _kPrayerNamesEn[index]);

class Governorate {
  final String name;
  final double lat;
  final double lng;

  const Governorate(this.name, this.lat, this.lng);
}

/// محافظات مصر — دقة مركز المحافظة كافية لمواعيد الصلاة.
const List<Governorate> kGovernorates = [
  Governorate('القاهرة', 30.0444, 31.2357),
  Governorate('الجيزة', 30.0131, 31.2089),
  Governorate('الإسكندرية', 31.2001, 29.9187),
  Governorate('الدقهلية', 31.0409, 31.3785),
  Governorate('البحر الأحمر', 27.2579, 33.8116),
  Governorate('البحيرة', 31.0341, 30.4682),
  Governorate('الفيوم', 29.3084, 30.8428),
  Governorate('الغربية', 30.7865, 31.0004),
  Governorate('الإسماعيلية', 30.6043, 32.2723),
  Governorate('المنوفية', 30.5545, 31.0092),
  Governorate('المنيا', 28.1099, 30.7503),
  Governorate('القليوبية', 30.4598, 31.1785),
  Governorate('الوادي الجديد', 25.4390, 30.5586),
  Governorate('السويس', 29.9668, 32.5498),
  Governorate('أسوان', 24.0889, 32.8998),
  Governorate('أسيوط', 27.1783, 31.1859),
  Governorate('بني سويف', 29.0661, 31.0994),
  Governorate('بورسعيد', 31.2653, 32.3019),
  Governorate('دمياط', 31.4165, 31.8133),
  Governorate('الشرقية', 30.5877, 31.5020),
  Governorate('جنوب سيناء', 28.2410, 33.6218),
  Governorate('كفر الشيخ', 31.1107, 30.9388),
  Governorate('مطروح', 31.3543, 27.2373),
  Governorate('الأقصر', 25.6872, 32.6396),
  Governorate('قنا', 26.1551, 32.7160),
  Governorate('شمال سيناء', 31.1316, 33.7984),
  Governorate('سوهاج', 26.5569, 31.6948),
];

Governorate governorateByName(String name) => kGovernorates
    .firstWhere((g) => g.name == name, orElse: () => kGovernorates.first);

/// الموقع المستخدم في الحسابات: مدينة عالمية مخصّصة (لو المستخدم اختارها من
/// البحث الجغرافي) وإلا محافظة مصر. بيوحّد المصدر للصلاة والطقس.
Future<Governorate> resolvePlace(SettingsRepo settings) async {
  final loc = await settings.customLocation();
  if (loc != null) {
    return Governorate(loc.label.isEmpty ? 'موقعك' : loc.label, loc.lat, loc.lng);
  }
  return governorateByName(await settings.governorateName());
}

class PrayerDay {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerDay({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// بنفس ترتيب [kPrayerNames].
  List<DateTime> get times => [fajr, dhuhr, asr, maghrib, isha];

  /// أول صلاة لسه ماجتش النهارده — null لو العشا فاتت.
  int? nextIndex(DateTime now) {
    for (var i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) return i;
    }
    return null;
  }
}

/// طرق حساب المواقيت المتاحة (المفتاح مخزّن، والعرض بـ [prayerMethodLabel]).
const List<String> kPrayerMethods = [
  'egyptian',
  'ummAlQura',
  'muslimWorldLeague',
  'karachi',
  'dubai',
  'qatar',
  'kuwait',
  'turkiye',
  'northAmerica',
];

String prayerMethodLabel(String key) => switch (key) {
      'egyptian' => tr('الهيئة المصرية العامة للمساحة', 'Egyptian General Authority'),
      'ummAlQura' => tr('أم القرى (السعودية)', 'Umm al-Qura (Saudi)'),
      'muslimWorldLeague' => tr('رابطة العالم الإسلامي', 'Muslim World League'),
      'karachi' => tr('كراتشي (جامعة العلوم)', 'Karachi'),
      'dubai' => tr('دبي', 'Dubai'),
      'qatar' => tr('قطر', 'Qatar'),
      'kuwait' => tr('الكويت', 'Kuwait'),
      'turkiye' => tr('تركيا (ديانت)', 'Turkey (Diyanet)'),
      'northAmerica' => tr('أمريكا الشمالية (ISNA)', 'North America (ISNA)'),
      _ => key,
    };

/// تفضيلات حساب المواقيت — بتتحمّل مرة عند بدء التطبيق + بعد أى تغيير.
class PrayerPrefs {
  static String method = 'egyptian';
  static String madhab = 'shafi';

  static Future<void> load() async {
    final s = SettingsRepo();
    method = await s.get('prayer.method') ?? 'egyptian';
    madhab = await s.get('prayer.madhab') ?? 'shafi';
  }
}

CalculationParameters _prayerParams() {
  final p = switch (PrayerPrefs.method) {
    'ummAlQura' => CalculationMethodParameters.ummAlQura(),
    'muslimWorldLeague' => CalculationMethodParameters.muslimWorldLeague(),
    'karachi' => CalculationMethodParameters.karachi(),
    'dubai' => CalculationMethodParameters.dubai(),
    'qatar' => CalculationMethodParameters.qatar(),
    'kuwait' => CalculationMethodParameters.kuwait(),
    'turkiye' => CalculationMethodParameters.turkiye(),
    'northAmerica' => CalculationMethodParameters.northAmerica(),
    _ => CalculationMethodParameters.egyptian(),
  };
  p.madhab = PrayerPrefs.madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  return p;
}

/// حساب فلكي محلي بالكامل — من غير نت (الطريقة والمذهب من التفضيلات).
PrayerDay prayerTimesFor(DateTime day, Governorate gov) {
  final pt = PrayerTimes(
    date: DateTime(day.year, day.month, day.day, 12),
    coordinates: Coordinates(gov.lat, gov.lng),
    calculationParameters: _prayerParams(),
    precision: true,
  );
  return PrayerDay(
    fajr: pt.fajr.toLocal(),
    dhuhr: pt.dhuhr.toLocal(),
    asr: pt.asr.toLocal(),
    maghrib: pt.maghrib.toLocal(),
    isha: pt.isha.toLocal(),
  );
}

/// جدولة إشعارات الأذان: مواعيد الصلاة بتتغير كل يوم، فبنجدول ٧ أيام
/// قدام كإشعارات مفردة وبنجددها مع كل فتحة للتطبيق.
class PrayerScheduler {
  static const int daysAhead = 7;

  /// الصلوات اللى ليها سنة راتبة مؤكّدة (الفجر/الظهر/المغرب/العشاء — مش العصر).
  static const List<int> _rawatibPrayers = [0, 1, 3, 4];

  static Future<void> ensureScheduled() async {
    // إلغاء كل الجدولات القديمة (صلاة + رواتب + سحور/إفطار).
    for (var d = 0; d < daysAhead; d++) {
      for (var p = 0; p < kPrayerNames.length; p++) {
        await Notifications.cancel(Notifications.prayerNotifId(d, p));
        await Notifications.cancel(Notifications.rawatibNotifId(d, p));
      }
      await Notifications.cancel(Notifications.suhoorNotifId(d));
      await Notifications.cancel(Notifications.iftarNotifId(d));
    }
    final settings = SettingsRepo();
    final prayerOn = await settings.prayerNotificationsEnabled();
    final rawatibOn = await settings.rawatibRemindersEnabled();
    final fastingOn = await settings.fastingRemindersEnabled();
    if (!prayerOn && !rawatibOn && !fastingOn) return;

    final adhanOn = await settings.adhanSoundEnabled();
    final adhanUri = adhanOn ? await settings.adhanCustomUri() : null;
    final adhanChannel = adhanOn ? await settings.adhanCustomChannel() : null;
    final gov = await resolvePlace(settings);
    final today = dateOnly(DateTime.now());
    for (var d = 0; d < daysAhead; d++) {
      final day = today.add(Duration(days: d));
      final prayers = prayerTimesFor(day, gov);
      final times = prayers.times;
      for (var p = 0; p < times.length; p++) {
        if (prayerOn) {
          await Notifications.scheduleOnce(
            id: Notifications.prayerNotifId(d, p),
            title: 'أذان ${kPrayerNames[p]}',
            body: 'وقت صلاة ${kPrayerNames[p]} — ${arTime(times[p])}',
            when: times[p],
            adhan: adhanOn,
            adhanUri: adhanUri,
            adhanChannel: adhanChannel,
          );
        }
        if (rawatibOn && _rawatibPrayers.contains(p)) {
          await Notifications.scheduleOnce(
            id: Notifications.rawatibNotifId(d, p),
            title: 'سنة ${kPrayerNames[p]} الراتبة',
            body: 'صلِّ ركعتَي السنة الراتبة 🤲',
            when: times[p].add(const Duration(minutes: 8)),
          );
        }
      }
      if (fastingOn) {
        // السحور قبل الفجر بـ 40 دقيقة، الإفطار عند المغرب.
        await Notifications.scheduleOnce(
          id: Notifications.suhoorNotifId(d),
          title: 'وقت السحور 🌙',
          body: 'اقترب الفجر — لا تنسَ السحور فإن فيه بركة',
          when: prayers.fajr.subtract(const Duration(minutes: 40)),
        );
        await Notifications.scheduleOnce(
          id: Notifications.iftarNotifId(d),
          title: 'وقت الإفطار 🌇',
          body: 'حان وقت المغرب — أفطر وتقبّل الله صيامك',
          when: prayers.maghrib,
        );
      }
    }
  }
}

/// تذكير أسبوعى يوم الجمعة: سورة الكهف + الإكثار من الصلاة على النبى ﷺ.
class FridayReminder {
  static Future<void> ensureScheduled() async {
    await Notifications.cancel(Notifications.fridayNotifId);
    final settings = SettingsRepo();
    if (!await settings.fridayReminderEnabled()) return;
    await Notifications.scheduleWeekly(
      id: Notifications.fridayNotifId,
      title: 'يوم الجمعة 🕌',
      body: 'لا تنسَ قراءة سورة الكهف والإكثار من الصلاة على النبى ﷺ',
      weekday: DateTime.friday,
      hour: 9,
      minute: 0,
    );
  }
}
