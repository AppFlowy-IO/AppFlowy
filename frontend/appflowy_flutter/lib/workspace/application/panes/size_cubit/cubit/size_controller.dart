import 'dart:math';

import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';

class PaneSizeController extends ChangeNotifier {
  List<double> flex;
  final Axis? axis;
  final List<PaneNode> children;
  DragUpdateDetails? details;

  PaneSizeController({
    required this.flex,
    required this.axis,
    this.children = const [],
    this.details,
  });

  factory PaneSizeController.intial() => PaneSizeController(
        flex: [],
        axis: null,
      );

  void resize(
    PaneNode node,
    double availableWidth,
    double newWidth,
    int targetIndex,
    double change,
  ) {
    Log.warn("Flex before: ${flex}");
    double minFlex = 0.1; // minimum visible flex
    double totalFlex = 0;

    // Calculate the total flex for all panes excluding the target pane
    for (var i = 0; i < node.children.length; i++) {
      if (i != targetIndex) {
        totalFlex += flex[i];
      }
    }

    // Calculate new flex values
    for (var i = 0; i <= targetIndex; i++) {
      if (i == targetIndex) {
        double newFlex = max(minFlex, newWidth / availableWidth);
        flex[i] = newFlex;
      } else {
        // Adjust the flex values for other panes
        double proportionalFlex =
            (flex[i] / totalFlex) * (1 - flex[targetIndex]);
        flex[i] = proportionalFlex;
      }
    }

    Log.warn("Flex after: ${flex} $targetIndex $change");
    notifyListeners();
  }
}
