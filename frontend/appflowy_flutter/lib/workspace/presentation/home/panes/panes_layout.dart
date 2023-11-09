import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaneLayout {
  PaneLayout({
    required this.flex,
    required this.childPane,
    required this.parentPane,
    required BoxConstraints parentPaneConstraints,
    required HomeLayout homeLayout,
  }) {
    childPaneWidth = parentPane.axis == Axis.vertical
        ? parentPaneConstraints.maxWidth * flex[childPane.$1]
        : parentPaneConstraints.maxWidth;

    childPaneHeight = parentPane.axis == Axis.horizontal
        ? parentPaneConstraints.maxHeight * flex[childPane.$1]
        : parentPaneConstraints.maxHeight;

    final bool adaptiveContent = adaptivePlugins.contains(
      childPane.$2.tabsController.currentPageManager.notifier.plugin.pluginType,
    );

    if (adaptiveContent) {
      homePageHeight = childPaneHeight;
      homePageWidth = childPaneWidth;
    } else {
      homePageHeight = homeLayout.homePageHeight;
      homePageWidth = homeLayout.homePageWidth;
    }
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

  final (int, PaneNode) childPane;
  final PaneNode parentPane;
  final List<double> flex;
  late double menuWidth;
  late bool showMenu;
  late double childPaneWidth;
  late double childPaneHeight;
  late double? childPaneLPosition;
  late double? childPaneTPosition;
  late double? resizerPosition;
  late double resizerWidth;
  late double resizerHeight;
  late double homePageWidth;
  late double homePageHeight;
  late SystemMouseCursor resizeCursorType;

  factory PaneLayout.initial({
    required BoxConstraints parentConstraints,
    required PaneNode root,
    required HomeLayout homeLayout,
  }) =>
      PaneLayout(
        homeLayout: homeLayout,
        parentPaneConstraints: parentConstraints,
        flex: [],
        childPane: (0, root),
        parentPane: PaneNode.initial(),
      );

  /// PluginType added here will adapt to size of pane
  /// rather than being stacked over
  final List<PluginType> adaptivePlugins = [];
}
