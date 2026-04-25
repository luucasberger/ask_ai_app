import 'dart:ui';

import 'package:app_ui/app_ui.dart';

/// {@template app_radii}
/// Border-radius scale tokens for consistent rounding throughout the app.
///
/// Use [BorderRadius.circular] with one of these values, e.g.
/// `BorderRadius.circular(context.appRadii.md)`. For fully-rounded
/// shapes (pills, avatars), use [StadiumBorder] or a circle widget
/// instead of a numeric radius.
/// {@endtemplate}
class AppRadii extends ThemeExtension<AppRadii> {
  /// {@macro app_radii}
  const AppRadii({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
  });

  /// Extra small radius: 4px. Use for chips and tight controls.
  final double xs;

  /// Small radius: 8px. Use for inputs and small buttons.
  final double sm;

  /// Medium radius: 12px. Use for buttons, cards, and chat bubbles.
  final double md;

  /// Large radius: 16px. Use for dialogs and prominent surfaces.
  final double lg;

  /// Extra large radius: 24px. Use for sheets and hero surfaces.
  final double xl;

  @override
  AppRadii copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppRadii(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppRadii lerp(AppRadii? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}
