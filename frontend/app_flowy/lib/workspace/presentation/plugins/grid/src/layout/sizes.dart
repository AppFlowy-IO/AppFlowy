import 'package:flutter/widgets.dart';

class GridSize {
  static double scale = 1;

  static double get scrollBarSize => 12 * scale;
  static double get headerHeight => 40 * scale;
  static double get footerHeight => 40 * scale;
  static double get leadingHeaderPadding => 30 * scale;
  static double get trailHeaderPadding => 140 * scale;
  static double get headerContentPadding => 8 * scale;
  static double get cellContentPadding => 8 * scale;
  //
  static EdgeInsets get headerContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.headerContentPadding,
        vertical: GridSize.headerContentPadding,
      );
  static EdgeInsets get cellContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellContentPadding,
        vertical: GridSize.cellContentPadding,
      );

  static EdgeInsets get footerContentInsets => EdgeInsets.fromLTRB(
        0,
        GridSize.headerContentPadding,
        GridSize.headerContentPadding,
        GridSize.headerContentPadding,
      );
}
