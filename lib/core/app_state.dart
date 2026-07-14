import 'dart:async';

import 'package:flutter/material.dart';

import '../data/settings_repo.dart';

/// حالة عامة للتطبيق: وضع الثيم واللغة — محفوظين في الإعدادات وبيتغيروا live
/// عبر ValueNotifier (المستمع في app.dart بيعيد بناء MaterialApp).
class AppState {
  // الافتراضي غامق (الهوية البصرية البريميوم) — المستخدم يقدر يغيّره من الإعدادات.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  // مفتاح لون الهوية (mint/pink/blue/...) — الافتراضي نعناعي.
  static final ValueNotifier<String> accentKey = ValueNotifier('mint');
  // مفتاح لون الخلفية للوضع الغامق — الافتراضي كحلي داكن.
  static final ValueNotifier<String> bgKey = ValueNotifier('midnight');
  // مفتاح لون الخلفية للوضع الفاتح — الافتراضي أبيض ورقي.
  static final ValueNotifier<String> bgLightKey = ValueNotifier('paper');
  // النوع: '' غير محدد / 'male' ذكر / 'female' أنثى (يظهر بند الدورة الشهرية).
  static final ValueNotifier<String> gender = ValueNotifier('');

  // ---- الوضع الليلي المجدول ----
  static bool scheduleEnabled = false;
  static String darkFrom = '18:00';
  static String darkTo = '06:00';
  static Timer? _scheduleTimer;

  static Future<void> load() async {
    final s = SettingsRepo();
    themeMode.value = _modeFrom(await s.get('theme_mode'));
    final lang = await s.get('language');
    locale.value = Locale(lang == 'en' ? 'en' : 'ar');
    accentKey.value = await s.get('ui_accent') ?? 'mint';
    bgKey.value = await s.get('ui_bg') ?? 'midnight';
    bgLightKey.value = await s.get('ui_bg_light') ?? 'paper';
    gender.value = await s.get('gender') ?? '';
    scheduleEnabled = await s.get('theme.schedule') == '1';
    darkFrom = await s.get('theme.dark_from') ?? '18:00';
    darkTo = await s.get('theme.dark_to') ?? '06:00';
    if (scheduleEnabled) {
      applySchedule();
      // نعيد التقييم كل دقيقة عشان الثيم يتبدّل تلقائي فى وقته.
      _scheduleTimer?.cancel();
      _scheduleTimer =
          Timer.periodic(const Duration(minutes: 1), (_) => applySchedule());
    }
  }

  static int _parseHm(String hm) {
    final parts = hm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  /// دالة نقية للاختبار: هل الوقت [nowM] (بالدقائق) يقع داخل نافذة الغامق
  /// [from]→[to]؟ بتتعامل مع تجاوز منتصف الليل (مثلاً ٦م→٦ص).
  static bool isDarkWindow(int nowM, String from, String to) {
    final f = _parseHm(from), t = _parseHm(to);
    return f <= t ? (nowM >= f && nowM < t) : (nowM >= f || nowM < t);
  }

  /// يحسب الثيم من الوقت الحالى لو الجدول مفعّل (بيتعامل مع تجاوز منتصف الليل).
  static void applySchedule() {
    if (!scheduleEnabled) return;
    final now = TimeOfDay.now();
    final nowM = now.hour * 60 + now.minute;
    final dark = isDarkWindow(nowM, darkFrom, darkTo);
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    if (themeMode.value != mode) themeMode.value = mode;
  }

  static Future<void> setSchedule(
      {bool? enabled, String? from, String? to}) async {
    final s = SettingsRepo();
    if (enabled != null) {
      scheduleEnabled = enabled;
      await s.set('theme.schedule', enabled ? '1' : '0');
    }
    if (from != null) {
      darkFrom = from;
      await s.set('theme.dark_from', from);
    }
    if (to != null) {
      darkTo = to;
      await s.set('theme.dark_to', to);
    }
    _scheduleTimer?.cancel();
    if (scheduleEnabled) {
      applySchedule();
      _scheduleTimer =
          Timer.periodic(const Duration(minutes: 1), (_) => applySchedule());
    } else {
      // نرجع للوضع المحفوظ يدويًا.
      themeMode.value = _modeFrom(await s.get('theme_mode'));
    }
  }

  static Future<void> setGender(String g) async {
    gender.value = g;
    await SettingsRepo().set('gender', g);
  }

  static Future<void> setAccent(String key) async {
    accentKey.value = key;
    await SettingsRepo().set('ui_accent', key);
  }

  static Future<void> setBg(String key) async {
    bgKey.value = key;
    await SettingsRepo().set('ui_bg', key);
  }

  static Future<void> setBgLight(String key) async {
    bgLightKey.value = key;
    await SettingsRepo().set('ui_bg_light', key);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    // اختيار يدوى للثيم بيوقف الجدولة (المستخدم كسب).
    if (scheduleEnabled) await setSchedule(enabled: false);
    themeMode.value = mode;
    await SettingsRepo().set('theme_mode', _modeName(mode));
  }

  static Future<void> setLanguage(String code) async {
    final normalized = code == 'en' ? 'en' : 'ar';
    locale.value = Locale(normalized);
    await SettingsRepo().set('language', normalized);
  }

  static bool get isEnglish => locale.value.languageCode == 'en';

  static ThemeMode _modeFrom(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        // مفيش إعداد محفوظ → غامق (الافتراضي البريميوم).
        _ => ThemeMode.dark,
      };

  static String _modeName(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
