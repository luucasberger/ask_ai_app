import 'package:app_ui/app_ui.dart';
import 'package:app_ui/src/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AppTheme, () {
    group('dark', () {
      final theme = AppTheme.dark;

      test('returns a $ThemeData', () {
        expect(theme, isA<ThemeData>());
      });

      test('has dark brightness', () {
        expect(theme.brightness, Brightness.dark);
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('exposes $AppColors, $AppSpacing, and $AppRadii extensions', () {
        expect(theme.extension<AppColors>(), isNotNull);
        expect(theme.extension<AppSpacing>(), isNotNull);
        expect(theme.extension<AppRadii>(), isNotNull);
      });

      test('uses near-black scaffold background', () {
        expect(theme.scaffoldBackgroundColor, ColorPalette.background);
        expect(theme.canvasColor, ColorPalette.background);
      });

      test('uses violet primary on the color scheme', () {
        expect(theme.colorScheme.primary, ColorPalette.primary);
        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      test('text theme is Geist-based', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'packages/app_ui/Geist');
        expect(theme.textTheme.titleLarge?.fontFamily, 'packages/app_ui/Geist');
      });

      test('app bar theme is flat over the scaffold', () {
        expect(theme.appBarTheme.backgroundColor, ColorPalette.background);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.appBarTheme.centerTitle, isFalse);
      });

      test('drawer theme uses surfaceContainerLow', () {
        expect(
          theme.drawerTheme.backgroundColor,
          ColorPalette.surfaceContainerLow,
        );
        expect(theme.drawerTheme.elevation, 0);
      });

      test('dialog theme is rounded and surface-tinted', () {
        expect(
          theme.dialogTheme.backgroundColor,
          ColorPalette.surfaceContainerHigh,
        );
        expect(theme.dialogTheme.elevation, 0);
      });

      test('bottom sheet theme has a top-rounded shape and drag handle', () {
        expect(
          theme.bottomSheetTheme.backgroundColor,
          ColorPalette.surfaceContainerHigh,
        );
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });

      test('input decoration theme is filled with surfaceContainer', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(
          theme.inputDecorationTheme.fillColor,
          ColorPalette.surfaceContainer,
        );
      });

      test('divider theme uses outlineVariant', () {
        expect(theme.dividerTheme.color, ColorPalette.outlineVariant);
        expect(theme.dividerTheme.thickness, 1);
      });

      test('snack bar theme is floating', () {
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });

      test('progress indicator theme uses primary', () {
        expect(theme.progressIndicatorTheme.color, ColorPalette.primary);
      });

      test('list tile theme uses surface text + variant icons', () {
        expect(theme.listTileTheme.textColor, ColorPalette.onSurface);
        expect(theme.listTileTheme.iconColor, ColorPalette.onSurfaceVariant);
      });

      test('button themes are configured with rounded labels', () {
        expect(theme.filledButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(theme.iconButtonTheme.style, isNotNull);
      });

      test('menu and popup menu themes are configured', () {
        expect(theme.menuTheme.style, isNotNull);
        expect(theme.popupMenuTheme.color, ColorPalette.surfaceContainerHigh);
      });

      test('card theme uses surfaceContainer with no margin', () {
        expect(theme.cardTheme.color, ColorPalette.surfaceContainer);
        expect(theme.cardTheme.margin, EdgeInsets.zero);
      });

      test('tooltip theme uses surfaceContainerHighest', () {
        expect(theme.tooltipTheme.decoration, isA<BoxDecoration>());
      });
    });
  });
}
