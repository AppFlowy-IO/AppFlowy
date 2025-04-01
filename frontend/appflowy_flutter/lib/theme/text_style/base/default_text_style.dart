import 'package:flutter/widgets.dart';

abstract class TextThemeType {
  const TextThemeType();

  TextStyle standard({String family = ''});
  TextStyle enhanced({String family = ''});
  TextStyle prominent({String family = ''});
  TextStyle underline({String family = ''});
}

class TextThemeHeading extends TextThemeType {
  const TextThemeHeading();

  @override
  TextStyle standard({String family = ''}) => _defaultTextStyle(
        family: family,
        fontSize: 36,
        height: 40 / 36,
      );

  @override
  TextStyle enhanced({String family = ''}) => _defaultTextStyle(
        family: family,
        fontSize: 24,
        height: 32 / 24,
      );

  @override
  TextStyle prominent({String family = ''}) => _defaultTextStyle(
        family: family,
        fontSize: 20,
        height: 28 / 20,
      );

  @override
  TextStyle underline({String family = ''}) => _defaultTextStyle(
        family: family,
        fontSize: 16,
        decoration: TextDecoration.underline,
        height: 22 / 16,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    required double fontSize,
    required double height,
    TextDecoration decoration = TextDecoration.none,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold,
        height: height,
        fontFamily: family,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeadline extends TextThemeType {
  const TextThemeHeadline();

  @override
  TextStyle standard({String family = ''}) => _defaultTextStyle(
        family: family,
      );

  @override
  TextStyle enhanced({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = ''}) => _defaultTextStyle(
        family: family,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 24,
    double height = 36 / 24,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: weight,
        height: height,
        fontFamily: family,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeTitle extends TextThemeType {
  const TextThemeTitle();

  @override
  TextStyle standard({String family = ''}) => _defaultTextStyle(
        family: family,
      );

  @override
  TextStyle enhanced({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = ''}) => _defaultTextStyle(
        family: family,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 20,
    double height = 28 / 20,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: weight,
        height: height,
        fontFamily: family,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeBody extends TextThemeType {
  const TextThemeBody();

  @override
  TextStyle standard({String family = ''}) => _defaultTextStyle(
        family: family,
      );

  @override
  TextStyle enhanced({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = ''}) => _defaultTextStyle(
        family: family,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 14,
    double height = 20 / 14,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: weight,
        height: height,
        fontFamily: family,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeCaption extends TextThemeType {
  const TextThemeCaption();

  @override
  TextStyle standard({String family = ''}) => _defaultTextStyle(
        family: family,
      );

  @override
  TextStyle enhanced({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = ''}) => _defaultTextStyle(
        family: family,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = ''}) => _defaultTextStyle(
        family: family,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 12,
    double height = 16 / 12,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: weight,
        height: height,
        fontFamily: family,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}
