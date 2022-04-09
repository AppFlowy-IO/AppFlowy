import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/cell_bloc/select_option_service.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'selection_cell_bloc.freezed.dart';

class SelectionCellBloc extends Bloc<SelectionCellEvent, SelectionCellState> {
  final SelectOptionService _service;
  final CellListener _cellListener;
  final FieldListener _fieldListener;

  SelectionCellBloc({
    required CellData cellData,
  })  : _service = SelectOptionService(),
        _cellListener = CellListener(rowId: cellData.rowId, fieldId: cellData.field.id),
        _fieldListener = FieldListener(fieldId: cellData.field.id),
        super(SelectionCellState.initial(cellData)) {
    on<SelectionCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _loadOptions();
            _startListening();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(options: value.options, selectedOptions: value.selectedOptions));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _cellListener.stop();
    await _fieldListener.stop();
    return super.close();
  }

  void _loadOptions() async {
    final result = await _service.getOpitonContext(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
    );

    result.fold(
      (selectOptionContext) => add(SelectionCellEvent.didReceiveOptions(
        selectOptionContext.options,
        selectOptionContext.selectOptions,
      )),
      (err) => Log.error(err),
    );
  }

  void _startListening() {
    _cellListener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (notificationData) => _loadOptions(),
        (err) => Log.error(err),
      );
    });
    _cellListener.start();

    _fieldListener.updateFieldNotifier.addPublishListener((result) {
      result.fold(
        (field) => _loadOptions(),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
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
    required CellData cellData,
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  }) = _SelectionCellState;

  factory SelectionCellState.initial(CellData cellData) => SelectionCellState(
        cellData: cellData,
        options: [],
        selectedOptions: [],
      );
}
