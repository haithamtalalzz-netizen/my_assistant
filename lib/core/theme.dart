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

/// مولّد لون هوية من درجة لونية (hue 0-360) — primary + container + onContainer متناسقين.
AccentPreset _hueAccent(int hue) => AccentPreset(
      '$hue°',
      HSLColor.fromAHSL(1, hue.toDouble(), 0.72, 0.60).toColor(),
      HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.16).toColor(),
      HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.86).toColor(),
    );

/// ألوان الهوية: 14 لون مسمّى + 36 درجة مولّدة عبر الطيف = تشكيلة كبيرة.
final Map<String, AccentPreset> kAccentPresets = {
  'mint': const AccentPreset(
      'نعناعي', Color(0xFF2FDE9B), Color(0xFF10362A), Color(0xFFA9F5D4)),
  'pink': const AccentPreset(
      'وردي', Color(0xFFFF6EC7), Color(0xFF3A1830), Color(0xFFFFD1EC)),
  'blue': const AccentPreset(
      'أزرق', Color(0xFF4AA8FF), Color(0xFF14344F), Color(0xFFBFE1FF)),
  'purple': const AccentPreset(
      'بنفسجي', Color(0xFFB794F6), Color(0xFF2E2247), Color(0xFFE4D3FF)),
  'red': const AccentPreset(
      'أحمر', Color(0xFFFF6B6B), Color(0xFF3A1414), Color(0xFFFFC9C9)),
  'orange': const AccentPreset(
      'برتقالي', Color(0xFFFFA94D), Color(0xFF3A2712), Color(0xFFFFE0B2)),
  'amber': const AccentPreset(
      'كهرماني', Color(0xFFFFCA28), Color(0xFF3A2E0A), Color(0xFFFFECB3)),
  'gold': const AccentPreset(
      'ذهبي (رمضان)', Color(0xFFE9C46A), Color(0xFF3A2E12), Color(0xFFFBE9C0)),
  'green': const AccentPreset(
      'أخضر', Color(0xFF66BB6A), Color(0xFF15321A), Color(0xFFC8E6C9)),
  'teal': const AccentPreset(
      'تركوازي', Color(0xFF2DD4BF), Color(0xFF0F332F), Color(0xFFA7F3E8)),
  'cyan': const AccentPreset(
      'سماوي', Color(0xFF4DD0E1), Color(0xFF0E323A), Color(0xFFB2EBF2)),
  'indigo': const AccentPreset(
      'نيلي', Color(0xFF8C9EFF), Color(0xFF1E2547), Color(0xFFC5CAE9)),
  'coral': const AccentPreset(
      'مرجاني', Color(0xFFFF8A65), Color(0xFF3A1E14), Color(0xFFFFCCBC)),
  'lavender': const AccentPreset(
      'خزامي', Color(0xFFCE93D8), Color(0xFF2E1A33), Color(0xFFF3D9F7)),
  // 36 درجة عبر الطيف كامل.
  for (var h = 0; h < 360; h += 10) 'h$h': _hueAccent(h),
};

AccentPreset _accent() =>
    kAccentPresets[AppState.accentKey.value] ?? kAccentPresets['mint']!;

// ---- ألوان الخلفية (منتقاة في الإعدادات، للوضعين الغامق والفاتح) ----
class BgPreset {
  final String label;
  final Color bg;
  final Color card;
  final Color cardHigh;
  final Color border;
  const BgPreset(this.label, this.bg, this.card, this.cardHigh, this.border);
}

