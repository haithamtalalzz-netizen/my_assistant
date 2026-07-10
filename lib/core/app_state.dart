import 'package:flutter/material.dart';

import '../data/settings_repo.dart';

/// حالة عامة للتطبيق: وضع الثيم واللغة — محفوظين في الإعدادات وبيتغيروا live
/// عبر ValueNotifier (المستمع في app.dart بيعيد بناء MaterialApp).
class AppState {
  // الافتراضي غامق (الهوية البصرية البريميوم) — المستخدم يقدر يغيّره من الإعدادات.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  // مفتاح لون الهوية: mint/blue/purple/gold — الافتراضي نعناعي.
  static final ValueNotifier<String> accentKey = ValueNotifier('mint');

  static Future<void> load() async {
    final s = SettingsRepo();
    themeMode.value = _modeFrom(await s.get('theme_mode'));
    final lang = await s.get('language');
    locale.value = Locale(lang == 'en' ? 'en' : 'ar');
    accentKey.value = await s.get('ui_accent') ?? 'mint';
  }

  static Future<void> setAccent(String key) async {
    accentKey.value = key;
    await SettingsRepo().set('ui_accent', key);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
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
