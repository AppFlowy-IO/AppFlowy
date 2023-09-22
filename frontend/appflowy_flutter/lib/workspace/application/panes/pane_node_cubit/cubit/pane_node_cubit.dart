import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'pane_node_state.dart';

class PaneNodeCubit extends Cubit<PaneNodeState> {
  PaneNodeCubit(int length) : super(PaneNodeState.initial(length: length));

  void initialize(int length) {
    emit(state.copyWith(flex: List.generate(length, (index) => 1 / length)));
  }

  void resize(
    double availableWidth,
    int targetIndex,
    double change,
  ) {
    List<double> flex = [...state.flex];
    const minFlex = 0.12;
    const maxFlex = 1.0;
    final direction = change > 0 ? 1 : -1;
    final newWidth = availableWidth * flex[targetIndex] - change;
    final newFlex = max(minFlex, newWidth / availableWidth);

    // Calculate the total flex of the other panes
    final double otherFlex = 1 - flex[targetIndex];
    // Adjust the flex of the target pane
    flex[targetIndex] = newFlex;

    // Adjust the flexes of the other panes
    for (var i = 0; i < flex.length; i++) {
      if (i != targetIndex) {
        flex[i] = max(minFlex, (flex[i] / otherFlex) * (maxFlex - newFlex));
      }
    }

    // If the total flex is over 1, reduce all flexes proportionally
    final double totalFlex = flex.reduce((a, b) => a + b);
    if (totalFlex > maxFlex) {
      for (var i = 0; i < flex.length; i++) {
        flex[i] = (flex[i] / totalFlex) * maxFlex;
      }
    }

    // Adjust flexes based on direction
    if (direction > 0) {
      for (var i = targetIndex + 1; i < flex.length; i++) {
        flex[i] = max(minFlex, flex[i]);
      }
    } else {
      for (var i = 0; i < targetIndex; i++) {
        flex[i] = max(minFlex, flex[i]);
      }
    }

    emit(state.copyWith(flex: flex, totalOffset: 0));
  }
}
