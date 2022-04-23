import 'dart:async';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/application/grid/cell/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';

part 'selection_cell_bloc.freezed.dart';

class SelectionCellBloc extends Bloc<SelectionCellEvent, SelectionCellState> {
  final SingleFieldListener _fieldListener;
  final GridCellContext<SelectOptionContext> cellContext;

  SelectionCellBloc({
    required this.cellContext,
  })  : _fieldListener = SingleFieldListener(fieldId: cellContext.fieldId),
        super(SelectionCellState.initial(cellContext)) {
    on<SelectionCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(
              options: value.options,
              selectedOptions: value.selectedOptions,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    cellContext.removeListener();
    return super.close();
  }

  void _startListening() {
    cellContext.onCellChanged((selectOptionContext) {
      if (!isClosed) {
        add(SelectionCellEvent.didReceiveOptions(
          selectOptionContext.options,
          selectOptionContext.selectOptions,
        ));
      }
    });

    cellContext.onFieldChanged(() => cellContext.reloadCellData());
  }
}

@freezed
class SelectionCellEvent with _$SelectionCellEvent {
  const factory SelectionCellEvent.initial() = _InitialCell;
  const factory SelectionCellEvent.didReceiveOptions(
    List<SelectOption> options,
    List<SelectOption> selectedOptions,
  ) = _DidReceiveOptions;
}

@freezed
class SelectionCellState with _$SelectionCellState {
  const factory SelectionCellState({
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  }) = _SelectionCellState;

  factory SelectionCellState.initial(GridCellContext<SelectOptionContext> context) {
    final data = context.getCellData();

    return SelectionCellState(
      options: data?.options ?? [],
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
