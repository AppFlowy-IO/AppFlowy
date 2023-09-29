import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaneLayout {
  late double menuWidth;
  late bool showMenu;
  late double childPaneWidth;
  late double childPaneHeight;
  late double? childPaneLPosition;
  late double? childPaneTPosition;
  late double? resizerPosition;
  late double resizerWidth;
  late double resizerHeight;
  late SystemMouseCursor resizeCursorType;
  final (int, PaneNode) childPane;
  final PaneNode parentPane;
  final List<double> flex;

  PaneLayout({
    required BoxConstraints parentPaneConstraints,
    required this.flex,
    required this.childPane,
    required this.parentPane,
  }) {
    childPaneWidth = parentPane.axis == Axis.vertical
        ? parentPaneConstraints.maxWidth * flex[childPane.$1]
        : parentPaneConstraints.maxWidth;

    childPaneHeight = parentPane.axis == Axis.horizontal
        ? parentPaneConstraints.maxHeight * flex[childPane.$1]
        : parentPaneConstraints.maxHeight;

    double accumulatedWidth = 0;
    double accumulatedHeight = 0;
    for (int i = 0; i < childPane.$1; i++) {
      accumulatedWidth += parentPaneConstraints.maxWidth * flex[i];
      accumulatedHeight += parentPaneConstraints.maxHeight * flex[i];
    }

    childPaneLPosition =
        parentPane.axis == Axis.vertical ? accumulatedWidth : null;

    childPaneTPosition =
        parentPane.axis == Axis.horizontal ? accumulatedHeight : null;

    resizerWidth = parentPane.axis == Axis.vertical
        ? HomeSizes.resizeBarThickness
        : parentPaneConstraints.maxWidth;

    resizerHeight = parentPane.axis == Axis.horizontal
        ? HomeSizes.resizeBarThickness
        : parentPaneConstraints.maxHeight;

    resizeCursorType = parentPane.axis == Axis.vertical
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
  }
}
