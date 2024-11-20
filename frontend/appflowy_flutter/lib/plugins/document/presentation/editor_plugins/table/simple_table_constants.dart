import 'package:flutter/material.dart';

class SimpleTableConstants {
  static const defaultColumnWidth = 120.0;
  static const minimumColumnWidth = 50.0;
  static const borderColor = Color(0xFFE4E5E5);

  static const addRowButtonHeight = 16.0;
  static const addRowButtonPadding = 2.0;
  static const addRowButtonBackgroundColor = Color(0xFFF2F3F5);
  static const addRowButtonRadius = 4.0;
  static const addRowButtonRightPadding =
      addColumnButtonWidth + addColumnButtonPadding * 2;

  static const addColumnButtonWidth = 16.0;
  static const addColumnButtonPadding = 2.0;
  static const addColumnButtonBackgroundColor = addRowButtonBackgroundColor;
  static const addColumnButtonRadius = 4.0;
  static const addColumnButtonBottomPadding =
      addRowButtonHeight + addRowButtonPadding * 2;

  static const addColumnAndRowButtonWidth = addColumnButtonWidth;
  static const addColumnAndRowButtonHeight = addRowButtonHeight;
  static const addColumnAndRowButtonCornerRadius = addColumnButtonWidth / 2.0;
  static const addColumnAndRowButtonBackgroundColor =
      addColumnButtonBackgroundColor;

  static const cellEdgePadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 2.0,
  );
}
