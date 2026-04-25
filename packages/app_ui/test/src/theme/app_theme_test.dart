import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    group('dark', () {
      test('returns a ThemeData', () {
        expect(AppTheme.dark, isA<ThemeData>());
      });

      test('has AppColors extension', () {
        expect(AppTheme.dark.extension<AppColors>(), isNotNull);
      });

      test('has AppSpacing extension', () {
        expect(AppTheme.dark.extension<AppSpacing>(), isNotNull);
      });

      test('has dark brightness', () {
        expect(AppTheme.dark.brightness, Brightness.dark);
      });
    });
  });
}
