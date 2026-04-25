import 'package:app_ui/app_ui.dart';
import 'package:app_ui/src/theme/theme.dart';

/// {@template app_typography}
/// Typography tokens for the app, built on the Geist type family.
///
/// Sizes, weights, line-heights, and letter-spacing are tuned for a
/// near-black dark surface. Every style ships with [ColorPalette.onSurface]
/// as its default color so widgets that consume these styles directly
/// (without passing through Material's theming) still render with the
/// correct foreground.
///
/// Styles are exposed as static [TextStyle]s and also composed into a
/// Material [TextTheme] via [textTheme] so built-in widgets ([AppBar],
/// [ListTile], [TextField], etc.) pick the correct style automatically.
/// {@endtemplate}
abstract final class AppTypography {
  /// The Geist font family, packaged with `app_ui`.
  static const fontFamily = 'Geist';

  /// The package the [fontFamily] is bundled in.
  static const package = 'app_ui';

  /// Hero display style. Use for splash and onboarding hero copy.
  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Mid display style. Use for empty-state hero titles.
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.6,
  );

  /// Small display style. Use for marketing-style headers.
  static const displaySmall = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.5,
  );

  /// Largest headline. Use for top-level screen titles.
  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.22,
    letterSpacing: -0.3,
  );

  /// Mid headline. Use for section titles inside a screen.
  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Small headline. Use for dialog titles and prominent rows.
  static const headlineSmall = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  /// Large title. Use for app-bar titles and grouped section headers.
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Mid title. Use for list-item titles.
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Small title. Use for compact metadata rows.
  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Default body style. Use for chat messages and primary copy.
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Compact body style. Use for secondary copy and dialog content.
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Smallest body style. Use for timestamps and helper text.
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  /// Large label. Use for primary button labels.
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// Mid label. Use for chips and secondary controls.
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Small label. Use for badges and overlines.
  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    package: package,
    color: ColorPalette.onSurface,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.4,
  );

  /// The styles composed into a Material [TextTheme] so that built-in
  /// widgets ([AppBar], [ListTile], [TextField], etc.) inherit them
  /// automatically.
  static const textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
