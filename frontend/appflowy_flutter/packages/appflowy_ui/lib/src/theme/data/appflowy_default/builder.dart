import 'package:appflowy_ui/src/theme/definition/border_radius/border_radius.dart';
import 'package:appflowy_ui/src/theme/dimensions.dart';
import 'package:appflowy_ui/src/theme/definition/shadow/shadow.dart';
import 'package:appflowy_ui/src/theme/definition/spacing/spacing.dart';
import 'package:flutter/material.dart';

class AppFlowyThemeBuilder {
  const AppFlowyThemeBuilder();

  AppFlowyBorderRadius buildBorderRadius() {
    return AppFlowyBorderRadius(
      xs: AppFlowyBorderRadiusConstant.radius100,
      s: AppFlowyBorderRadiusConstant.radius200,
      m: AppFlowyBorderRadiusConstant.radius300,
      l: AppFlowyBorderRadiusConstant.radius400,
      xl: AppFlowyBorderRadiusConstant.radius500,
      xxl: AppFlowyBorderRadiusConstant.radius600,
    );
  }

  AppFlowySpacing buildSpacing() {
    return AppFlowySpacing(
      xs: AppFlowySpacingConstant.spacing100,
      s: AppFlowySpacingConstant.spacing200,
      m: AppFlowySpacingConstant.spacing300,
      l: AppFlowySpacingConstant.spacing400,
      xl: AppFlowySpacingConstant.spacing500,
      xxl: AppFlowySpacingConstant.spacing600,
    );
  }

  AppFlowyShadow buildShadow(
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => AppFlowyShadow(
          small: [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 16,
              color: Color(0x1F000000),
            ),
          ],
          medium: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 32,
              color: Color(0x1F000000),
            ),
          ],
        ),
      Brightness.dark => AppFlowyShadow(
          small: [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 16,
              color: Color(0x7A000000),
            ),
          ],
          medium: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 32,
              color: Color(0x7A000000),
            ),
          ],
        ),
    };
  }
}
