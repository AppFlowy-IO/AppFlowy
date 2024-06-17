import 'package:flutter/material.dart';

import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/utils/color_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'dandelion.dart';
import 'default_colorscheme.dart';
import 'lavender.dart';
import 'lemonade.dart';

part 'colorscheme.g.dart';

/// A map of all the built-in themes.
///
/// The key is the theme name, and the value is a list of two color schemes:
/// the first is for light mode, and the second is for dark mode.
const Map<String, List<FlowyColorScheme>> themeMap = {
  BuiltInTheme.defaultTheme: [
    DefaultColorScheme.light(),
    DefaultColorScheme.dark(),
  ],
  BuiltInTheme.dandelion: [
    DandelionColorScheme.light(),
    DandelionColorScheme.dark(),
  ],
  BuiltInTheme.lemonade: [
    LemonadeColorScheme.light(),
    LemonadeColorScheme.dark(),
  ],
  BuiltInTheme.lavender: [
    LavenderColorScheme.light(),
    LavenderColorScheme.dark(),
  ],
};

@JsonSerializable(converters: [ColorConverter()])
class FlowyColorScheme {
  const FlowyColorScheme({
    required this.surface,
    required this.hover,
    required this.selector,
    required this.red,
    required this.yellow,
    required this.green,
    required this.shader1,
    required this.shader2,
    required this.shader3,
    required this.shader4,
    required this.shader5,
    required this.shader6,
    required this.shader7,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.tint1,
    required this.tint2,
    required this.tint3,
    required this.tint4,
    required this.tint5,
    required this.tint6,
    required this.tint7,
    required this.tint8,
    required this.tint9,
    required this.main1,
    required this.main2,
    required this.shadow,
    required this.sidebarBg,
    required this.divider,
    required this.topbarBg,
    required this.icon,
    required this.text,
    required this.secondaryText,
    required this.strongText,
    required this.input,
    required this.hint,
    required this.primary,
    required this.onPrimary,
    required this.hoverBG1,
    required this.hoverBG2,
    required this.hoverBG3,
    required this.hoverFG,
    required this.questionBubbleBG,
    required this.progressBarBGColor,
    required this.toolbarColor,
    required this.toggleButtonBGColor,
    required this.calendarWeekendBGColor,
    required this.gridRowCountColor,
  });

  final Color surface;
  final Color hover;
  final Color selector;
  final Color red;
  final Color yellow;
  final Color green;
  final Color shader1;
  final Color shader2;
  final Color shader3;
  final Color shader4;
  final Color shader5;
  final Color shader6;
  final Color shader7;
  final Color bg1;
  final Color bg2;
  final Color bg3;
  final Color bg4;
  final Color tint1;
  final Color tint2;
  final Color tint3;
  final Color tint4;
  final Color tint5;
  final Color tint6;
  final Color tint7;
  final Color tint8;
  final Color tint9;
  final Color main1;
  final Color main2;
  final Color shadow;
  final Color sidebarBg;
  final Color divider;
  final Color topbarBg;
  final Color icon;
  final Color text;
  final Color secondaryText;
  final Color strongText;
  final Color input;
  final Color hint;
  final Color primary;
  final Color onPrimary;
  //page title hover effect
  final Color hoverBG1;
  //action item hover effect
  final Color hoverBG2;
  final Color hoverBG3;
  //the text color when it is hovered
  final Color hoverFG;
  final Color questionBubbleBG;
  final Color progressBarBGColor;
  //editor toolbar BG color
  final Color toolbarColor;
  final Color toggleButtonBGColor;
  final Color calendarWeekendBGColor;
  //grid bottom count color
  final Color gridRowCountColor;

  factory FlowyColorScheme.fromJson(Map<String, dynamic> json) =>
      _$FlowyColorSchemeFromJson(json);

  Map<String, dynamic> toJson() => _$FlowyColorSchemeToJson(this);
}
