import 'package:flutter/material.dart';

class GridScrollController {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  ScrollController get verticalController => _verticalController;
  ScrollController get horizontalController => _horizontalController;

  GridScrollController();

  // final SelectionChangeCallback? onSelectionChanged;

  // final ShouldApplySelection? shouldApplySelection;

  // final ScrollCallback? onScroll;

  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
  }
}
