import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/checklist_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
part 'checklist_cell_bloc.freezed.dart';

class ChecklistCardCellBloc
    extends Bloc<ChecklistCellEvent, ChecklistCellState> {
  final ChecklistCellController cellController;
  final ChecklistCellBackendService _checklistCellSvc;
  void Function()? _onCellChangedFn;
  ChecklistCardCellBloc({
    required this.cellController,
  })  : _checklistCellSvc = ChecklistCellBackendService(
          cellContext: cellController.cellContext,
        ),
        super(ChecklistCellState.initial(cellController)) {
    on<ChecklistCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveOptions: (data) {
            emit(
              state.copyWith(
                allOptions: data.options,
                selectedOptions: data.selectedOptions,
                percent: data.percentage,
              ),
            );
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
    _checklistCellSvc.getCellData().then((result) {
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
    ChecklistCellDataPB data,
  ) = _DidReceiveCellUpdate;
}

@freezed
class ChecklistCellState with _$ChecklistCellState {
  const factory ChecklistCellState({
    required List<SelectOptionPB> allOptions,
    required List<SelectOptionPB> selectedOptions,
    required double percent,
  }) = _ChecklistCellState;

  factory ChecklistCellState.initial(ChecklistCellController cellController) {
    return const ChecklistCellState(
      allOptions: [],
      selectedOptions: [],
      percent: 0,
    );
  }
}
