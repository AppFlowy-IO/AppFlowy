import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pane_node_bloc.freezed.dart';

class PaneNodeBloc extends Bloc<PaneNodeEvent, PaneNodeState> {
  PaneNodeBloc(int length, double size)
      : super(PaneNodeState.initial(length: length, size: size)) {
    on<PaneNodeEvent>(
      (event, emit) {
        event.map(
          resizeStart: (_) {},
          resizeUpdate: (update) {
            final change = update.offset;

            final flex = [...state.flex];
            const minFlex = 0.15;

            double prefixFlex = 0;
            for (int i = 0; i < update.targetIndex - 1; i++) {
              prefixFlex += flex[i];
            }

            final direction = change > 0 ? 1 : -1;
            final changeFlex = change / update.availableWidth;

            if (direction > 0) {
              int targetReduction = update.targetIndex;
              while (flex[targetReduction] <= minFlex) {
                targetReduction++;
                if (targetReduction >= flex.length) return;
              }
              final newFlex = changeFlex.abs();
              flex[update.targetIndex - 1] = min(
                flex[update.targetIndex - 1] + newFlex,
                1 - ((flex.length - update.targetIndex) * minFlex + prefixFlex),
              );

              flex[targetReduction] =
                  max(flex[targetReduction] - newFlex, minFlex);
            } else {
              int targetReduction = update.targetIndex - 1;
              while (flex[targetReduction] <= minFlex) {
                targetReduction--;
                if (targetReduction < 0) return;
              }
              final newFlex = changeFlex.abs();
              flex[update.targetIndex] = min(
                flex[update.targetIndex] + newFlex,
                1 - ((flex.length - update.targetIndex) * minFlex + prefixFlex),
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

@freezed
class PaneNodeEvent with _$PaneNodeEvent {
  const factory PaneNodeEvent.resizeStart() = ResizeStart;
  const factory PaneNodeEvent.resizeUpdate({
    required int targetIndex,
    required double offset,
    required double availableWidth,
  }) = ResizeUpdate;
}

@freezed
class PaneNodeState with _$PaneNodeState {
  const factory PaneNodeState({required List<double> flex}) = _PaneNodeState;

  factory PaneNodeState.initial({
    required int length,
    required double size,
  }) =>
      PaneNodeState(flex: List.generate(length, (_) => 1 / length));
}
