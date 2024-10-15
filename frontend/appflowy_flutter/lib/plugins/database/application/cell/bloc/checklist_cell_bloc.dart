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

  int? nextPhantomIndex;

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
                  showIncompleteOnly: false,
                  phantomIndex: null,
                ),
              );
              return;
            }
            final phantomIndex = state.phantomIndex != null
                ? nextPhantomIndex ?? state.phantomIndex
                : null;
            emit(
              state.copyWith(
                tasks: _makeChecklistSelectOptions(data),
                percent: data.percentage,
                phantomIndex: phantomIndex,
              ),
            );
            nextPhantomIndex = null;
          },
          updateTaskName: (option, name) {
            _updateOption(option, name);
          },
          selectTask: (id) async {
            await _checklistCellService.select(optionId: id);
          },
          createNewTask: (name, index) async {
            await _createTask(name, index);
          },
          deleteTask: (id) async {
            await _deleteOption([id]);
          },
          reorderTask: (fromIndex, toIndex) async {
            await _reorderTask(fromIndex, toIndex, emit);
          },
          toggleShowIncompleteOnly: () {
            emit(state.copyWith(showIncompleteOnly: !state.showIncompleteOnly));
          },
          updatePhantomIndex: (index) {
            emit(
              ChecklistCellState(
                tasks: state.tasks,
                percent: state.percent,
                showIncompleteOnly: state.showIncompleteOnly,
                phantomIndex: index,
              ),
            );
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

  Future<void> _createTask(String name, int? index) async {
    nextPhantomIndex = index == null ? state.tasks.length + 1 : index + 1;

    int? actualIndex = index;
    if (index != null && state.showIncompleteOnly) {
      int notSelectedTaskCount = 0;
      for (int i = 0; i < state.tasks.length; i++) {
        if (!state.tasks[i].isSelected) {
          notSelectedTaskCount++;
        }

        if (notSelectedTaskCount == index) {
          actualIndex = i + 1;
          break;
        }
      }
    }

    final result = await _checklistCellService.create(
      name: name,
      index: actualIndex,
    );
    result.fold((l) {}, (err) => Log.error(err));
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

    final tasks = state.showIncompleteOnly
        ? state.tasks.where((task) => !task.isSelected).toList()
        : state.tasks;

    final fromId = tasks[fromIndex].data.id;
    final toId = tasks[toIndex].data.id;

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
  const factory ChecklistCellEvent.createNewTask(
    String description, {
    int? index,
  }) = _CreateNewTask;
  const factory ChecklistCellEvent.deleteTask(String taskId) = _DeleteTask;
  const factory ChecklistCellEvent.reorderTask(int fromIndex, int toIndex) =
      _ReorderTask;

  const factory ChecklistCellEvent.toggleShowIncompleteOnly() = _IncompleteOnly;
  const factory ChecklistCellEvent.updatePhantomIndex(int? index) =
      _UpdatePhantomIndex;
}

@freezed
class ChecklistCellState with _$ChecklistCellState {
  const factory ChecklistCellState({
    required List<ChecklistSelectOption> tasks,
    required double percent,
    required bool showIncompleteOnly,
    required int? phantomIndex,
  }) = _ChecklistCellState;

  factory ChecklistCellState.initial(ChecklistCellController cellController) {
    final cellData = cellController.getCellData(loadIfNotExist: true);

    return ChecklistCellState(
      tasks: _makeChecklistSelectOptions(cellData),
      percent: cellData?.percentage ?? 0,
      showIncompleteOnly: false,
      phantomIndex: null,
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
