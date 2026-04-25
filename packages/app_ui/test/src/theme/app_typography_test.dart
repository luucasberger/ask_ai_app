import 'package:app_ui/app_ui.dart';
import 'package:app_ui/src/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AppTypography, () {
    const allStyles = <TextStyle>[
      AppTypography.displayLarge,
      AppTypography.displayMedium,
      AppTypography.displaySmall,
      AppTypography.headlineLarge,
      AppTypography.headlineMedium,
      AppTypography.headlineSmall,
      AppTypography.titleLarge,
      AppTypography.titleMedium,
      AppTypography.titleSmall,
      AppTypography.bodyLarge,
      AppTypography.bodyMedium,
      AppTypography.bodySmall,
      AppTypography.labelLarge,
      AppTypography.labelMedium,
      AppTypography.labelSmall,
    ];

    test('exposes Geist font family from app_ui package', () {
      expect(AppTypography.fontFamily, 'Geist');
      expect(AppTypography.package, 'app_ui');
    });

    test('all static styles use Geist with the package prefix', () {
      for (final style in allStyles) {
        expect(style.fontFamily, 'packages/app_ui/Geist');
      }
    });

    test('all static styles default to ${ColorPalette.onSurface}', () {
      for (final style in allStyles) {
        expect(style.color, ColorPalette.onSurface);
      }
    });

    test('display tier uses Bold (w700) and shrinks from large to small', () {
      expect(AppTypography.displayLarge.fontWeight, FontWeight.w700);
      expect(AppTypography.displayMedium.fontWeight, FontWeight.w700);
      expect(AppTypography.displaySmall.fontWeight, FontWeight.w700);

      expect(
        AppTypography.displayLarge.fontSize,
        greaterThan(AppTypography.displayMedium.fontSize!),
      );
      expect(
        AppTypography.displayMedium.fontSize,
        greaterThan(AppTypography.displaySmall.fontSize!),
      );
    });

    test('headline tier uses SemiBold (w600)', () {
      expect(AppTypography.headlineLarge.fontWeight, FontWeight.w600);
      expect(AppTypography.headlineMedium.fontWeight, FontWeight.w600);
      expect(AppTypography.headlineSmall.fontWeight, FontWeight.w600);
    });

    test('body tier uses Regular (w400)', () {
      expect(AppTypography.bodyLarge.fontWeight, FontWeight.w400);
      expect(AppTypography.bodyMedium.fontWeight, FontWeight.w400);
      expect(AppTypography.bodySmall.fontWeight, FontWeight.w400);
    });

    test('label tier uses Medium (w500)', () {
      expect(AppTypography.labelLarge.fontWeight, FontWeight.w500);
      expect(AppTypography.labelMedium.fontWeight, FontWeight.w500);
      expect(AppTypography.labelSmall.fontWeight, FontWeight.w500);
    });

    group('textTheme', () {
      const theme = AppTypography.textTheme;

      test('every slot is populated with the matching static style', () {
        expect(theme.displayLarge, AppTypography.displayLarge);
        expect(theme.displayMedium, AppTypography.displayMedium);
        expect(theme.displaySmall, AppTypography.displaySmall);
        expect(theme.headlineLarge, AppTypography.headlineLarge);
        expect(theme.headlineMedium, AppTypography.headlineMedium);
        expect(theme.headlineSmall, AppTypography.headlineSmall);
        expect(theme.titleLarge, AppTypography.titleLarge);
        expect(theme.titleMedium, AppTypography.titleMedium);
        expect(theme.titleSmall, AppTypography.titleSmall);
        expect(theme.bodyLarge, AppTypography.bodyLarge);
        expect(theme.bodyMedium, AppTypography.bodyMedium);
        expect(theme.bodySmall, AppTypography.bodySmall);
        expect(theme.labelLarge, AppTypography.labelLarge);
        expect(theme.labelMedium, AppTypography.labelMedium);
        expect(theme.labelSmall, AppTypography.labelSmall);
      });
    });
  });
}
