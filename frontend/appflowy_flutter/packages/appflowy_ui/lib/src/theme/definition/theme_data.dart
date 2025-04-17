import 'border_radius/border_radius.dart';
import 'color_scheme/color_scheme.dart';
import 'shadow/shadow.dart';
import 'spacing/spacing.dart';
import 'text_style/text_style.dart';

/// [AppFlowyThemeData] defines the structure of the design system, and contains
/// the data that all child widgets will have access to.
class AppFlowyThemeData {
  const AppFlowyThemeData({
    required this.textColorScheme,
    required this.textStyle,
    required this.iconColorScheme,
    required this.borderColorScheme,
    required this.backgroundColorScheme,
    required this.fillColorScheme,
    required this.surfaceColorScheme,
    required this.borderRadius,
    required this.spacing,
    required this.shadow,
    required this.brandColorScheme,
    required this.otherColorsColorScheme,
  });

  final AppFlowyTextColorScheme textColorScheme;

  final AppFlowyBaseTextStyle textStyle;

  final AppFlowyIconColorScheme iconColorScheme;

  final AppFlowyBorderColorScheme borderColorScheme;

  final AppFlowyBackgroundColorScheme backgroundColorScheme;

  final AppFlowyFillColorScheme fillColorScheme;

  final AppFlowySurfaceColorScheme surfaceColorScheme;

  final AppFlowyBorderRadius borderRadius;

  final AppFlowySpacing spacing;

  final AppFlowyShadow shadow;

  final AppFlowyBrandColorScheme brandColorScheme;

  final AppFlowyOtherColorsColorScheme otherColorsColorScheme;

  static AppFlowyThemeData lerp(
    AppFlowyThemeData begin,
    AppFlowyThemeData end,
    double t,
  ) {
    return AppFlowyThemeData(
      textColorScheme: begin.textColorScheme.lerp(end.textColorScheme, t),
      textStyle: end.textStyle,
      iconColorScheme: begin.iconColorScheme.lerp(end.iconColorScheme, t),
      borderColorScheme: begin.borderColorScheme.lerp(end.borderColorScheme, t),
      backgroundColorScheme:
          begin.backgroundColorScheme.lerp(end.backgroundColorScheme, t),
      fillColorScheme: begin.fillColorScheme.lerp(end.fillColorScheme, t),
      surfaceColorScheme:
          begin.surfaceColorScheme.lerp(end.surfaceColorScheme, t),
      borderRadius: end.borderRadius,
      spacing: end.spacing,
      shadow: end.shadow,
      brandColorScheme: begin.brandColorScheme.lerp(end.brandColorScheme, t),
      otherColorsColorScheme:
          begin.otherColorsColorScheme.lerp(end.otherColorsColorScheme, t),
    );
  }
}

/// [AppFlowyThemeBuilder] is used to build the light and dark themes. Extend
/// this class to create a built-in theme, or use the [CustomTheme] class to
/// create a custom theme from JSON data.
///
/// See also:
///
/// - [AppFlowyThemeData] for the main theme data class.
abstract class AppFlowyThemeBuilder {
  const AppFlowyThemeBuilder();

  AppFlowyThemeData light();
  AppFlowyThemeData dark();
}
