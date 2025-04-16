import 'border_radius/border_radius.dart';
import 'color_scheme/color_scheme.dart';
import 'shadow/shadow.dart';
import 'spacing/spacing.dart';
import 'text_style/text_style.dart';

class AppFlowyBaseThemeData {
  const AppFlowyBaseThemeData({
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

  AppFlowyBaseThemeData lerp(
    AppFlowyBaseThemeData other,
    double t,
  ) {
    return AppFlowyBaseThemeData(
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
