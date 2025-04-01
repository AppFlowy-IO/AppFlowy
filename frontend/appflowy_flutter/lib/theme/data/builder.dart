import 'package:appflowy/theme/border_radius/border_radius.dart';
import 'package:appflowy/theme/color_scheme/background/background_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/base/base_scheme.dart';
import 'package:appflowy/theme/color_scheme/border/border.dart';
import 'package:appflowy/theme/color_scheme/brand/brand_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/fill/fill.dart';
import 'package:appflowy/theme/color_scheme/icon/icon_color_theme.dart';
import 'package:appflowy/theme/color_scheme/surface/surface_color_scheme.dart';
import 'package:appflowy/theme/color_scheme/text/text_color_scheme.dart';
import 'package:appflowy/theme/dimensions.dart';
import 'package:appflowy/theme/spacing/spacing.dart';
import 'package:flutter/material.dart';

class AppFlowyThemeBuilder {
  const AppFlowyThemeBuilder();

  AppFlowyTextColorScheme buildTextColorScheme(
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

  AppFlowyIconColorTheme buildIconColorTheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyIconColorTheme(
          primary: colorScheme.neutral.neutral1000,
          secondary: colorScheme.neutral.neutral600,
          tertiary: colorScheme.neutral.neutral400,
          quaternary: colorScheme.neutral.neutral200,
          white: colorScheme.neutral.white,
          purpleThick: colorScheme.purple.purple500,
          purpleThickHover: colorScheme.purple.purple600,
        ),
      Brightness.dark => AppFlowyIconColorTheme(
          primary: colorScheme.neutral.neutral200,
          secondary: colorScheme.neutral.neutral400,
          tertiary: colorScheme.neutral.neutral600,
          quaternary: colorScheme.neutral.neutral1000,
          white: colorScheme.neutral.white,
          purpleThick: const Color(0xFFFFFFFF),
          purpleThickHover: const Color(0xFFFFFFFF),
        ),
    };
  }

  AppFlowyBorderColorScheme buildBorderColorScheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyBorderColorScheme(
          greyPrimary: colorScheme.neutral.neutral1000,
          greyPrimaryHover: colorScheme.neutral.neutral900,
          greySecondary: colorScheme.neutral.neutral800,
          greySecondaryHover: colorScheme.neutral.neutral700,
          greyTertiary: colorScheme.neutral.neutral300,
          greyTertiaryHover: colorScheme.neutral.neutral400,
          greyQuaternary: colorScheme.neutral.neutral100,
          greyQuaternaryHover: colorScheme.neutral.neutral200,
          transparent: colorScheme.neutral.alphaWhite0,
          themeThick: colorScheme.blue.blue500,
          themeThickHover: colorScheme.blue.blue600,
          infoThick: colorScheme.blue.blue500,
          infoThickHover: colorScheme.blue.blue600,
          successThick: colorScheme.green.green600,
          successThickHover: colorScheme.green.green700,
          warningThick: colorScheme.orange.orange600,
          warningThickHover: colorScheme.orange.orange700,
          errorThick: colorScheme.red.red600,
          errorThickHover: colorScheme.red.red700,
          purpleThick: colorScheme.purple.purple500,
          purpleThickHover: colorScheme.purple.purple600,
        ),
      Brightness.dark => AppFlowyBorderColorScheme(
          greyPrimary: colorScheme.neutral.neutral100,
          greyPrimaryHover: colorScheme.neutral.neutral200,
          greySecondary: colorScheme.neutral.neutral300,
          greySecondaryHover: colorScheme.neutral.neutral400,
          greyTertiary: colorScheme.neutral.neutral800,
          greyTertiaryHover: colorScheme.neutral.neutral700,
          greyQuaternary: colorScheme.neutral.neutral1000,
          greyQuaternaryHover: colorScheme.neutral.neutral900,
          transparent: colorScheme.neutral.alphaWhite0,
          themeThick: colorScheme.blue.blue500,
          themeThickHover: colorScheme.blue.blue600,
          infoThick: colorScheme.blue.blue500,
          infoThickHover: colorScheme.blue.blue600,
          successThick: colorScheme.green.green600,
          successThickHover: colorScheme.green.green700,
          warningThick: colorScheme.orange.orange600,
          warningThickHover: colorScheme.orange.orange700,
          errorThick: colorScheme.red.red500,
          errorThickHover: colorScheme.red.red400,
          purpleThick: colorScheme.purple.purple500,
          purpleThickHover: colorScheme.purple.purple600,
        ),
    };
  }

  AppFlowyFillColorScheme buildFillColorScheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyFillColorScheme(
          primary: colorScheme.neutral.neutral100,
          primaryHover: colorScheme.neutral.neutral200,
          secondary: colorScheme.neutral.neutral300,
          secondaryHover: colorScheme.neutral.neutral400,
          tertiary: colorScheme.neutral.neutral600,
          tertiaryHover: colorScheme.neutral.neutral500,
          quaternary: colorScheme.neutral.neutral1000,
          quaternaryHover: colorScheme.neutral.neutral900,
          transparent: colorScheme.neutral.alphaWhite0,
          primaryAlpha5: colorScheme.neutral.alphaGrey10005,
          primaryAlpha5Hover: colorScheme.neutral.alphaGrey10010,
          primaryAlpha80: colorScheme.neutral.alphaGrey100080,
          primaryAlpha80Hover: colorScheme.neutral.alphaGrey100070,
          white: colorScheme.neutral.white,
          whiteAlpha: colorScheme.neutral.alphaWhite20,
          whiteAlphaHover: colorScheme.neutral.alphaWhite30,
          black: colorScheme.neutral.black,
          themeLight: colorScheme.blue.blue100,
          themeLightHover: colorScheme.blue.blue200,
          themeThick: colorScheme.blue.blue500,
          themeThickHover: colorScheme.blue.blue400,
          themeSelect: colorScheme.blue.alphaBlue50015,
          infoLight: colorScheme.blue.blue100,
          infoLightHover: colorScheme.blue.blue200,
          infoThick: colorScheme.blue.blue500,
          infoThickHover: colorScheme.blue.blue600,
          successLight: colorScheme.green.green100,
          successLightHover: colorScheme.green.green200,
          successThick: colorScheme.green.green600,
          successThickHover: colorScheme.green.green700,
          warningLight: colorScheme.orange.orange100,
          warningLightHover: colorScheme.orange.orange200,
          warningThick: colorScheme.orange.orange600,
          warningThickHover: colorScheme.orange.orange700,
          errorLight: colorScheme.red.red100,
          errorLightHover: colorScheme.red.red200,
          errorThick: colorScheme.red.red600,
          errorThickHover: colorScheme.red.red500,
          errorSelect: colorScheme.red.alphaRed50010,
          purpleLight: colorScheme.purple.purple100,
          purpleLightHover: colorScheme.purple.purple200,
          purpleThick: colorScheme.purple.purple500,
          purpleThickHover: colorScheme.purple.purple600,
        ),
      Brightness.dark => AppFlowyFillColorScheme(
          primary: colorScheme.neutral.neutral1000,
          primaryHover: colorScheme.neutral.neutral900,
          secondary: colorScheme.neutral.neutral600,
          secondaryHover: colorScheme.neutral.neutral500,
          tertiary: colorScheme.neutral.neutral300,
          tertiaryHover: colorScheme.neutral.neutral400,
          quaternary: colorScheme.neutral.neutral100,
          quaternaryHover: colorScheme.neutral.neutral200,
          transparent: colorScheme.neutral.alphaWhite0,
          primaryAlpha5: colorScheme.neutral.alphaGrey100005,
          primaryAlpha5Hover: colorScheme.neutral.alphaGrey100010,
          primaryAlpha80: colorScheme.neutral.alphaGrey100080,
          primaryAlpha80Hover: colorScheme.neutral.alphaGrey100070,
          white: colorScheme.neutral.white,
          whiteAlpha: colorScheme.neutral.alphaWhite20,
          whiteAlphaHover: colorScheme.neutral.alphaWhite30,
          black: colorScheme.neutral.black,
          themeLight: colorScheme.blue.blue100,
          themeLightHover: colorScheme.blue.blue200,
          themeThick: colorScheme.blue.blue500,
          themeThickHover: colorScheme.blue.blue600,
          themeSelect: colorScheme.blue.alphaBlue50015,
          infoLight: colorScheme.blue.blue100,
          infoLightHover: colorScheme.blue.blue200,
          infoThick: colorScheme.blue.blue500,
          infoThickHover: colorScheme.blue.blue600,
          successLight: colorScheme.green.green100,
          successLightHover: colorScheme.green.green200,
          successThick: colorScheme.green.green600,
          successThickHover: colorScheme.green.green700,
          warningLight: colorScheme.orange.orange100,
          warningLightHover: colorScheme.orange.orange200,
          warningThick: colorScheme.orange.orange600,
          warningThickHover: colorScheme.orange.orange700,
          errorLight: colorScheme.red.red100,
          errorLightHover: colorScheme.red.red200,
          errorThick: colorScheme.red.red600,
          errorThickHover: colorScheme.red.red700,
          errorSelect: colorScheme.red.alphaRed50010,
          purpleLight: colorScheme.purple.purple100,
          purpleLightHover: colorScheme.purple.purple200,
          purpleThick: colorScheme.purple.purple500,
          purpleThickHover: colorScheme.purple.purple600,
        ),
    };
  }

  AppFlowySurfaceColorScheme buildSurfaceColorScheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowySurfaceColorScheme(
          primary: colorScheme.neutral.white,
          overlay: colorScheme.neutral.alphaBlack60,
        ),
      Brightness.dark => AppFlowySurfaceColorScheme(
          primary: colorScheme.neutral.neutral900,
          overlay: colorScheme.neutral.alphaBlack60,
        ),
    };
  }

  AppFlowyBackgroundColorScheme buildBackgroundColorScheme(
    AppFlowyBaseColorScheme colorScheme,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyBackgroundColorScheme(
          primary: colorScheme.neutral.white,
          secondary: colorScheme.neutral.neutral100,
          tertiary: colorScheme.neutral.neutral200,
          quaternary: colorScheme.neutral.neutral300,
        ),
      Brightness.dark => AppFlowyBackgroundColorScheme(
          primary: colorScheme.neutral.neutral1000,
          secondary: colorScheme.neutral.neutral900,
          tertiary: colorScheme.neutral.neutral800,
          quaternary: colorScheme.neutral.neutral700,
        ),
    };
  }

  AppFlowyBrandColorScheme buildBrandColorScheme(
    AppFlowyBaseColorScheme colorScheme,
  ) {
    return AppFlowyBrandColorScheme(
      skyline: const Color(0xFF00B5FF),
      aqua: const Color(0xFF00C8FF),
      violet: const Color(0xFF9327FF),
      amethyst: const Color(0xFF8427E0),
      berry: const Color(0xFFE3006D),
      coral: const Color(0xFFFB006D),
      golden: const Color(0xFFF7931E),
      amber: const Color(0xFFFFBD00),
      lemon: const Color(0xFFFFCE00),
    );
  }

  AppFlowyBorderRadius buildBorderRadius(
    AppFlowyBaseColorScheme colorScheme,
  ) {
    return AppFlowyBorderRadius(
      radius0: AppFlowyBorderRadiusConstant.radius0,
      radiusXs: AppFlowyBorderRadiusConstant.radius100,
      radiusS: AppFlowyBorderRadiusConstant.radius200,
      radiusM: AppFlowyBorderRadiusConstant.radius300,
      radiusL: AppFlowyBorderRadiusConstant.radius400,
      radiusXl: AppFlowyBorderRadiusConstant.radius500,
      radiusXxl: AppFlowyBorderRadiusConstant.radius600,
      radiusFull: AppFlowyBorderRadiusConstant.radius1000,
    );
  }

  AppFlowySpacing buildSpacing(
    AppFlowyBaseColorScheme colorScheme,
  ) {
    return AppFlowySpacing(
      spacing0: AppFlowySpacingConstant.spacing0,
      spacingXs: AppFlowySpacingConstant.spacing100,
      spacingS: AppFlowySpacingConstant.spacing200,
      spacingM: AppFlowySpacingConstant.spacing300,
      spacingL: AppFlowySpacingConstant.spacing400,
      spacingXl: AppFlowySpacingConstant.spacing500,
      spacingXxl: AppFlowySpacingConstant.spacing600,
      spacingFull: AppFlowySpacingConstant.spacing1000,
    );
  }
}
