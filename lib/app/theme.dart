import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// shadcn-like look of the web admin: slate neutrals, 1 px borders, 10 px
/// radius, Inter, one accent (PLAN.md §8, QUESTIONS M23).
abstract final class AppColors {
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);
  static const teal = Color(0xFF0F766E);
  static const tealLight = Color(0xFF14B8A6);
  static const danger = Color(0xFFB91C1C);
  static const dangerDark = Color(0xFFF87171);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
}

double _luminance(Color c) => c.computeLuminance();

/// WCAG contrast ratio between two colours.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The restaurant's brand colour when it reads on white (≥ 4.5:1), else teal.
Color accentFor(Color? brand) => brand != null && contrastRatio(brand, Colors.white) >= 4.5 ? brand : AppColors.teal;

/// Parses #RRGGBB.
Color? parseHex(String? hex) {
  if (hex == null) return null;
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

ThemeData buildTheme(Brightness brightness, {Color? accent}) {
  final dark = brightness == Brightness.dark;
  final primary = dark ? AppColors.tealLight : (accent ?? AppColors.teal);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: dark ? AppColors.slate950 : Colors.white,
    primaryContainer: dark ? const Color(0xFF134E4A) : const Color(0xFFE6F4F2),
    onPrimaryContainer: dark ? const Color(0xFF99F6E4) : const Color(0xFF134E4A),
    secondary: dark ? AppColors.slate100 : AppColors.slate900,
    onSecondary: dark ? AppColors.slate900 : Colors.white,
    surface: dark ? AppColors.slate950 : Colors.white,
    onSurface: dark ? AppColors.slate100 : AppColors.slate900,
    onSurfaceVariant: dark ? AppColors.slate400 : AppColors.slate600,
    surfaceContainerLowest: dark ? AppColors.slate950 : Colors.white,
    surfaceContainerLow: dark ? AppColors.slate900 : AppColors.slate50,
    surfaceContainer: dark ? AppColors.slate900 : AppColors.slate50,
    surfaceContainerHigh: dark ? AppColors.slate800 : AppColors.slate100,
    surfaceContainerHighest: dark ? AppColors.slate800 : AppColors.slate100,
    outline: dark ? AppColors.slate700 : AppColors.slate300,
    outlineVariant: dark ? AppColors.slate800 : AppColors.slate200,
    error: dark ? AppColors.dangerDark : AppColors.danger,
    onError: Colors.white,
  );
  final radius = BorderRadius.circular(10);
  final border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: scheme.outline),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter', brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? AppColors.slate950 : AppColors.slate50,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface),
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
      errorBorder: border.copyWith(borderSide: BorderSide(color: scheme.error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 10,
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelType: NavigationRailLabelType.all,
    ),
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
      backgroundColor: scheme.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
  );
}
