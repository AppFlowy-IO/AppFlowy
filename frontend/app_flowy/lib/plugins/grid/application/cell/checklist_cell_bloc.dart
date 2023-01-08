import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';
import 'checklist_cell_editor_bloc.dart';
import 'select_option_service.dart';
part 'checklist_cell_bloc.freezed.dart';

class ChecklistCellBloc extends Bloc<ChecklistCellEvent, ChecklistCellState> {
  final GridChecklistCellController cellController;
  final SelectOptionFFIService _selectOptionService;
  void Function()? _onCellChangedFn;
  ChecklistCellBloc({
    required this.cellController,
  })  : _selectOptionService =
            SelectOptionFFIService(cellId: cellController.cellId),
        super(ChecklistCellState.initial(cellController)) {
    on<ChecklistCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveOptions: (data) {
            emit(state.copyWith(
              allOptions: data.options,
              selectedOptions: data.selectOptions,
              percent: percentFromSelectOptionCellData(data),
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellFieldChanged: () {
        _loadOptions();
      },
      onCellChanged: (data) {
        if (!isClosed && data != null) {
          add(ChecklistCellEvent.didReceiveOptions(data));
        }
      },
    );
  }

  void _loadOptions() {
    _selectOptionService.getOptionContext().then((result) {
      if (isClosed) return;

      return result.fold(
        (data) => add(ChecklistCellEvent.didReceiveOptions(data)),
        (err) => Log.error(err),
      );
    });
  }
}

@freezed
class ChecklistCellEvent with _$ChecklistCellEvent {
  const factory ChecklistCellEvent.initial() = _InitialCell;
  const factory ChecklistCellEvent.didReceiveOptions(
      SelectOptionCellDataPB data) = _DidReceiveCellUpdate;
}

@freezed
class ChecklistCellState with _$ChecklistCellState {
  const factory ChecklistCellState({
    required List<SelectOptionPB> allOptions,
    required List<SelectOptionPB> selectedOptions,
    required double percent,
  }) = _ChecklistCellState;

  factory ChecklistCellState.initial(
      GridChecklistCellController cellController) {
    return const ChecklistCellState(
      allOptions: [],
      selectedOptions: [],
      percent: 0,
    );
  }
}
