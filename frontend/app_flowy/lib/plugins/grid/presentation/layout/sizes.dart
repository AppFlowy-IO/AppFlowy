import 'package:flutter/widgets.dart';

class GridSize {
  static double scale = 1;

  static double get scrollBarSize => 12 * scale;
  static double get headerHeight => 40 * scale;
  static double get footerHeight => 40 * scale;
  static double get leadingHeaderPadding => 50 * scale;
  static double get trailHeaderPadding => 140 * scale;
  static double get headerContainerPadding => 0 * scale;
  static double get cellHPadding => 10 * scale;
  static double get cellVPadding => 10 * scale;
  static double get typeOptionItemHeight => 32 * scale;
  static double get typeOptionSeparatorHeight => 4 * scale;

  static EdgeInsets get headerContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.headerContainerPadding,
        vertical: GridSize.headerContainerPadding,
      );
  static EdgeInsets get cellContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellHPadding,
        vertical: GridSize.cellVPadding,
      );

  static EdgeInsets get fieldContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellHPadding,
        vertical: GridSize.cellVPadding,
      );

  static EdgeInsets get typeOptionContentInsets => const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      );

  static EdgeInsets get footerContentInsets => EdgeInsets.fromLTRB(
        GridSize.leadingHeaderPadding,
        GridSize.headerContainerPadding,
        GridSize.headerContainerPadding,
        GridSize.headerContainerPadding,
      );

  static EdgeInsets optionListItemPadding({
    required int length,
    required int index,
    double? right,
    double? left,
    double? top,
    double? bottom,
    double? horizontal,
    double? vertical,
  }) {
    assert(horizontal == null || (left == null && right == null));
    assert(vertical == null || (top == null && bottom == null));

    EdgeInsets padding = EdgeInsets.zero;

    if (horizontal != null) {
      padding = padding.copyWith(left: horizontal, right: horizontal);
    } else {
      padding = padding.copyWith(left: left, right: right);
    }

    if (index == 0) {
      if (vertical != null) {
        padding = padding.copyWith(top: vertical);
      } else {
        padding = padding.copyWith(top: top);
      }
    }

    if (index == length - 1) {
      if (vertical != null) {
        padding = padding.copyWith(bottom: vertical);
      } else {
        padding = padding.copyWith(bottom: bottom);
      }
    }

    return padding;
  }
}
