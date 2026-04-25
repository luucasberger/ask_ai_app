import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AppRadii, () {
    const radii = AppRadii();

    test('has correct default values', () {
      expect(radii.xs, 4);
      expect(radii.sm, 8);
      expect(radii.md, 12);
      expect(radii.lg, 16);
      expect(radii.xl, 24);
    });

    test('copyWith returns a new instance with updated values', () {
      final updated = radii.copyWith(xs: 1, sm: 2, md: 3, lg: 4, xl: 5);
      expect(updated.xs, 1);
      expect(updated.sm, 2);
      expect(updated.md, 3);
      expect(updated.lg, 4);
      expect(updated.xl, 5);
    });

    test('copyWith returns identical instance when no values are provided', () {
      final copy = radii.copyWith();
      expect(copy.xs, radii.xs);
      expect(copy.sm, radii.sm);
      expect(copy.md, radii.md);
      expect(copy.lg, radii.lg);
      expect(copy.xl, radii.xl);
    });

    test('lerp returns this when other is not $AppRadii', () {
      final result = radii.lerp(null, 0.5);
      expect(result, radii);
    });

    test('lerp interpolates between two $AppRadii instances', () {
      const other = AppRadii(xs: 8, sm: 16, md: 24, lg: 32, xl: 48);
      final result = radii.lerp(other, 0.5);
      expect(result.xs, 6);
      expect(result.sm, 12);
      expect(result.md, 18);
      expect(result.lg, 24);
      expect(result.xl, 36);
    });
  });
}
