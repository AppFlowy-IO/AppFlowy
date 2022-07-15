import 'dart:async';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';

part 'select_option_cell_bloc.freezed.dart';

class SelectOptionCellBloc extends Bloc<SelectOptionCellEvent, SelectOptionCellState> {
  final GridSelectOptionCellController cellContext;
  void Function()? _onCellChangedFn;

  SelectOptionCellBloc({
    required this.cellContext,
  }) : super(SelectOptionCellState.initial(cellContext)) {
    on<SelectOptionCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(
              selectedOptions: value.selectedOptions,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
      onCellChanged: ((selectOptionContext) {
        if (!isClosed) {
          add(SelectOptionCellEvent.didReceiveOptions(
            selectOptionContext?.selectOptions ?? [],
          ));
        }
      }),
    );
  }
}

@freezed
class SelectOptionCellEvent with _$SelectOptionCellEvent {
  const factory SelectOptionCellEvent.initial() = _InitialCell;
  const factory SelectOptionCellEvent.didReceiveOptions(
    List<SelectOption> selectedOptions,
  ) = _DidReceiveOptions;
}

@freezed
class SelectOptionCellState with _$SelectOptionCellState {
  const factory SelectOptionCellState({
    required List<SelectOption> selectedOptions,
  }) = _SelectOptionCellState;

  factory SelectOptionCellState.initial(GridSelectOptionCellController context) {
    final data = context.getCellData();

    return SelectOptionCellState(
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
