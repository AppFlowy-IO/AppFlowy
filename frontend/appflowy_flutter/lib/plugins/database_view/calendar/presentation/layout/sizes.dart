import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:flutter/widgets.dart';

class CalendarSize {
  static double scale = 1;

  static double get headerContainerPadding => 12 * scale;

  static EdgeInsets get contentInsets => EdgeInsets.fromLTRB(
        GridSize.leadingHeaderPadding,
        CalendarSize.headerContainerPadding,
        GridSize.leadingHeaderPadding,
        CalendarSize.headerContainerPadding,
      );

  static double get scrollBarSize => 8 * scale;
  static double get navigatorButtonWidth => 20 * scale;
  static double get navigatorButtonHeight => 25 * scale;
  static EdgeInsets get daysOfWeekInsets =>
      EdgeInsets.symmetric(vertical: 10.0 * scale);
}
