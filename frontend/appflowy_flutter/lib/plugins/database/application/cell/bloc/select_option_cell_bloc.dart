import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_cell_bloc.freezed.dart';

class SelectOptionCellBloc
    extends Bloc<SelectOptionCellEvent, SelectOptionCellState> {
  SelectOptionCellBloc({required this.cellController})
      : super(SelectOptionCellState.initial(cellController)) {
    _dispatch();
  }

  final SelectOptionCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<SelectOptionCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveOptions: (List<SelectOptionPB> selectedOptions) {
            emit(
              state.copyWith(
                selectedOptions: selectedOptions,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (selectOptionCellData) {
        if (!isClosed) {
          add(
            SelectOptionCellEvent.didReceiveOptions(
              selectOptionCellData?.selectOptions ?? [],
            ),
          );
        }
      },
    );
  }
}

@freezed
class SelectOptionCellEvent with _$SelectOptionCellEvent {
  const factory SelectOptionCellEvent.initial() = _InitialCell;
  const factory SelectOptionCellEvent.didReceiveOptions(
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
}

@freezed
class SelectOptionCellState with _$SelectOptionCellState {
  const factory SelectOptionCellState({
    required List<SelectOptionPB> selectedOptions,
  }) = _SelectOptionCellState;

  factory SelectOptionCellState.initial(
    SelectOptionCellController cellController,
  ) {
    final data = cellController.getCellData();

    return SelectOptionCellState(
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
