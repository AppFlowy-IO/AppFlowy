import 'dart:math';

import 'package:flutter/material.dart';

class PaneSizeController extends ChangeNotifier {
  List<double> flex;

  PaneSizeController({required this.flex});

  factory PaneSizeController.intial() => PaneSizeController(flex: []);

  void resize(
    double availableWidth,
    List<double> flex,
    int targetIndex,
    double change,
  ) {
    const minFlex = 0.2;
    final newWidth = availableWidth * flex[targetIndex] - change;
    double totalFlex = 0;
    for (var i = 0; i < flex.length; i++) {
      if (i != targetIndex) {
        totalFlex += flex[i];
      }
    }

    for (var i = 0; i <= targetIndex; i++) {
      if (i == targetIndex) {
        final newFlex = max(minFlex, newWidth / availableWidth);
        flex[i] = newFlex;
      } else {
        final proportionalFlex =
            (flex[i] / totalFlex) * (1 - flex[targetIndex]);
        flex[i] = proportionalFlex;
      }
    }
    notifyListeners();
  }
}
