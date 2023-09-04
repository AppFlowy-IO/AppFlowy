import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'pane_size_state.dart';

class PaneSizeCubit extends Cubit<PaneSizeState> {
  PaneSizeCubit({required double offset})
      : super(PaneSizeState.initial(offset: offset));

  void editPanelResizeStart() {
    emit(
      state.copyWith(
        resizeStart: state.resizeOffset,
      ),
    );
  }

  void editPanelResized(double offset) {
    final newPosition = (offset + state.resizeStart);
    emit(state.copyWith(resizeOffset: newPosition));
  }

  void editPanelResizeEnd() {}
}
