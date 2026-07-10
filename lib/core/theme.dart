import 'package:flutter/material.dart';

import 'app_state.dart';

/// خط Cairo مدمج كـ asset (مفيش تحميل من النت خالص) + وضع فاتح وغامق بريميوم.
ThemeData buildTheme() => _buildLight(_accent());
ThemeData buildDarkTheme() => _buildDark(_accent());

// ---- ألوان الهوية (منتقي في الإعدادات) ----
const Color kAccent = Color(0xFF2FDE9B); // أخضر نعناعي (الافتراضي)
const Color kAccentDeep = Color(0xFF16B57E);

/// ألوان الهوية المتاحة — كل واحدة primary + container + onContainer.
class AccentPreset {
  final String label;
  final Color primary;
  final Color container;
  final Color onContainer;
  const AccentPreset(this.label, this.primary, this.container, this.onContainer);
}

const Map<String, AccentPreset> kAccentPresets = {
  'mint': AccentPreset(
      'نعناعي', Color(0xFF2FDE9B), Color(0xFF10362A), Color(0xFFA9F5D4)),
  'blue': AccentPreset(
      'أزرق', Color(0xFF4AA8FF), Color(0xFF14344F), Color(0xFFBFE1FF)),
  'purple': AccentPreset(
      'بنفسجي', Color(0xFFB794F6), Color(0xFF2E2247), Color(0xFFE4D3FF)),
  'gold': AccentPreset(
      'ذهبي (رمضان)', Color(0xFFE9C46A), Color(0xFF3A2E12), Color(0xFFFBE9C0)),
};

AccentPreset _accent() =>
    kAccentPresets[AppState.accentKey.value] ?? kAccentPresets['mint']!;

// ---- ألوان الوضع الغامق (مطابقة للموكاب) ----
const Color _dBg = Color(0xFF0B0F17); // خلفية الشاشة
const Color _dCard = Color(0xFF141B27); // سطح الكروت
const Color _dCardHigh = Color(0xFF1B2431);
const Color _dBorder = Color(0xFF232E40); // حدود ناعمة حوالين الكروت
const Color _dText = Color(0xFFE9EDF4);
const Color _dMuted = Color(0xFF8A94A6);

ThemeData _buildDark(AccentPreset a) {
  final scheme = ColorScheme.dark(
    primary: a.primary,
    onPrimary: const Color(0xFF04271B),
    primaryContainer: a.container,
    onPrimaryContainer: a.onContainer,
    secondary: Color(0xFF4AA8FF),
    onSecondary: Color(0xFF03243D),
    secondaryContainer: Color(0xFF14344F),
    onSecondaryContainer: Color(0xFFBFE1FF),
    tertiary: Color(0xFFFFB74D),
    tertiaryContainer: Color(0xFF3A2A12),
    onTertiaryContainer: Color(0xFFFFE0B2),
    surface: _dBg,
    onSurface: _dText,
    surfaceContainerLowest: Color(0xFF0D131C),
    surfaceContainerLow: _dCard,
    surfaceContainer: _dCard,
    surfaceContainerHigh: _dCardHigh,
    surfaceContainerHighest: Color(0xFF212C3D),
    onSurfaceVariant: _dMuted,
    outline: _dMuted,
    outlineVariant: _dBorder,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3A0A0A),
  );
  return _common(scheme, cardColor: _dCard, borderColor: _dBorder);
}

ThemeData _buildLight(AccentPreset a) {
  final scheme = ColorScheme.fromSeed(
    seedColor: a.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: a.primary,
    surface: const Color(0xFFF6F8F9),
  );
  return _common(scheme,
      cardColor: Colors.white, borderColor: const Color(0xFFE3E8EC));
}

ThemeData _common(ColorScheme scheme,
    {required Color cardColor, required Color borderColor}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: scheme.surface,
  );
  final radius = BorderRadius.circular(20);
  return base.copyWith(
    // كروت مرفوعة بحواف مدوّرة + حدّ ناعم (زي الموكاب).
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      side: BorderSide(color: borderColor),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface)),
    ),
  );
}
