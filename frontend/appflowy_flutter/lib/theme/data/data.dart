import 'package:appflowy/theme/border_radius/border_radius.dart';
import 'package:appflowy/theme/color_scheme/background/background_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/base/base_scheme.dart';
import 'package:appflowy/theme/color_scheme/border/border.dart';
import 'package:appflowy/theme/color_scheme/brand/brand_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/fill/fill.dart';
import 'package:appflowy/theme/color_scheme/icon/icon_color_theme.dart';
import 'package:appflowy/theme/color_scheme/surface/surface_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/text/text_color_scheme.dart';
import 'package:appflowy/theme/data/builder.dart';
import 'package:appflowy/theme/spacing/spacing.dart';
import 'package:appflowy/theme/text_style/text_style.dart';
import 'package:flutter/material.dart';

abstract class AppFlowyBaseTheme {
  const AppFlowyBaseTheme();

  AppFlowyBaseColorScheme get colorScheme;

  AppFlowyTextColorScheme get textColorScheme;

  AppFlowyBaseTextStyle get textStyle;

  AppFlowyIconColorTheme get iconColorTheme;

  AppFlowyBorderColorScheme get borderColorScheme;

  AppFlowyBackgroundColorScheme get backgroundColorScheme;

  AppFlowyFillColorScheme get fillColorScheme;

  AppFlowySurfaceColorScheme get surfaceColorScheme;

  AppFlowyBorderRadius get borderRadius;

  AppFlowySpacing get spacing;

  AppFlowyBrandColorScheme get brandColorScheme;
}

class AppFlowyThemeData extends AppFlowyBaseTheme {
  factory AppFlowyThemeData.light() {
    final colorScheme = AppFlowyBaseColorScheme();

    final textStyle = AppFlowyBaseTextStyle();
    final textColorScheme = themeBuilder.buildTextColorScheme(
      colorScheme,
      Brightness.light,
    );
    final borderColorScheme = themeBuilder.buildBorderColorScheme(
      colorScheme,
      Brightness.light,
    );
    final fillColorScheme = themeBuilder.buildFillColorScheme(
      colorScheme,
      Brightness.light,
    );
    final surfaceColorScheme = themeBuilder.buildSurfaceColorScheme(
      colorScheme,
      Brightness.light,
    );
    final backgroundColorScheme = themeBuilder.buildBackgroundColorScheme(
      colorScheme,
      Brightness.light,
    );
    final iconColorTheme = themeBuilder.buildIconColorTheme(
      colorScheme,
      Brightness.light,
    );
    final brandColorScheme = themeBuilder.buildBrandColorScheme(colorScheme);
    final borderRadius = themeBuilder.buildBorderRadius(colorScheme);
    final spacing = themeBuilder.buildSpacing(colorScheme);

    return AppFlowyThemeData(
      colorScheme: colorScheme,
      textColorScheme: textColorScheme,
      textStyle: textStyle,
      iconColorTheme: iconColorTheme,
      backgroundColorScheme: backgroundColorScheme,
      borderColorScheme: borderColorScheme,
      fillColorScheme: fillColorScheme,
      surfaceColorScheme: surfaceColorScheme,
      borderRadius: borderRadius,
      spacing: spacing,
      brandColorScheme: brandColorScheme,
    );
  }

  factory AppFlowyThemeData.dark() {
    final colorScheme = AppFlowyBaseColorScheme();
    final textStyle = AppFlowyBaseTextStyle();
    final textColorScheme = themeBuilder.buildTextColorScheme(
      colorScheme,
      Brightness.dark,
    );
    final borderColorScheme = themeBuilder.buildBorderColorScheme(
      colorScheme,
      Brightness.dark,
    );
    final fillColorScheme = themeBuilder.buildFillColorScheme(
      colorScheme,
      Brightness.dark,
    );
    final surfaceColorScheme = themeBuilder.buildSurfaceColorScheme(
      colorScheme,
      Brightness.dark,
    );
    final backgroundColorScheme = themeBuilder.buildBackgroundColorScheme(
      colorScheme,
      Brightness.dark,
    );
    final iconColorTheme = themeBuilder.buildIconColorTheme(
      colorScheme,
      Brightness.dark,
    );
    final brandColorScheme = themeBuilder.buildBrandColorScheme(colorScheme);
    final borderRadius = themeBuilder.buildBorderRadius(colorScheme);
    final spacing = themeBuilder.buildSpacing(colorScheme);

    return AppFlowyThemeData(
      colorScheme: colorScheme,
      textColorScheme: textColorScheme,
      textStyle: textStyle,
      iconColorTheme: iconColorTheme,
      backgroundColorScheme: backgroundColorScheme,
      borderColorScheme: borderColorScheme,
      fillColorScheme: fillColorScheme,
      surfaceColorScheme: surfaceColorScheme,
      borderRadius: borderRadius,
      spacing: spacing,
      brandColorScheme: brandColorScheme,
    );
  }

