import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GridScrollController {
  GridScrollController({
    required LinkedScrollControllerGroup scrollGroupController,
  })  : _scrollGroupController = scrollGroupController,
        verticalController = ScrollController(),
        horizontalController = scrollGroupController.addAndGet();

  final LinkedScrollControllerGroup _scrollGroupController;
  final ScrollController verticalController;
  final ScrollController horizontalController;

  final List<ScrollController> _linkHorizontalControllers = [];

  ScrollController linkHorizontalController() {
    final controller = _scrollGroupController.addAndGet();
    _linkHorizontalControllers.add(controller);
    return controller;
  }

  void dispose() {
    for (final controller in _linkHorizontalControllers) {
      controller.dispose();
    }
    verticalController.dispose();
    horizontalController.dispose();
  }
}
