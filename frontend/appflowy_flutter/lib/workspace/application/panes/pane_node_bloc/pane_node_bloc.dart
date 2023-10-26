import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pane_node_state.dart';
part 'pane_node_bloc.freezed.dart';
part 'pane_node_event.dart';

class PaneNodeCubit extends Bloc<PaneNodeEvent, PaneNodeState> {
  PaneNodeCubit(int length, double size)
      : super(PaneNodeState.initial(length: length, size: size)) {
    on<PaneNodeEvent>(
      (event, emit) {
        event.map(
          resizeStart: (e) {},
          resizeUpdate: (e) {
            final change = e.offset;

            final flex = [...state.flex];
            const minFlex = 0.15;

            double prefixFlex = 0;
            for (int i = 0; i < e.targetIndex - 1; i++) {
              prefixFlex += flex[i];
            }

            final direction = change > 0 ? 1 : -1;
            final changeFlex = change / e.availableWidth;

            if (direction > 0) {
              int targetReduction = e.targetIndex;
              while (flex[targetReduction] <= minFlex) {
                targetReduction++;
                if (targetReduction >= flex.length) return;
              }
              final newFlex = changeFlex.abs();
              flex[e.targetIndex - 1] = min(
                flex[e.targetIndex - 1] + newFlex,
                1 - ((flex.length - e.targetIndex) * minFlex + prefixFlex),
              );

              flex[targetReduction] =
                  max(flex[targetReduction] - newFlex, minFlex);
            } else {
              int targetReduction = e.targetIndex - 1;
              while (flex[targetReduction] <= minFlex) {
                targetReduction--;
                if (targetReduction < 0) return;
              }
              final newFlex = changeFlex.abs();
              flex[e.targetIndex] = min(
                flex[e.targetIndex] + newFlex,
                1 - ((flex.length - e.targetIndex) * minFlex + prefixFlex),
              );

              flex[targetReduction] = max(
                flex[targetReduction] - newFlex,
                minFlex,
              );
            }
            emit(state.copyWith(flex: flex));
          },
        );
      },
    );
  }
}