const Map<String, BgPreset> kBgPresets = {
  'midnight': BgPreset('كحلي داكن', Color(0xFF0B0F17), Color(0xFF141B27),
      Color(0xFF1B2431), Color(0xFF232E40)),
  'black': BgPreset('أسود', Color(0xFF000000), Color(0xFF0E0E0E),
      Color(0xFF1A1A1A), Color(0xFF262626)),
  'charcoal': BgPreset('فحمي', Color(0xFF14161A), Color(0xFF1E2126),
      Color(0xFF262A30), Color(0xFF33383F)),
  'slate': BgPreset('رمادي أزرق', Color(0xFF0F1720), Color(0xFF19232E),
      Color(0xFF212D3A), Color(0xFF2C3B4C)),
  'navy': BgPreset('أزرق بحري', Color(0xFF0A1428), Color(0xFF13203B),
      Color(0xFF1A2A4A), Color(0xFF26385C)),
  'ocean': BgPreset('أزرق محيطي', Color(0xFF07171C), Color(0xFF0E2831),
      Color(0xFF12333E), Color(0xFF1C4652)),
  'espresso': BgPreset('بني قهوة', Color(0xFF16110E), Color(0xFF241C17),
      Color(0xFF2E241D), Color(0xFF3A2E24)),
  'forest': BgPreset('أخضر غابة', Color(0xFF0A1512), Color(0xFF12251F),
      Color(0xFF183028), Color(0xFF234037)),
  'plum': BgPreset('برقوقي', Color(0xFF140F1A), Color(0xFF201828),
      Color(0xFF2A2035), Color(0xFF382A45)),
  'wine': BgPreset('نبيتي', Color(0xFF19080D), Color(0xFF281217),
      Color(0xFF33181E), Color(0xFF45242B)),
};

/// خلفيات الوضع الفاتح.
const Map<String, BgPreset> kLightBgPresets = {
  'paper': BgPreset('أبيض ورقي', Color(0xFFF6F8F9), Color(0xFFFFFFFF),
      Color(0xFFEDF0F2), Color(0xFFE3E8EC)),
  'pure': BgPreset('أبيض ناصع', Color(0xFFFFFFFF), Color(0xFFFFFFFF),
      Color(0xFFF2F3F5), Color(0xFFE6E8EB)),
  'warm': BgPreset('كريمي', Color(0xFFFBF6EF), Color(0xFFFFFDF9),
      Color(0xFFF3ECE0), Color(0xFFEDE3D4)),
  'gray': BgPreset('رمادي فاتح', Color(0xFFEFF0F2), Color(0xFFFFFFFF),
      Color(0xFFE6E7EA), Color(0xFFDADCE0)),
  'mintlight': BgPreset('أخضر فاتح', Color(0xFFEFF9F4), Color(0xFFFFFFFF),
      Color(0xFFE3F4EC), Color(0xFFD5EBE0)),
  'bluelight': BgPreset('أزرق فاتح', Color(0xFFEEF4FC), Color(0xFFFFFFFF),
      Color(0xFFE1EDFA), Color(0xFFD3E4F5)),
  'pinklight': BgPreset('وردي فاتح', Color(0xFFFCEFF6), Color(0xFFFFFFFF),
      Color(0xFFF8E1EE), Color(0xFFF0D3E4)),
  'lavlight': BgPreset('خزامي فاتح', Color(0xFFF5F0FB), Color(0xFFFFFFFF),
      Color(0xFFEDE3F7), Color(0xFFE0D3F0)),
};

BgPreset _bg() => kBgPresets[AppState.bgKey.value] ?? kBgPresets['midnight']!;
BgPreset _bgLight() =>
    kLightBgPresets[AppState.bgLightKey.value] ?? kLightBgPresets['paper']!;

const Color _dText = Color(0xFFE9EDF4);
const Color _dMuted = Color(0xFF8A94A6);

ThemeData _buildDark(AccentPreset a) {
  final b = _bg();
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
    surface: b.bg,
    onSurface: _dText,
    surfaceContainerLowest: b.bg,
    surfaceContainerLow: b.card,
    surfaceContainer: b.card,
    surfaceContainerHigh: b.cardHigh,
    surfaceContainerHighest: b.cardHigh,
    onSurfaceVariant: _dMuted,
    outline: _dMuted,
    outlineVariant: b.border,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3A0A0A),
  );
  return _common(scheme, cardColor: b.card, borderColor: b.border);
}

ThemeData _buildLight(AccentPreset a) {
  final b = _bgLight();
  final scheme = ColorScheme.fromSeed(
    seedColor: a.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: a.primary,
    surface: b.bg,
    surfaceContainerLow: b.card,
    surfaceContainer: b.card,
    surfaceContainerHigh: b.cardHigh,
    surfaceContainerHighest: b.cardHigh,
    outlineVariant: b.border,
  );
  return _common(scheme, cardColor: b.card, borderColor: b.border);
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
