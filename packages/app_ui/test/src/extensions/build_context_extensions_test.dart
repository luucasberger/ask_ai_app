import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AppThemeBuildContext', () {
    testWidgets('appColors returns $AppColors from theme', (tester) async {
      late AppColors colors;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            colors = context.appColors;
            return const SizedBox();
          },
        ),
      );

      expect(colors, isA<AppColors>());
    });

    testWidgets('appSpacing returns $AppSpacing from theme', (tester) async {
      late AppSpacing spacing;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            spacing = context.appSpacing;
            return const SizedBox();
          },
        ),
      );

      expect(spacing, isA<AppSpacing>());
    });

    testWidgets('appRadii returns $AppRadii from theme', (tester) async {
      late AppRadii radii;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            radii = context.appRadii;
            return const SizedBox();
          },
        ),
      );

      expect(radii, isA<AppRadii>());
    });

    testWidgets('textTheme returns $TextTheme from theme', (tester) async {
      late TextTheme textTheme;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            textTheme = context.textTheme;
            return const SizedBox();
          },
        ),
      );

      expect(textTheme, isA<TextTheme>());
      expect(textTheme.bodyMedium, isNotNull);
    });

    testWidgets('colorScheme returns $ColorScheme from theme', (tester) async {
      late ColorScheme colorScheme;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            colorScheme = context.colorScheme;
            return const SizedBox();
          },
        ),
      );

      expect(colorScheme, isA<ColorScheme>());
      expect(colorScheme.brightness, Brightness.dark);
    });
  });
}
