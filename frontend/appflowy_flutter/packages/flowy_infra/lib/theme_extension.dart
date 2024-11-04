import 'package:flutter/material.dart';

@immutable
class AFThemeExtension extends ThemeExtension<AFThemeExtension> {
  static AFThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<AFThemeExtension>()!;

  static AFThemeExtension? maybeOf(BuildContext context) =>
      Theme.of(context).extension<AFThemeExtension>();

  const AFThemeExtension({
    required this.warning,
    required this.success,
    required this.tint1,
    required this.tint2,
    required this.tint3,
    required this.tint4,
    required this.tint5,
    required this.tint6,
    required this.tint7,
    required this.tint8,
    required this.tint9,
    required this.greyHover,
    required this.greySelect,
    required this.lightGreyHover,
    required this.toggleOffFill,
    required this.textColor,
    required this.secondaryTextColor,
    required this.strongText,
    required this.calloutBGColor,
    required this.tableCellBGColor,
    required this.calendarWeekendBGColor,
    required this.code,
    required this.callout,
    required this.caption,
    required this.progressBarBGColor,
    required this.toggleButtonBGColor,
    required this.gridRowCountColor,
    required this.background,
    required this.onBackground,
    required this.borderColor,
    required this.scrollbarColor,
    required this.scrollbarHoverColor,
    required this.lightIconColor,
  });

  final Color? warning;
  final Color? success;

  final Color tint1;
  final Color tint2;
  final Color tint3;
  final Color tint4;
  final Color tint5;
  final Color tint6;
  final Color tint7;
  final Color tint8;
  final Color tint9;

  final Color textColor;
  final Color secondaryTextColor;
  final Color strongText;
  final Color greyHover;
  final Color greySelect;
  final Color lightGreyHover;
  final Color toggleOffFill;
  final Color progressBarBGColor;
  final Color toggleButtonBGColor;
  final Color calloutBGColor;
  final Color tableCellBGColor;
  final Color calendarWeekendBGColor;
  final Color gridRowCountColor;

  final TextStyle code;
  final TextStyle callout;
  final TextStyle caption;

  final Color background;
  final Color onBackground;

  /// The color of the border of the widget.
  ///
  /// This is used in the divider, outline border, etc.
  final Color borderColor;

  final Color scrollbarColor;
  final Color scrollbarHoverColor;

  final Color lightIconColor;

  @override
  AFThemeExtension copyWith({
    Color? warning,
    Color? success,
    Color? tint1,
    Color? tint2,
    Color? tint3,
    Color? tint4,
    Color? tint5,
    Color? tint6,
    Color? tint7,
    Color? tint8,
    Color? tint9,
    Color? textColor,
    Color? secondaryTextColor,
    Color? strongText,
    Color? calloutBGColor,
    Color? tableCellBGColor,
    Color? greyHover,
    Color? greySelect,
    Color? lightGreyHover,
    Color? toggleOffFill,
    Color? progressBarBGColor,
    Color? toggleButtonBGColor,
    Color? calendarWeekendBGColor,
    Color? gridRowCountColor,
    TextStyle? code,
    TextStyle? callout,
    TextStyle? caption,
    Color? background,
    Color? onBackground,
    Color? borderColor,
    Color? scrollbarColor,
    Color? scrollbarHoverColor,
    Color? lightIconColor,
  }) =>
      AFThemeExtension(
        warning: warning ?? this.warning,
        success: success ?? this.success,
        tint1: tint1 ?? this.tint1,
        tint2: tint2 ?? this.tint2,
        tint3: tint3 ?? this.tint3,
        tint4: tint4 ?? this.tint4,
        tint5: tint5 ?? this.tint5,
        tint6: tint6 ?? this.tint6,
        tint7: tint7 ?? this.tint7,
        tint8: tint8 ?? this.tint8,
        tint9: tint9 ?? this.tint9,
        textColor: textColor ?? this.textColor,
        secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
        strongText: strongText ?? this.strongText,
        calloutBGColor: calloutBGColor ?? this.calloutBGColor,
        tableCellBGColor: tableCellBGColor ?? this.tableCellBGColor,
        greyHover: greyHover ?? this.greyHover,
        greySelect: greySelect ?? this.greySelect,
        lightGreyHover: lightGreyHover ?? this.lightGreyHover,
        toggleOffFill: toggleOffFill ?? this.toggleOffFill,
        progressBarBGColor: progressBarBGColor ?? this.progressBarBGColor,
        toggleButtonBGColor: toggleButtonBGColor ?? this.toggleButtonBGColor,
        calendarWeekendBGColor:
            calendarWeekendBGColor ?? this.calendarWeekendBGColor,
        gridRowCountColor: gridRowCountColor ?? this.gridRowCountColor,
        code: code ?? this.code,
        callout: callout ?? this.callout,
        caption: caption ?? this.caption,
        onBackground: onBackground ?? this.onBackground,
        background: background ?? this.background,
        borderColor: borderColor ?? this.borderColor,
        scrollbarColor: scrollbarColor ?? this.scrollbarColor,
        scrollbarHoverColor: scrollbarHoverColor ?? this.scrollbarHoverColor,
        lightIconColor: lightIconColor ?? this.lightIconColor,
      );

