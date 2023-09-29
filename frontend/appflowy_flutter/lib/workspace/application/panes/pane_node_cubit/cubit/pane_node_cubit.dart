import 'dart:math';

import 'package:appflowy_backend/log.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'pane_node_state.dart';

class PaneNodeCubit extends Cubit<PaneNodeState> {
  PaneNodeCubit(int length, double size)
      : super(
          PaneNodeState.initial(
            length: length,
            size: size,
          ),
        );

  void resizeStart() {
    emit(state.copyWith(resizeStart: state.resizeOffset));
  }

  void paneResized(
    int targetIndex,
    double offset,
    double availableWidth,
  ) {
    final newPosition = (state.resizeStart[targetIndex] + offset);
    if (state.resizeOffset[targetIndex] != newPosition) {
      final change = offset;

      final flex = [...state.flex];
      const minFlex = 0.15;

      double prefixFlex = 0;
      for (int i = 0; i < targetIndex - 1; i++) {
        prefixFlex += flex[i];
      }

      final direction = change > 0 ? 1 : -1;
      final changeFlex = change / availableWidth;

      if (direction > 0) {
        int targetReduction = targetIndex;
        while (flex[targetReduction] <= minFlex) {
          targetReduction++;
          if (targetReduction >= flex.length) return;
        }
        final newFlex = changeFlex.abs();
        flex[targetIndex - 1] = min(flex[targetIndex - 1] + newFlex,
            1 - ((flex.length - targetIndex) * minFlex + prefixFlex));

        flex[targetReduction] = max(flex[targetReduction] - newFlex, minFlex);
      } else {
        int targetReduction = targetIndex - 1;
        while (flex[targetReduction] <= minFlex) {
          targetReduction--;
          if (targetReduction < 0) return;
        }
        final newFlex = changeFlex.abs();
        flex[targetIndex] = min(flex[targetIndex] + newFlex,
            1 - ((flex.length - targetIndex) * minFlex + prefixFlex));

        flex[targetReduction] = max(flex[targetReduction] - newFlex, minFlex);
      }
      emit(
        state.copyWith(
            flex: flex,
            resizeOffset: state.resizeOffset..[targetIndex] = newPosition),
      );
    }
  }
}
