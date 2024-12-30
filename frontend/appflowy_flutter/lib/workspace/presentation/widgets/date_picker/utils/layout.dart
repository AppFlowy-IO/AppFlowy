import 'package:flutter/material.dart';

class DatePickerSize {
  static double scale = 1;

  static double get itemHeight => 26 * scale;
  static double get seperatorHeight => 4 * scale;

  static EdgeInsets get itemOptionInsets => const EdgeInsets.all(4);
}
