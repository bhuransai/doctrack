import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// User-selectable theme preference. [system] follows the OS setting.
enum AppThemeMode { system, light, dark }

extension AppThemeModeCodec on AppThemeMode {
  String get key => name;

  static AppThemeMode fromKey(String? key) {
    return AppThemeMode.values.firstWhere((m) => m.name == key, orElse: () => AppThemeMode.system);
  }
}

/// Single source of truth for "is the app dark right now" — read by every
/// [AppColors] getter (so they don't each need a BuildContext) and by
/// [DocTrackApp] to drive [MaterialApp.themeMode]. [DocStore.setThemeMode]
/// is the only place that mutates this; the app rebuilds after because that
/// call also runs through a [ChangeNotifier].
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  void setMode(AppThemeMode mode) => _mode = mode;

  bool get isDark {
    switch (_mode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  ThemeMode get flutterMode {
    switch (_mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// Design tokens lifted from the DocTrack design doc: navy ink + slate greys,
/// one blue accent, status colour used only for status. Every token below is
/// a getter (not a `const`) so it can resolve against [ThemeController] —
/// light values on the right of `:`, dark values on the left of `?`.
class AppColors {
  AppColors._();

  static bool get _dark => ThemeController.instance.isDark;

  static Color get canvas => _dark ? const Color(0xFF0A0D14) : const Color(0xFFEBEDF1);
  static Color get screenBg => _dark ? const Color(0xFF10141D) : const Color(0xFFF6F7F9);
  static Color get surface => _dark ? const Color(0xFF171B26) : const Color(0xFFFFFFFF);
  // A step lighter than [surface] — replaces the light-mode-only literal
  // fills (search boxes, calendar body, ad slot) so they stay legible on dark.
  static Color get surfaceRaised => _dark ? const Color(0xFF1E2330) : const Color(0xFFFBFCFD);
  // Translucent surface for the blurred bottom nav bar.
  static Color get navBarBg => _dark ? const Color(0xE6161A24) : const Color(0xEBFFFFFF);

  // Primary text/icon colour — flips with the theme.
  static Color get ink => _dark ? const Color(0xFFF2F4F8) : const Color(0xFF101728);
  // Solid brand-dark fill for buttons, avatars, the FAB and the splash
  // background — stays a dark navy in light mode; lifts to an elevated
  // slate (not pure white) in dark mode so it still reads as "the dark chip"
  // against an already-dark canvas.
  static Color get inkStrong => _dark ? const Color(0xFF242B3A) : const Color(0xFF101728);
  // Fixed dark colour for text that always sits on a fixed light/white
  // surface (e.g. the welcome screen's white CTA) — never flips.
  static const onLight = Color(0xFF101728);

  static Color get textMuted => _dark ? const Color(0xFF9AA3B5) : const Color(0xFF8A93A3);
  static Color get textFaint => _dark ? const Color(0xFF7E8698) : const Color(0xFF98A1B0);
  static Color get textSlate => _dark ? const Color(0xFFB0B8C8) : const Color(0xFF626C7E);
  static Color get textDisabled => _dark ? const Color(0xFF576079) : const Color(0xFFA8B0BD);
  static Color get textDim => _dark ? const Color(0xFF9CA4B5) : const Color(0xFF7A8394);
  static Color get dotMuted => _dark ? const Color(0xFF4C5468) : const Color(0xFFC9CFDA);
  static Color get chevron => _dark ? const Color(0xFF4C5468) : const Color(0xFFC2C9D4);

  static Color get borderCard => _dark ? const Color(0xFF262C3B) : const Color(0xFFE8EBF1);
  static Color get borderSoft => _dark ? const Color(0xFF1D2230) : const Color(0xFFEEF0F4);
  static Color get borderFaint => _dark ? const Color(0xFF1A1F2B) : const Color(0xFFF1F3F7);
  static Color get borderInput => _dark ? const Color(0xFF2C3344) : const Color(0xFFE4E8EF);
  static Color get borderDashed => _dark ? const Color(0xFF3A4257) : const Color(0xFFD8DDE6);

  static Color get accent => _dark ? const Color(0xFF6E8CFF) : const Color(0xFF2F5FE0);
  static Color get accentSoft => _dark ? const Color(0xFF1B2138) : const Color(0xFFF4F7FF);
  static Color get accentTint => _dark ? const Color(0xFF1D2540) : const Color(0xFFEEF2FE);
  static Color get accentMuted => _dark ? const Color(0xFF9FB2E8) : const Color(0xFF5C7BD9);

  static const badgeRed = Color(0xFFD14436);

  // Status: Safe
  static Color get safeFg => _dark ? const Color(0xFF4FD196) : const Color(0xFF0F7A4F);
  static const safeStrong = Color(0xFF17966A);
  static Color get safeTint => _dark ? const Color(0xFF12291F) : const Color(0xFFE9F5EF);
  static Color get safeLine => _dark ? const Color(0xFF1E4432) : const Color(0xFFCDE8DC);

  // Status: Expiring soon
  static Color get soonFg => _dark ? const Color(0xFFF3B94A) : const Color(0xFF8A5300);
  static const soonStrong = Color(0xFFE0A030);
  static Color get soonTint => _dark ? const Color(0xFF322813) : const Color(0xFFFCF2E0);
  static Color get soonLine => _dark ? const Color(0xFF4A3B1E) : const Color(0xFFF0DFBE);

  // Status: Expired / urgent
  static Color get urgentFg => _dark ? const Color(0xFFFF8A75) : const Color(0xFFA63024);
  static const urgentStrong = Color(0xFFD14436);
  static Color get urgentTint => _dark ? const Color(0xFF321C18) : const Color(0xFFFBEAE7);
  static Color get urgentLine => _dark ? const Color(0xFF4A2A24) : const Color(0xFFF2D3CE);
}

enum DocStatus { safe, soon, urgent }

class StatusPalette {
  final String label;
  final Color fg;
  final Color strong;
  final Color tint;
  final Color line;
  const StatusPalette({
    required this.label,
    required this.fg,
    required this.strong,
    required this.tint,
    required this.line,
  });
}

/// Built fresh on every read (not `const`) so it reflects the current theme
/// via the [AppColors] getters above.
Map<DocStatus, StatusPalette> get kStatusPalettes => {
      DocStatus.safe: StatusPalette(
        label: 'SAFE',
        fg: AppColors.safeFg,
        strong: AppColors.safeStrong,
        tint: AppColors.safeTint,
        line: AppColors.safeLine,
      ),
      DocStatus.soon: StatusPalette(
        label: 'EXPIRING',
        fg: AppColors.soonFg,
        strong: AppColors.soonStrong,
        tint: AppColors.soonTint,
        line: AppColors.soonLine,
      ),
      DocStatus.urgent: StatusPalette(
        label: 'EXPIRED',
        fg: AppColors.urgentFg,
        strong: AppColors.urgentStrong,
        tint: AppColors.urgentTint,
        line: AppColors.urgentLine,
      ),
    };

/// Text style helpers. Plus Jakarta Sans for UI copy, IBM Plex Mono for
/// dates, numbers and small mono labels — mirrors the design doc's SYSTEM note.
class AppText {
  AppText._();

  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: height,
        letterSpacing: letterSpacing,
      );
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFEBEDF1),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F5FE0),
      primary: isDark ? const Color(0xFF6E8CFF) : const Color(0xFF2F5FE0),
      brightness: brightness,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  );
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);
