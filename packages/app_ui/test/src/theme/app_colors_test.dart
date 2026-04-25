import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AppColors, () {
    const colors = AppColors(
      borderSubtle: Color(0xFF111111),
      borderStrong: Color(0xFF222222),
      textMuted: Color(0xFF333333),
      success: Color(0xFF16A34A),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFCA8A04),
      onWarning: Color(0xFFFFFFFF),
      info: Color(0xFF2563EB),
      onInfo: Color(0xFFFFFFFF),
      danger: Color(0xFFDC2626),
      onDanger: Color(0xFFFFFFFF),
      userBubble: Color(0xFF8B5CF6),
      onUserBubble: Color(0xFFFFFFFF),
      assistantBubble: Color(0xFF1C1C24),
      onAssistantBubble: Color(0xFFF5F5F7),
    );

    test('copyWith returns a new instance with updated values', () {
      final updated = colors.copyWith(
        borderSubtle: const Color(0xFFAAAAAA),
        borderStrong: const Color(0xFFBBBBBB),
        textMuted: const Color(0xFFCCCCCC),
        success: const Color(0xFF000001),
        onSuccess: const Color(0xFF000002),
        warning: const Color(0xFF000003),
        onWarning: const Color(0xFF000004),
        info: const Color(0xFF000005),
        onInfo: const Color(0xFF000006),
        danger: const Color(0xFF000007),
        onDanger: const Color(0xFF000008),
        userBubble: const Color(0xFF000009),
        onUserBubble: const Color(0xFF00000A),
        assistantBubble: const Color(0xFF00000B),
        onAssistantBubble: const Color(0xFF00000C),
      );
      expect(updated.borderSubtle, const Color(0xFFAAAAAA));
      expect(updated.borderStrong, const Color(0xFFBBBBBB));
      expect(updated.textMuted, const Color(0xFFCCCCCC));
      expect(updated.success, const Color(0xFF000001));
      expect(updated.onSuccess, const Color(0xFF000002));
      expect(updated.warning, const Color(0xFF000003));
      expect(updated.onWarning, const Color(0xFF000004));
      expect(updated.info, const Color(0xFF000005));
      expect(updated.onInfo, const Color(0xFF000006));
      expect(updated.danger, const Color(0xFF000007));
      expect(updated.onDanger, const Color(0xFF000008));
      expect(updated.userBubble, const Color(0xFF000009));
      expect(updated.onUserBubble, const Color(0xFF00000A));
      expect(updated.assistantBubble, const Color(0xFF00000B));
      expect(updated.onAssistantBubble, const Color(0xFF00000C));
    });

    test('copyWith returns identical instance when no values are provided', () {
      final copy = colors.copyWith();
      expect(copy.borderSubtle, colors.borderSubtle);
      expect(copy.borderStrong, colors.borderStrong);
      expect(copy.textMuted, colors.textMuted);
      expect(copy.success, colors.success);
      expect(copy.onSuccess, colors.onSuccess);
      expect(copy.warning, colors.warning);
      expect(copy.onWarning, colors.onWarning);
      expect(copy.info, colors.info);
      expect(copy.onInfo, colors.onInfo);
      expect(copy.danger, colors.danger);
      expect(copy.onDanger, colors.onDanger);
      expect(copy.userBubble, colors.userBubble);
      expect(copy.onUserBubble, colors.onUserBubble);
      expect(copy.assistantBubble, colors.assistantBubble);
      expect(copy.onAssistantBubble, colors.onAssistantBubble);
    });

    test('lerp returns this when other is not $AppColors', () {
      final result = colors.lerp(null, 0.5);
      expect(result, colors);
    });

    test('lerp interpolates between two $AppColors', () {
      const other = AppColors(
        borderSubtle: Color(0xFF000000),
        borderStrong: Color(0xFF000000),
        textMuted: Color(0xFF000000),
        success: Color(0xFF000000),
        onSuccess: Color(0xFF000000),
        warning: Color(0xFF000000),
        onWarning: Color(0xFF000000),
        info: Color(0xFF000000),
        onInfo: Color(0xFF000000),
        danger: Color(0xFF000000),
        onDanger: Color(0xFF000000),
        userBubble: Color(0xFF000000),
        onUserBubble: Color(0xFF000000),
        assistantBubble: Color(0xFF000000),
        onAssistantBubble: Color(0xFF000000),
      );

      final result = colors.lerp(other, 0.5);
      expect(result.borderSubtle, isNotNull);
      expect(result.borderStrong, isNotNull);
      expect(result.textMuted, isNotNull);
      expect(result.success, isNotNull);
      expect(result.onSuccess, isNotNull);
      expect(result.warning, isNotNull);
      expect(result.onWarning, isNotNull);
      expect(result.info, isNotNull);
      expect(result.onInfo, isNotNull);
      expect(result.danger, isNotNull);
      expect(result.onDanger, isNotNull);
      expect(result.userBubble, isNotNull);
      expect(result.onUserBubble, isNotNull);
      expect(result.assistantBubble, isNotNull);
      expect(result.onAssistantBubble, isNotNull);
    });
  });
}
