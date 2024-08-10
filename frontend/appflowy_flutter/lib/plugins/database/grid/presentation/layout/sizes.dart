import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

class GridSize {
  static double scale = 1;

  static double get scrollBarSize => 8 * scale;
  static double get headerHeight => 40 * scale;
  static double get footerHeight => 40 * scale;
  static double get horizontalHeaderPadding =>
      PlatformExtension.isDesktop ? 40 * scale : 16 * scale;
  static double get trailHeaderPadding => 140 * scale;
  static double get cellHPadding => 10 * scale;
  static double get cellVPadding => 10 * scale;
  static double get popoverItemHeight => 26 * scale;
  static double get typeOptionSeparatorHeight => 4 * scale;
  static double get newPropertyButtonWidth => 140 * scale;
  static double get mobileNewPropertyButtonWidth => 200 * scale;

  static EdgeInsets get cellContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellHPadding,
        vertical: GridSize.cellVPadding,
      );

  static EdgeInsets get fieldContentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.cellHPadding,
        vertical: GridSize.cellVPadding,
      );

  static EdgeInsets get typeOptionContentInsets => const EdgeInsets.all(4);

  static EdgeInsets get toolbarSettingButtonInsets =>
      const EdgeInsets.symmetric(horizontal: 8, vertical: 2);

  static EdgeInsets get footerContentInsets => EdgeInsets.fromLTRB(
        GridSize.horizontalHeaderPadding,
        0,
        PlatformExtension.isMobile ? GridSize.horizontalHeaderPadding : 0,
        PlatformExtension.isMobile ? 100 : 0,
      );

  static EdgeInsets get contentInsets => EdgeInsets.symmetric(
        horizontal: GridSize.horizontalHeaderPadding,
      );
}
