import 'package:flutter/widgets.dart';

abstract class TextThemeType {
  const TextThemeType({
    required this.fontFamily,
  });

  final String fontFamily;

  TextStyle standard({
    String? family,
    Color? color,
    FontWeight? weight,
  });

  TextStyle enhanced({
    String? family,
    Color? color,
    FontWeight? weight,
  });

  TextStyle prominent({
    String? family,
    Color? color,
    FontWeight? weight,
  });

  TextStyle underline({
    String? family,
    Color? color,
    FontWeight? weight,
  });
}

class TextThemeHeading1 extends TextThemeType {
  const TextThemeHeading1({
    required super.fontFamily,
  });

  @override
  TextStyle standard({
    String? family,
    Color? color,
    FontWeight? weight,
  }) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        fontSize: 36,
        height: 40 / 36,
        color: color,
        weight: weight ?? FontWeight.w400,
      );

  @override
  TextStyle enhanced({
    String? family,
    Color? color,
    FontWeight? weight,
  }) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        fontSize: 36,
        height: 40 / 36,
        color: color,
        weight: weight ?? FontWeight.w600,
      );

  @override
  TextStyle prominent({
    String? family,
    Color? color,
    FontWeight? weight,
  }) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        fontSize: 36,
        height: 40 / 36,
        color: color,
        weight: weight ?? FontWeight.w700,
      );

  @override
  TextStyle underline({
    String? family,
    Color? color,
    FontWeight? weight,
  }) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        fontSize: 36,
        height: 40 / 36,
        color: color,
        weight: weight ?? FontWeight.bold,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    required double fontSize,
    required double height,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        decoration: decoration,
        fontStyle: FontStyle.normal,
        fontWeight: weight,
        height: height,
        fontFamily: family,
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeading2 extends TextThemeType {
  const TextThemeHeading2({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w600,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w700,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 24,
    double height = 32 / 24,
    TextDecoration decoration = TextDecoration.none,
    FontWeight weight = FontWeight.w400,
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
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeading3 extends TextThemeType {
  const TextThemeHeading3({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w600,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w700,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 20,
    double height = 28 / 20,
    TextDecoration decoration = TextDecoration.none,
    FontWeight weight = FontWeight.w400,
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
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeading4 extends TextThemeType {
  const TextThemeHeading4({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w600,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w700,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w400,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 16,
    double height = 22 / 16,
    TextDecoration decoration = TextDecoration.none,
    FontWeight weight = FontWeight.w400,
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
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
}

class TextThemeHeadline extends TextThemeType {
  const TextThemeHeadline({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w500,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.bold,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 24,
    double height = 36 / 24,
    TextDecoration decoration = TextDecoration.none,
    FontWeight weight = FontWeight.normal,
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
  const TextThemeTitle({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w500,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.bold,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
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
  const TextThemeBody({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w500,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.bold,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
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
  const TextThemeCaption({
    required super.fontFamily,
  });

  @override
  TextStyle standard({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
      );

  @override
  TextStyle enhanced({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.w500,
      );

  @override
  TextStyle prominent({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.bold,
      );

  @override
  TextStyle underline({String? family, Color? color, FontWeight? weight}) =>
      _defaultTextStyle(
        family: family ?? super.fontFamily,
        color: color,
        weight: weight ?? FontWeight.normal,
        decoration: TextDecoration.underline,
      );

  static TextStyle _defaultTextStyle({
    required String family,
    double fontSize = 12,
    double height = 18 / 12,
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