  const AppFlowyThemeData({
    required this.colorScheme,
    required this.textStyle,
    required this.textColorScheme,
    required this.borderColorScheme,
    required this.fillColorScheme,
    required this.surfaceColorScheme,
    required this.borderRadius,
    required this.spacing,
    required this.brandColorScheme,
    required this.iconColorTheme,
    required this.backgroundColorScheme,
    this.brightness = Brightness.light,
  });

  static const AppFlowyThemeBuilder themeBuilder = AppFlowyThemeBuilder();

  final Brightness brightness;

  @override
  final AppFlowyBaseColorScheme colorScheme;

  @override
  final AppFlowyBaseTextStyle textStyle;

  @override
  final AppFlowyTextColorScheme textColorScheme;

  @override
  final AppFlowyBorderColorScheme borderColorScheme;

  @override
  final AppFlowyFillColorScheme fillColorScheme;

  @override
  final AppFlowySurfaceColorScheme surfaceColorScheme;

  @override
  final AppFlowyBorderRadius borderRadius;

  @override
  final AppFlowySpacing spacing;

  @override
  final AppFlowyBrandColorScheme brandColorScheme;

  @override
  final AppFlowyIconColorTheme iconColorTheme;

  @override
  final AppFlowyBackgroundColorScheme backgroundColorScheme;

  static AppFlowyTextColorScheme buildTextColorScheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyTextColorScheme(
          primary: colorScheme.neutral.neutral1000,
          secondary: colorScheme.neutral.neutral600,
          tertiary: colorScheme.neutral.neutral400,
          quaternary: colorScheme.neutral.neutral200,
          inverse: colorScheme.neutral.white,
          onFill: colorScheme.neutral.white,
          theme: colorScheme.blue.blue500,
          themeHover: colorScheme.blue.blue600,
          action: colorScheme.blue.blue500,
          actionHover: colorScheme.blue.blue600,
          info: colorScheme.blue.blue500,
          infoHover: colorScheme.blue.blue600,
          success: colorScheme.green.green600,
          successHover: colorScheme.green.green700,
          warning: colorScheme.orange.orange600,
          warningHover: colorScheme.orange.orange700,
          error: colorScheme.red.red600,
          errorHover: colorScheme.red.red700,
          purple: colorScheme.purple.purple500,
          purpleHover: colorScheme.purple.purple600,
        ),
      Brightness.dark => AppFlowyTextColorScheme(
          primary: colorScheme.neutral.neutral200,
          secondary: colorScheme.neutral.neutral400,
          tertiary: colorScheme.neutral.neutral600,
          quaternary: colorScheme.neutral.neutral1000,
          inverse: colorScheme.neutral.neutral1000,
          onFill: colorScheme.neutral.white,
          theme: colorScheme.blue.blue500,
          themeHover: colorScheme.blue.blue600,
          action: colorScheme.blue.blue500,
          actionHover: colorScheme.blue.blue600,
          info: colorScheme.blue.blue500,
          infoHover: colorScheme.blue.blue600,
          success: colorScheme.green.green600,
          successHover: colorScheme.green.green700,
          warning: colorScheme.orange.orange600,
          warningHover: colorScheme.orange.orange700,
          error: colorScheme.red.red500,
          errorHover: colorScheme.red.red400,
          purple: colorScheme.purple.purple500,
          purpleHover: colorScheme.purple.purple600,
        ),
    };
  }
}
