import 'package:flutter/material.dart';

/// Gavel's look: a warm auction room in ink, ivory and gold, with green for
/// a lead, orange for an outbid and red for LIVE.
abstract final class Brand {
  static const ink = Color(0xFF17130F);
  static const inkRaised = Color(0xFF241E18);
  static const inkLine = Color(0xFF3A3129);
  static const gold = Color(0xFFE0A93B);
  static const goldBright = Color(0xFFF2C66D);

  /// Gold dark enough to read on ivory.
  static const goldDeep = Color(0xFF8F600F);
  static const goldTint = Color(0xFFF8EDD7);
  static const ivory = Color(0xFFFAF7F2);
  static const line = Color(0xFFE8E0D3);
  static const muted = Color(0xFF6E6458);

  /// Muted text on [ink].
  static const mutedOnInk = Color(0xFFB5A994);
  static const live = Color(0xFFE5383B);
  static const lead = Color(0xFF15803D);
  static const leadTint = Color(0xFFDCFCE7);
  static const outbid = Color(0xFFC2410C);
  static const outbidTint = Color(0xFFFFEDD5);

  static const sans = 'Plus Jakarta Sans';
  static const serif = 'Playfair Display';

  /// The serif of headlines and the wordmark.
  static const display = TextStyle(
    fontFamily: serif,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
  );

  /// Tabular figures, so a ticking price or clock doesn't jiggle.
  static const tabular = [FontFeature.tabularFigures()];

  /// Small capitals over a value: CURRENT BID, CLOSES IN.
  static const eyebrow = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  /// The dark band behind heroes and headers: ink warmed by a gold glow.
  static const band = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.75, -0.9),
      radius: 1.6,
      colors: [Color(0xFF3D2E17), ink],
      stops: [0, 0.75],
    ),
  );

  /// Gold on ink, for the moments that move money: bid, join, try the demo.
  static final goldButton = FilledButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: ink,
    disabledBackgroundColor: gold.withValues(alpha: 0.4),
    disabledForegroundColor: ink.withValues(alpha: 0.5),
  );
}

/// The app's light theme.
ThemeData gavelTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.gold,
        brightness: Brightness.light,
      ).copyWith(
        primary: Brand.ink,
        onPrimary: Colors.white,
        primaryContainer: Brand.goldTint,
        onPrimaryContainer: const Color(0xFF3D2A06),
        secondary: Brand.goldDeep,
        onSecondary: Colors.white,
        secondaryContainer: Brand.goldTint,
        onSecondaryContainer: const Color(0xFF3D2A06),
        tertiary: Brand.lead,
        onTertiary: Colors.white,
        tertiaryContainer: Brand.leadTint,
        onTertiaryContainer: const Color(0xFF14532D),
        surface: Colors.white,
        onSurface: Brand.ink,
        onSurfaceVariant: Brand.muted,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFCFAF6),
        surfaceContainer: const Color(0xFFF6F1EA),
        surfaceContainerHigh: const Color(0xFFF1EBE2),
        surfaceContainerHighest: const Color(0xFFEAE3D8),
        outline: const Color(0xFFCFC4B4),
        outlineVariant: Brand.line,
        error: const Color(0xFFC62828),
      );
  return _build(scheme, background: Brand.ivory);
}

/// The projector's theme (UC-11): black and gold whatever the system
/// theme, for a dark room.
ThemeData gavelBigScreenTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Brand.gold,
        onPrimary: Brand.ink,
        primaryContainer: const Color(0xFF4A3712),
        onPrimaryContainer: Brand.goldBright,
        surface: const Color(0xFF1A1612),
        onSurface: Colors.white,
        onSurfaceVariant: Brand.mutedOnInk,
        outlineVariant: Brand.inkLine,
      );
  return _build(scheme, background: Colors.black).copyWith(
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1612),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.inkLine),
      ),
    ),
  );
}

ThemeData _build(ColorScheme scheme, {required Color background}) {
  final base = ThemeData(colorScheme: scheme, fontFamily: Brand.sans);
  final text = base.textTheme;
  TextStyle? heavy(TextStyle? style, double spacing) =>
      style?.copyWith(fontWeight: FontWeight.w800, letterSpacing: spacing);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const buttonText = TextStyle(
    fontFamily: Brand.sans,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: text.copyWith(
      displayLarge: heavy(text.displayLarge, -1.5),
      displayMedium: heavy(text.displayMedium, -1),
      displaySmall: heavy(text.displaySmall, -0.5),
      headlineLarge: heavy(text.headlineLarge, -0.5),
      headlineMedium: heavy(text.headlineMedium, -0.5),
      headlineSmall: heavy(text.headlineSmall, -0.25),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: text.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.ink,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: Brand.sans,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: shape, textStyle: buttonText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 1.6),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.6),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: Brand.goldTint,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: Brand.sans,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.ink,
      actionTextColor: Brand.gold,
      contentTextStyle: const TextStyle(
        fontFamily: Brand.sans,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: shape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Brand.gold,
      foregroundColor: Brand.ink,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      extendedTextStyle: buttonText.copyWith(fontWeight: FontWeight.w800),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.gold),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(fontFamily: Brand.sans, color: Colors.white),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Brand.goldDeep,
      thumbColor: Brand.goldDeep,
    ),
  );
}
