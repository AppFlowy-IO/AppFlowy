import 'package:flutter/widgets.dart';

class GridSize {
  static double scale = 1;

  static double get scrollBarSize => 12 * scale;
  static double get headerHeight => 40 * scale;
  static double get footerHeight => 40 * scale;
  static double get leadingHeaderPadding => 30 * scale;
  static double get trailHeaderPadding => 140 * scale;
  static double get headerContainerPadding => 0 * scale;
  static double get cellContentPadding => 10 * scale;
  static double get typeOptionItemHeight => 30 * scale;
  static double get typeOptionSeparatorHeight => 6 * scale;

  //
  static EdgeInsets get headerContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.headerContainerPadding,
        vertical: GridSize.headerContainerPadding,
      );
  static EdgeInsets get cellContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellContentPadding,
        vertical: GridSize.cellContentPadding,
      );

  static EdgeInsets get fieldContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellContentPadding,
        vertical: GridSize.cellContentPadding,
      );

  static EdgeInsets get typeOptionContentInsets => const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      );

  static EdgeInsets get footerContentInsets => EdgeInsets.fromLTRB(
        0,
        GridSize.headerContainerPadding,
        GridSize.headerContainerPadding,
        GridSize.headerContainerPadding,
      );
}
