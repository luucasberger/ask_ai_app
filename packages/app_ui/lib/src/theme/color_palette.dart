import 'package:app_ui/app_ui.dart';

/// {@template color_palette}
/// The raw color palette for the app's dark theme.
///
/// All [Color] values used by [AppTheme], [AppColors], and any widget
/// that needs a hard-coded color should be referenced from here so the
/// palette has a single source of truth.
/// {@endtemplate}
abstract final class ColorPalette {
  // ─── Pure ──────────────────────────────────────────────────────────
  /// Pure black — used for shadows and scrim.
  static const black = Color(0xFF000000);

  /// Pure white — used as a foreground on saturated accents.
  static const white = Color(0xFFFFFFFF);

  // ─── Surfaces (near-black) ─────────────────────────────────────────
  /// The scaffold background — the deepest neutral.
  static const background = Color(0xFF0B0B0F);

  /// The default surface (cards, app bars without scroll).
  static const surface = Color(0xFF14141A);

  /// One step above the scaffold for grouped containers.
  static const surfaceContainerLow = Color(0xFF14141A);

  /// Default elevated container (chat bubbles, inputs).
  static const surfaceContainer = Color(0xFF1C1C24);

  /// Higher-emphasis container (drawer, dialogs, sheets).
  static const surfaceContainerHigh = Color(0xFF25252F);

  /// Highest-emphasis container (snackbars, tooltips).
  static const surfaceContainerHighest = Color(0xFF2F2F3B);

  // ─── Text ──────────────────────────────────────────────────────────
  /// Primary foreground on surfaces — off-white, not pure white.
  static const onSurface = Color(0xFFF5F5F7);

  /// Secondary foreground for metadata and timestamps.
  static const onSurfaceVariant = Color(0xFFA1A1AA);

  /// Tertiary foreground for hints and disabled labels.
  static const textMuted = Color(0xFF71717A);

  // ─── Borders ───────────────────────────────────────────────────────
  /// Default outline for outlined controls.
  static const outline = Color(0xFF3A3A47);

  /// Subtle 1px divider for rows and groups.
  static const outlineVariant = Color(0xFF27272F);

  // ─── Primary (violet) ──────────────────────────────────────────────
  /// Brand violet — primary accent.
  static const primary = Color(0xFF8B5CF6);

  /// Foreground on top of [primary].
  static const Color onPrimary = white;

  /// Tonal background for primary-tinted surfaces.
  static const primaryContainer = Color(0xFF4C1D95);

  /// Foreground on top of [primaryContainer].
  static const onPrimaryContainer = Color(0xFFEDE9FE);

  /// Inverse primary used in dark-on-light contexts.
  static const inversePrimary = Color(0xFF6D28D9);

  // ─── Secondary ─────────────────────────────────────────────────────
  /// Lighter violet for secondary accents and links.
  static const secondary = Color(0xFFA78BFA);

  /// Foreground on top of [secondary] (dark for AA contrast).
  static const onSecondary = Color(0xFF1A0F33);

  /// Tonal background for secondary-tinted surfaces.
  static const secondaryContainer = Color(0xFF2D1A4F);

  /// Foreground on top of [secondaryContainer].
  static const onSecondaryContainer = Color(0xFFEDE9FE);

  // ─── Tertiary (cyan accent) ────────────────────────────────────────
  /// Cyan accent — used sparingly for highlights.
  static const tertiary = Color(0xFF22D3EE);

  /// Foreground on top of [tertiary].
  static const onTertiary = Color(0xFF051A1F);

  /// Tonal background for tertiary-tinted surfaces.
  static const tertiaryContainer = Color(0xFF155E75);

  /// Foreground on top of [tertiaryContainer].
  static const onTertiaryContainer = Color(0xFFCFFAFE);

  // ─── Semantic ──────────────────────────────────────────────────────
  /// Background for success states.
  static const success = Color(0xFF4ADE80);

  /// Foreground on top of [success].
  static const onSuccess = Color(0xFF052E14);

  /// Background for warning states.
  static const warning = Color(0xFFFACC15);

  /// Foreground on top of [warning].
  static const onWarning = Color(0xFF1A1300);

  /// Background for informational states.
  static const info = Color(0xFF60A5FA);

  /// Foreground on top of [info].
  static const onInfo = Color(0xFF051A33);

  /// Background for destructive / error states.
  static const danger = Color(0xFFF87171);

  /// Foreground on top of [danger].
  static const onDanger = Color(0xFF1A0606);

  /// Tonal background for destructive containers.
  static const dangerContainer = Color(0xFF7F1D1D);

  /// Foreground on top of [dangerContainer].
  static const onDangerContainer = Color(0xFFFEE2E2);
}