  @override
  ThemeExtension<AFThemeExtension> lerp(
      ThemeExtension<AFThemeExtension>? other, double t) {
    if (other is! AFThemeExtension) {
      return this;
    }
    return AFThemeExtension(
      warning: Color.lerp(warning, other.warning, t),
      success: Color.lerp(success, other.success, t),
      tint1: Color.lerp(tint1, other.tint1, t)!,
      tint2: Color.lerp(tint2, other.tint2, t)!,
      tint3: Color.lerp(tint3, other.tint3, t)!,
      tint4: Color.lerp(tint4, other.tint4, t)!,
      tint5: Color.lerp(tint5, other.tint5, t)!,
      tint6: Color.lerp(tint6, other.tint6, t)!,
      tint7: Color.lerp(tint7, other.tint7, t)!,
      tint8: Color.lerp(tint8, other.tint8, t)!,
      tint9: Color.lerp(tint9, other.tint9, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      secondaryTextColor: Color.lerp(
        secondaryTextColor,
        other.secondaryTextColor,
        t,
      )!,
      strongText: Color.lerp(
        strongText,
        other.strongText,
        t,
      )!,
      calloutBGColor: Color.lerp(calloutBGColor, other.calloutBGColor, t)!,
      tableCellBGColor:
          Color.lerp(tableCellBGColor, other.tableCellBGColor, t)!,
      greyHover: Color.lerp(greyHover, other.greyHover, t)!,
      greySelect: Color.lerp(greySelect, other.greySelect, t)!,
      lightGreyHover: Color.lerp(lightGreyHover, other.lightGreyHover, t)!,
      toggleOffFill: Color.lerp(toggleOffFill, other.toggleOffFill, t)!,
      progressBarBGColor:
          Color.lerp(progressBarBGColor, other.progressBarBGColor, t)!,
      toggleButtonBGColor:
          Color.lerp(toggleButtonBGColor, other.toggleButtonBGColor, t)!,
      calendarWeekendBGColor:
          Color.lerp(calendarWeekendBGColor, other.calendarWeekendBGColor, t)!,
      gridRowCountColor:
          Color.lerp(gridRowCountColor, other.gridRowCountColor, t)!,
      code: other.code,
      callout: other.callout,
      caption: other.caption,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      background: Color.lerp(background, other.background, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      scrollbarColor: Color.lerp(scrollbarColor, other.scrollbarColor, t)!,
      scrollbarHoverColor:
          Color.lerp(scrollbarHoverColor, other.scrollbarHoverColor, t)!,
      lightIconColor: Color.lerp(lightIconColor, other.lightIconColor, t)!,
    );
  }
}

enum FlowyTint {
  tint1,
  tint2,
  tint3,
  tint4,
  tint5,
  tint6,
  tint7,
  tint8,
  tint9;

  String toJson() => name;
  static FlowyTint fromJson(String json) {
    try {
      return FlowyTint.values.byName(json);
    } catch (_) {
      return FlowyTint.tint1;
    }
  }

  static FlowyTint? fromId(String id) {
    for (final value in FlowyTint.values) {
      if (value.id == id) {
        return value;
      }
    }
    return null;
  }

  Color color(BuildContext context) => switch (this) {
        FlowyTint.tint1 => AFThemeExtension.of(context).tint1,
        FlowyTint.tint2 => AFThemeExtension.of(context).tint2,
        FlowyTint.tint3 => AFThemeExtension.of(context).tint3,
        FlowyTint.tint4 => AFThemeExtension.of(context).tint4,
        FlowyTint.tint5 => AFThemeExtension.of(context).tint5,
        FlowyTint.tint6 => AFThemeExtension.of(context).tint6,
        FlowyTint.tint7 => AFThemeExtension.of(context).tint7,
        FlowyTint.tint8 => AFThemeExtension.of(context).tint8,
        FlowyTint.tint9 => AFThemeExtension.of(context).tint9,
      };

  String get id => switch (this) {
        // DON'T change this name because it's saved in the database!
        FlowyTint.tint1 => 'appflowy_them_color_tint1',
        FlowyTint.tint2 => 'appflowy_them_color_tint2',
        FlowyTint.tint3 => 'appflowy_them_color_tint3',
        FlowyTint.tint4 => 'appflowy_them_color_tint4',
        FlowyTint.tint5 => 'appflowy_them_color_tint5',
        FlowyTint.tint6 => 'appflowy_them_color_tint6',
        FlowyTint.tint7 => 'appflowy_them_color_tint7',
        FlowyTint.tint8 => 'appflowy_them_color_tint8',
        FlowyTint.tint9 => 'appflowy_them_color_tint9',
      };
}
