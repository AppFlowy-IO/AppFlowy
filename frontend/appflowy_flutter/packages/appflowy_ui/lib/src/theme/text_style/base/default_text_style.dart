import 'package:flutter/widgets.dart';

abstract class TextThemeType {
  const TextThemeType();

  TextStyle standard({
    String family = '',
    Color? color,
  });
  TextStyle enhanced({
    String family = '',
    Color? color,
  });
  TextStyle prominent({
    String family = '',
    Color? color,
  });
  TextStyle underline({
    String family = '',
    Color? color,
  });
}

class TextThemeHeading {
  const TextThemeHeading();

  TextStyle h1({
    String family = '',
    Color? color,
  }) =>
      _defaultTextStyle(
        family: family,
        fontSize: 36,
        height: 40 / 36,
        color: color,
      );

  TextStyle h2({
    String family = '',
    Color? color,
  }) =>
      _defaultTextStyle(
        family: family,
        fontSize: 24,
        height: 32 / 24,
        color: color,
      );

  TextStyle h3({
    String family = '',
    Color? color,
  }) =>
      _defaultTextStyle(
        family: family,
        fontSize: 20,
        height: 28 / 20,
        color: color,
      );

  TextStyle h4({
    String family = '',
    Color? color,
  }) =>
      _defaultTextStyle(
        family: family,
        fontSize: 16,
        height: 22 / 16,
        color: color,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    required double fontSize,
    required double height,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.bold,
        height: height,
        fontFamily: family,
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeadline extends TextThemeType {
  const TextThemeHeadline();

  @override
  TextStyle standard({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
      );

  @override
  TextStyle enhanced({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 24,
    double height = 36 / 24,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
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
        color: color,
      );
}

class TextThemeTitle extends TextThemeType {
  const TextThemeTitle();

  @override
  TextStyle standard({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
      );

  @override
  TextStyle enhanced({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 20,
    double height = 28 / 20,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
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
        color: color,
      );
}

class TextThemeBody extends TextThemeType {
  const TextThemeBody();

  @override
  TextStyle standard({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
      );

  @override
  TextStyle enhanced({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 14,
    double height = 20 / 14,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
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
        color: color,
      );
}

class TextThemeCaption extends TextThemeType {
  const TextThemeCaption();

  @override
  TextStyle standard({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
      );

  @override
  TextStyle enhanced({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.w600,
      );

  @override
  TextStyle prominent({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        weight: FontWeight.bold,
      );

  @override
  TextStyle underline({String family = '', Color? color}) => _defaultTextStyle(
        family: family,
        color: color,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 12,
    double height = 16 / 12,
    FontWeight weight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
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
        color: color,
      );
}
