import 'package:app_ui/app_ui.dart';

/// Extension on [BuildContext] for easy access to custom theme tokens.
extension AppThemeBuildContext on BuildContext {
  /// Returns the [AppColors] from the current theme.
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;

  /// Returns the [AppSpacing] from the current theme.
  AppSpacing get appSpacing => Theme.of(this).extension<AppSpacing>()!;

  /// Returns the [AppRadii] from the current theme.
  AppRadii get appRadii => Theme.of(this).extension<AppRadii>()!;

  /// Returns the [TextTheme] from the current theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns the [ColorScheme] from the current theme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
