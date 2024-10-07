import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/domain/checklist_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_cell_bloc.freezed.dart';

class ChecklistSelectOption {
  ChecklistSelectOption({required this.isSelected, required this.data});

  final bool isSelected;
  final SelectOptionPB data;
}

class ChecklistCellBloc extends Bloc<ChecklistCellEvent, ChecklistCellState> {
  ChecklistCellBloc({required this.cellController})
      : _checklistCellService = ChecklistCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(ChecklistCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final ChecklistCellController cellController;
  final ChecklistCellBackendService _checklistCellService;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(onCellChanged: _onCellChangedFn!);
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<ChecklistCellEvent>(
      (event, emit) async {
        await event.when(
          didUpdateCell: (data) {
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
          selectTask: (id) async {
            await _checklistCellService.select(optionId: id);
          },
          createNewTask: (name) async {
            final result = await _checklistCellService.create(name: name);
            result.fold(
              (l) => emit(state.copyWith(newTask: true)),
              (err) => Log.error(err),
            );
          },
          deleteTask: (id) async {
            await _deleteOption([id]);
          },
          reorderTask: (fromIndex, toIndex) async {
            await _reorderTask(fromIndex, toIndex, emit);
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(ChecklistCellEvent.didUpdateCell(data));
        }
      },
    );
  }

  void _updateOption(SelectOptionPB option, String name) async {
    final result =
        await _checklistCellService.updateName(option: option, name: name);
    result.fold((l) => null, (err) => Log.error(err));
  }

  Future<void> _deleteOption(List<String> options) async {
    final result = await _checklistCellService.delete(optionIds: options);
    result.fold((l) => null, (err) => Log.error(err));
  }

  Future<void> _reorderTask(
    int fromIndex,
    int toIndex,
    Emitter<ChecklistCellState> emit,
  ) async {
    if (fromIndex < toIndex) {
      toIndex--;
    }

    final fromId = state.tasks[fromIndex].data.id;
    final toId = state.tasks[toIndex].data.id;

    final newTasks = [...state.tasks];
    newTasks.insert(toIndex, newTasks.removeAt(fromIndex));
    emit(state.copyWith(tasks: newTasks));
    final result = await _checklistCellService.reorder(
      fromTaskId: fromId,
      toTaskId: toId,
    );
    result.fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class ChecklistCellEvent with _$ChecklistCellEvent {
  const factory ChecklistCellEvent.didUpdateCell(
    ChecklistCellDataPB? data,
  ) = _DidUpdateCell;
  const factory ChecklistCellEvent.updateTaskName(
    SelectOptionPB option,
    String name,
  ) = _UpdateTaskName;
  const factory ChecklistCellEvent.selectTask(String taskId) = _SelectTask;
  const factory ChecklistCellEvent.createNewTask(String description) =
      _CreateNewTask;
  const factory ChecklistCellEvent.deleteTask(String taskId) = _DeleteTask;
  const factory ChecklistCellEvent.reorderTask(int fromIndex, int toIndex) =
      _ReorderTask;
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
  return data.options
      .map(
        (option) => ChecklistSelectOption(
          isSelected: data.selectedOptions.any(
            (selected) => selected.id == option.id,
          ),
          data: option,
        ),
      )
      .toList();
}
