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

  AppFlowyThemeData lerp(
    AppFlowyThemeData other,
    double t,
  ) {
    return AppFlowyThemeData(
      textColorScheme: textColorScheme.lerp(other.textColorScheme, t),
      textStyle: other.textStyle,
      iconColorScheme: iconColorScheme.lerp(other.iconColorScheme, t),
      borderColorScheme: borderColorScheme.lerp(other.borderColorScheme, t),
      backgroundColorScheme:
          backgroundColorScheme.lerp(other.backgroundColorScheme, t),
      fillColorScheme: fillColorScheme.lerp(other.fillColorScheme, t),
      surfaceColorScheme: surfaceColorScheme.lerp(other.surfaceColorScheme, t),
      borderRadius: other.borderRadius,
      spacing: other.spacing,
      shadow: other.shadow,
      brandColorScheme: brandColorScheme.lerp(other.brandColorScheme, t),
      otherColorsColorScheme:
          otherColorsColorScheme.lerp(other.otherColorsColorScheme, t),
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
