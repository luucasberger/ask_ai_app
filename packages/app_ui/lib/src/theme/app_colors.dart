import 'package:app_ui/app_ui.dart';

/// {@template app_colors}
/// Custom color tokens beyond Material's [ColorScheme].
///
/// Provides semantic colors (success, warning, info, danger), surface
/// borders, muted text, and chat-bubble colors used by the conversation
/// view. All values are tuned for a near-black dark theme.
/// {@endtemplate}
class AppColors extends ThemeExtension<AppColors> {
  /// {@macro app_colors}
  const AppColors({
    required this.borderSubtle,
    required this.borderStrong,
    required this.textMuted,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.danger,
    required this.onDanger,
    required this.userBubble,
    required this.onUserBubble,
    required this.assistantBubble,
    required this.onAssistantBubble,
  });

  /// Subtle 1px divider color used between rows and cards.
  final Color borderSubtle;

  /// Stronger border color used for outlined controls.
  final Color borderStrong;

  /// Tertiary text color for hints and disabled labels.
  final Color textMuted;

  /// Background color for success states.
  final Color success;

  /// Foreground color used on top of [success].
  final Color onSuccess;

  /// Background color for warning states.
  final Color warning;

  /// Foreground color used on top of [warning].
  final Color onWarning;

  /// Background color for informational states.
  final Color info;

  /// Foreground color used on top of [info].
  final Color onInfo;

  /// Background color for destructive states.
  final Color danger;

  /// Foreground color used on top of [danger].
  final Color onDanger;

  /// Background color of the user's chat bubble.
  final Color userBubble;

  /// Foreground color used on top of [userBubble].
  final Color onUserBubble;

  /// Background color of the assistant's chat bubble.
  final Color assistantBubble;

  /// Foreground color used on top of [assistantBubble].
  final Color onAssistantBubble;

  @override
  AppColors copyWith({
    Color? borderSubtle,
    Color? borderStrong,
    Color? textMuted,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? danger,
    Color? onDanger,
    Color? userBubble,
    Color? onUserBubble,
    Color? assistantBubble,
    Color? onAssistantBubble,
  }) {
    return AppColors(
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      userBubble: userBubble ?? this.userBubble,
      onUserBubble: onUserBubble ?? this.onUserBubble,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      onAssistantBubble: onAssistantBubble ?? this.onAssistantBubble,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      onUserBubble: Color.lerp(onUserBubble, other.onUserBubble, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      onAssistantBubble: Color.lerp(
        onAssistantBubble,
        other.onAssistantBubble,
        t,
      )!,
    );
  }
}
