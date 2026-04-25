import 'package:app_ui/app_ui.dart';

/// {@template app_theme}
/// Composes [ThemeData] with [ColorScheme.fromSeed] and custom
/// [ThemeExtension]s. The app ships with a dark theme only.
/// {@endtemplate}
class AppTheme {
  /// The dark [ThemeData].
  static ThemeData get dark {
    const appColors = AppColors(
      success: Color(0xFF4ADE80),
      onSuccess: Color(0xFF1C1B1F),
      warning: Color(0xFFFACC15),
      onWarning: Color(0xFF1C1B1F),
      info: Color(0xFF60A5FA),
      onInfo: Color(0xFF1C1B1F),
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
      ),
      extensions: const [appColors, AppSpacing()],
    );
  }
}
