import 'package:flutter/widgets.dart';

class CalendarSize {
  static double scale = 1;

  static double get scrollBarSize => 12 * scale;
  static double get navigatorButtonWidth => 20 * scale;
  static double get navigatorButtonHeight => 25 * scale;
  static EdgeInsets get daysOfWeekInsets =>
      EdgeInsets.symmetric(vertical: 10.0 * scale);
}
