import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class GridScrollController {
  final LinkedScrollControllerGroup _scrollGroupContorller;
  final ScrollController verticalController;
  final ScrollController horizontalController;

  final List<ScrollController> _linkHorizontalControllers = [];

  GridScrollController({required LinkedScrollControllerGroup scrollGroupContorller})
      : _scrollGroupContorller = scrollGroupContorller,
        verticalController = ScrollController(),
        horizontalController = scrollGroupContorller.addAndGet();

  ScrollController linkHorizontalController() {
    final controller = _scrollGroupContorller.addAndGet();
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
