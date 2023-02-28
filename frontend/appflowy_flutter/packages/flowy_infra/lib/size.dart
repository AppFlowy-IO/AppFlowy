import 'package:flutter/material.dart';

class PageBreaks {
  static double get largePhone => 550;

  static double get tabletPortrait => 768;

  static double get tabletLandscape => 1024;

  static double get desktop => 1440;
}

class Insets {
  static double gutterScale = 1;

  static double scale = 1;

  /// Dynamic insets, may get scaled with the device size
  static double get mGutter => m * gutterScale;

  static double get lGutter => l * gutterScale;

  static double get xs => 2 * scale;

  static double get sm => 6 * scale;

  static double get m => 12 * scale;

  static double get l => 24 * scale;

  static double get xl => 36 * scale;
}

class FontSizes {
  static double get scale => 1;

  static double get s11 => 11 * scale;

  static double get s12 => 12 * scale;

  static double get s14 => 14 * scale;

  static double get s16 => 16 * scale;

  static double get s18 => 18 * scale;

  static double get s20 => 20 * scale;

  static double get s24 => 24 * scale;

  static double get s32 => 32 * scale;

  static double get s44 => 44 * scale;
}

class Sizes {
  static double hitScale = 1;

  static double get hit => 40 * hitScale;

  static double get iconMed => 20;

  static double get sideBarMed => 225 * hitScale;

  static double get sideBarLg => 290 * hitScale;
}

class Corners {
  static const BorderRadius s3Border = BorderRadius.all(s3Radius);
  static const Radius s3Radius = Radius.circular(3);

  static const BorderRadius s5Border = BorderRadius.all(s5Radius);
  static const Radius s5Radius = Radius.circular(5);

  static const BorderRadius s6Border = BorderRadius.all(s6Radius);
  static const Radius s6Radius = Radius.circular(6);

  static const BorderRadius s8Border = BorderRadius.all(s8Radius);
  static const Radius s8Radius = Radius.circular(8);

  static const BorderRadius s10Border = BorderRadius.all(s10Radius);
  static const Radius s10Radius = Radius.circular(10);

  static const BorderRadius s12Border = BorderRadius.all(s12Radius);
  static const Radius s12Radius = Radius.circular(12);
}
