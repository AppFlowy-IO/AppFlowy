import 'border_radius/border_radius.dart';
import 'color_scheme/color_scheme.dart';
import 'shadow/shadow.dart';
import 'spacing/spacing.dart';
import 'text_style/text_style.dart';

abstract class AppFlowyBaseThemeData {
  const AppFlowyBaseThemeData();

  AppFlowyTextColorScheme get textColorScheme;

  AppFlowyBaseTextStyle get textStyle;

  AppFlowyIconColorScheme get iconColorScheme;

  AppFlowyBorderColorScheme get borderColorScheme;

  AppFlowyBackgroundColorScheme get backgroundColorScheme;

  AppFlowyFillColorScheme get fillColorScheme;

  AppFlowySurfaceColorScheme get surfaceColorScheme;

  AppFlowyBorderRadius get borderRadius;

  AppFlowySpacing get spacing;

  AppFlowyShadow get shadow;

  AppFlowyBrandColorScheme get brandColorScheme;

  AppFlowyOtherColorsColorScheme get otherColorsColorScheme;
}
