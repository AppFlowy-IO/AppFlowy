import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class DesktopAppearance extends BaseAppearance {
  @override
  ThemeData getThemeData(
    AppTheme appTheme,
    Brightness brightness,
    String fontFamily,
    String codeFontFamily,
  ) {
    assert(codeFontFamily.isNotEmpty);

    final theme = brightness == Brightness.light
        ? appTheme.lightTheme
        : appTheme.darkTheme;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: theme.primary,
      onPrimary: theme.onPrimary,
      primaryContainer: theme.main2,
      onPrimaryContainer: white,
      // page title hover color
      secondary: theme.hoverBG1,
      onSecondary: theme.shader1,
      // setting value hover color
      secondaryContainer: theme.selector,
      onSecondaryContainer: theme.topbarBg,
      tertiary: theme.shader7,
      // Editor: toolbarColor
      onTertiary: theme.toolbarColor,
      tertiaryContainer: theme.questionBubbleBG,
      surface: theme.surface,
      // text&icon color when it is hovered
      onSurface: theme.hoverFG,
      // grey hover color
      inverseSurface: theme.hoverBG3,
      onError: theme.onPrimary,
      error: theme.red,
      outline: theme.shader4,
      surfaceContainerHighest: theme.sidebarBg,
      shadow: theme.shadow,
    );

    // Due to Desktop version has multiple themes, it relies on the current theme to build the ThemeData
    return ThemeData(
      visualDensity: VisualDensity.standard,
      useMaterial3: false,
      brightness: brightness,
      dialogBackgroundColor: theme.surface,
      textTheme: getTextTheme(
        fontFamily: fontFamily,
        fontColor: theme.text,
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.zero),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.main2,
        selectionHandleColor: theme.main2,
      ),
      iconTheme: IconThemeData(color: theme.icon),
      tooltipTheme: TooltipThemeData(
        textStyle: getFontStyle(
          fontFamily: fontFamily,
          fontSize: FontSizes.s11,
          fontWeight: FontWeight.w400,
          fontColor: theme.surface,
        ),
      ),
      scaffoldBackgroundColor: theme.surface,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.any(scrollbarInteractiveStates.contains)
              ? theme.scrollbarHoverColor
              : theme.scrollbarColor,
        ),
        thickness: WidgetStateProperty.resolveWith((_) => 4.0),
        crossAxisMargin: 0.0,
        mainAxisMargin: 6.0,
        radius: Corners.s10Radius,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //dropdown menu color
      canvasColor: theme.surface,
      dividerColor: theme.divider,
      hintColor: theme.hint,
      //action item hover color
      hoverColor: theme.hoverBG2,
      disabledColor: theme.shader4,
      highlightColor: theme.main1,
      indicatorColor: theme.main1,
      cardColor: theme.input,
      colorScheme: colorScheme,

      extensions: [
        AFThemeExtension(
          warning: theme.yellow,
          success: theme.green,
          tint1: theme.tint1,
          tint2: theme.tint2,
          tint3: theme.tint3,
          tint4: theme.tint4,
          tint5: theme.tint5,
          tint6: theme.tint6,
          tint7: theme.tint7,
          tint8: theme.tint8,
          tint9: theme.tint9,
          textColor: theme.text,
          secondaryTextColor: theme.secondaryText,
          strongText: theme.strongText,
          greyHover: theme.hoverBG1,
          greySelect: theme.bg3,
          lightGreyHover: theme.hoverBG3,
          toggleOffFill: theme.shader5,
          progressBarBGColor: theme.progressBarBGColor,
          toggleButtonBGColor: theme.toggleButtonBGColor,
          calendarWeekendBGColor: theme.calendarWeekendBGColor,
          gridRowCountColor: theme.gridRowCountColor,
          code: getFontStyle(
            fontFamily: codeFontFamily,
            fontColor: theme.shader3,
          ),
          callout: getFontStyle(
            fontFamily: fontFamily,
            fontSize: FontSizes.s11,
            fontColor: theme.shader3,
          ),
          calloutBGColor: theme.hoverBG3,
          tableCellBGColor: theme.surface,
          caption: getFontStyle(
            fontFamily: fontFamily,
            fontSize: FontSizes.s11,
            fontWeight: FontWeight.w400,
            fontColor: theme.hint,
          ),
          onBackground: theme.text,
          background: theme.surface,
          borderColor: theme.borderColor,
          scrollbarColor: theme.scrollbarColor,
          scrollbarHoverColor: theme.scrollbarHoverColor,
          lightIconColor: theme.lightIconColor,
        ),
      ],
    );
  }
}
