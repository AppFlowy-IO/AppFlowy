import 'package:flutter/material.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class Fonts {
  static const String lato = "Lato";

  static const String quicksand = "Quicksand";

  static const String emoji = "OpenSansEmoji";
}

class FontSizes {
  static double get scale => 1;

  static double get s11 => 11 * scale;

  static double get s12 => 12 * scale;

  static double get s14 => 14 * scale;

  static double get s16 => 16 * scale;

  static double get s18 => 18 * scale;
}

// ignore: non_constant_identifier_names
class TextStyles {
  static const TextStyle lato = TextStyle(
    fontFamily: Fonts.lato,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1,
    fontFamilyFallback: [
      Fonts.emoji,
    ],
  );

  static const TextStyle quicksand = TextStyle(
    fontFamily: Fonts.quicksand,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: [
      Fonts.emoji,
    ],
  );

  // ignore: non_constant_identifier_names
  static TextStyle get T1 => quicksand.bold.size(FontSizes.s14).letterSpace(.7);

  // ignore: non_constant_identifier_names
  static TextStyle get T2 => lato.bold.size(FontSizes.s12).letterSpace(.4);

  // ignore: non_constant_identifier_names
  static TextStyle get H1 => lato.bold.size(FontSizes.s14);

  // ignore: non_constant_identifier_names
  static TextStyle get H2 => lato.bold.size(FontSizes.s12);

  // ignore: non_constant_identifier_names
  static TextStyle get Body1 => lato.size(FontSizes.s14);

  // ignore: non_constant_identifier_names
  static TextStyle get Body2 => lato.size(FontSizes.s12);

  // ignore: non_constant_identifier_names
  static TextStyle get Body3 => lato.size(FontSizes.s11);

  // ignore: non_constant_identifier_names
  static TextStyle get Callout => quicksand.size(FontSizes.s14).letterSpace(1.75);

  // ignore: non_constant_identifier_names
  static TextStyle get CalloutFocus => Callout.bold;

  // ignore: non_constant_identifier_names
  static TextStyle get Btn => quicksand.bold.size(FontSizes.s14).letterSpace(1.75);

  // ignore: non_constant_identifier_names
  static TextStyle get BtnSelected => quicksand.size(FontSizes.s14).letterSpace(1.75);

  // ignore: non_constant_identifier_names
  static TextStyle get Footnote => quicksand.bold.size(FontSizes.s11);

  // ignore: non_constant_identifier_names
  static TextStyle get Caption => lato.size(FontSizes.s11).letterSpace(.3);
}
