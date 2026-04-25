import 'package:app_ui/app_ui.dart';
import 'package:app_ui/src/theme/theme.dart';

/// {@template app_theme}
/// Composes [ThemeData] with a curated [ColorScheme], the Geist
/// [TextTheme], and the [AppColors] / [AppSpacing] / [AppRadii]
/// [ThemeExtension]s. The app ships with a dark theme only.
///
/// All raw color values come from [ColorPalette].
/// {@endtemplate}
abstract final class AppTheme {
  static const _appColors = AppColors(
    borderSubtle: ColorPalette.outlineVariant,
    borderStrong: ColorPalette.outline,
    textMuted: ColorPalette.textMuted,
    success: ColorPalette.success,
    onSuccess: ColorPalette.onSuccess,
    warning: ColorPalette.warning,
    onWarning: ColorPalette.onWarning,
    info: ColorPalette.info,
    onInfo: ColorPalette.onInfo,
    danger: ColorPalette.danger,
    onDanger: ColorPalette.onDanger,
    userBubble: ColorPalette.primary,
    onUserBubble: ColorPalette.onPrimary,
    assistantBubble: ColorPalette.surfaceContainer,
    onAssistantBubble: ColorPalette.onSurface,
  );

  static const _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: ColorPalette.primary,
    onPrimary: ColorPalette.onPrimary,
    primaryContainer: ColorPalette.primaryContainer,
    onPrimaryContainer: ColorPalette.onPrimaryContainer,
    secondary: ColorPalette.secondary,
    onSecondary: ColorPalette.onSecondary,
    secondaryContainer: ColorPalette.secondaryContainer,
    onSecondaryContainer: ColorPalette.onSecondaryContainer,
    tertiary: ColorPalette.tertiary,
    onTertiary: ColorPalette.onTertiary,
    tertiaryContainer: ColorPalette.tertiaryContainer,
    onTertiaryContainer: ColorPalette.onTertiaryContainer,
    error: ColorPalette.danger,
    onError: ColorPalette.onDanger,
    errorContainer: ColorPalette.dangerContainer,
    onErrorContainer: ColorPalette.onDangerContainer,
    surface: ColorPalette.surface,
    onSurface: ColorPalette.onSurface,
    surfaceDim: ColorPalette.background,
    surfaceBright: ColorPalette.surfaceContainerHighest,
    surfaceContainerLowest: ColorPalette.background,
    surfaceContainerLow: ColorPalette.surfaceContainerLow,
    surfaceContainer: ColorPalette.surfaceContainer,
    surfaceContainerHigh: ColorPalette.surfaceContainerHigh,
    surfaceContainerHighest: ColorPalette.surfaceContainerHighest,
    onSurfaceVariant: ColorPalette.onSurfaceVariant,
    outline: ColorPalette.outline,
    outlineVariant: ColorPalette.outlineVariant,
    shadow: ColorPalette.black,
    scrim: ColorPalette.black,
    inverseSurface: ColorPalette.onSurface,
    onInverseSurface: ColorPalette.surface,
    inversePrimary: ColorPalette.inversePrimary,
    surfaceTint: ColorPalette.primary,
  );

  /// The dark [ThemeData].
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: ColorPalette.background,
      canvasColor: ColorPalette.background,
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(color: ColorPalette.onSurface, size: 22),
      dividerTheme: const DividerThemeData(
        color: ColorPalette.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.background,
        foregroundColor: ColorPalette.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: IconThemeData(color: ColorPalette.onSurface, size: 22),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: ColorPalette.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorPalette.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: ColorPalette.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorPalette.surfaceContainerHigh,
        modalBackgroundColor: ColorPalette.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(
            ColorPalette.surfaceContainerHigh,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ColorPalette.outlineVariant),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ColorPalette.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorPalette.outlineVariant),
        ),
        textStyle: AppTypography.bodyMedium,
      ),
      cardTheme: CardThemeData(
        color: ColorPalette.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ColorPalette.onSurfaceVariant,
        textColor: ColorPalette.onSurface,
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: ColorPalette.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.surfaceContainer,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: ColorPalette.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: ColorPalette.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.onSurface,
          side: const BorderSide(color: ColorPalette.outline),
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primary,
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ColorPalette.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorPalette.surfaceContainerHighest,
        contentTextStyle: AppTypography.bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorPalette.outlineVariant),
        ),
        textStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorPalette.primary,
        linearTrackColor: ColorPalette.surfaceContainer,
        circularTrackColor: ColorPalette.surfaceContainer,
      ),
      extensions: const [_appColors, AppSpacing(), AppRadii()],
    );
  }
}
