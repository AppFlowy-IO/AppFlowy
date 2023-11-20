import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/checklist_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
part 'checklist_cell_bloc.freezed.dart';

class ChecklistSelectOption {
  final bool isSelected;
  final SelectOptionPB data;

  ChecklistSelectOption(this.isSelected, this.data);
}

class ChecklistCellBloc extends Bloc<ChecklistCellEvent, ChecklistCellState> {
  final ChecklistCellController cellController;
  final ChecklistCellBackendService _checklistCellService;
  void Function()? _onCellChangedFn;
  ChecklistCellBloc({
    required this.cellController,
  })  : _checklistCellService = ChecklistCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(ChecklistCellState.initial(cellController)) {
    on<ChecklistCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          didReceiveOptions: (data) {
            if (data == null) {
              emit(
                const ChecklistCellState(
                  tasks: [],
                  percent: 0,
                  newTask: false,
                ),
              );
              return;
            }

            emit(
              state.copyWith(
                tasks: _makeChecklistSelectOptions(data),
                percent: data.percentage,
              ),
            );
          },
          updateTaskName: (option, name) {
            _updateOption(option, name);
          },
          selectTask: (option) async {
            await _checklistCellService.select(optionId: option.id);
          },
          createNewTask: (name) async {
            final result = await _checklistCellService.create(name: name);
            result.fold(
              (l) => emit(state.copyWith(newTask: true)),
              (err) => Log.error(err),
            );
          },
          deleteTask: (option) async {
            await _deleteOption([option]);
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
      onCellChanged: (data) {
        if (!isClosed) {
          add(ChecklistCellEvent.didReceiveOptions(data));
        }
      },
    );
  }

  void _updateOption(SelectOptionPB option, String name) async {
    final result =
        await _checklistCellService.updateName(option: option, name: name);

    result.fold((l) => null, (err) => Log.error(err));
  }

  Future<void> _deleteOption(List<SelectOptionPB> options) async {
    final result = await _checklistCellService.delete(
      optionIds: options.map((e) => e.id).toList(),
    );
    result.fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class ChecklistCellEvent with _$ChecklistCellEvent {
  const factory ChecklistCellEvent.initial() = _InitialCell;
  const factory ChecklistCellEvent.didReceiveOptions(
    ChecklistCellDataPB? data,
  ) = _DidReceiveCellUpdate;
  const factory ChecklistCellEvent.updateTaskName(
    SelectOptionPB option,
    String name,
  ) = _UpdateTaskName;
  const factory ChecklistCellEvent.selectTask(SelectOptionPB task) =
      _SelectTask;
  const factory ChecklistCellEvent.createNewTask(String description) =
      _CreateNewTask;
  const factory ChecklistCellEvent.deleteTask(SelectOptionPB option) =
      _DeleteTask;
}

@freezed
class ChecklistCellState with _$ChecklistCellState {
  const factory ChecklistCellState({
    required List<ChecklistSelectOption> tasks,
    required double percent,
    required bool newTask,
  }) = _ChecklistCellState;

  factory ChecklistCellState.initial(ChecklistCellController cellController) {
    final cellData = cellController.getCellData(loadIfNotExist: true);

    return ChecklistCellState(
      tasks: _makeChecklistSelectOptions(cellData),
      percent: cellData?.percentage ?? 0,
      newTask: false,
    );
  }
}

List<ChecklistSelectOption> _makeChecklistSelectOptions(
  ChecklistCellDataPB? data,
) {
  if (data == null) {
    return [];
  }

  final List<ChecklistSelectOption> options = [];
  final List<SelectOptionPB> allOptions = List.from(data.options);
  final selectedOptionIds = data.selectedOptions.map((e) => e.id).toList();

  for (final option in allOptions) {
    options.add(
      ChecklistSelectOption(selectedOptionIds.contains(option.id), option),
    );
  }

  return options;
}
