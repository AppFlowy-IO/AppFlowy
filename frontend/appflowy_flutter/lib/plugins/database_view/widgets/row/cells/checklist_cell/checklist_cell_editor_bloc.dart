import 'dart:async';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/checklist_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_cell_editor_bloc.freezed.dart';

class ChecklistSelectOption {
  final bool isSelected;
  final SelectOptionPB data;

  ChecklistSelectOption(this.isSelected, this.data);
}

class ChecklistCellEditorBloc
    extends Bloc<ChecklistCellEditorEvent, ChecklistCellEditorState> {
  final ChecklistCellBackendService _checklistCellService;
  final ChecklistCellController cellController;

  ChecklistCellEditorBloc({
    required this.cellController,
  })  : _checklistCellService = ChecklistCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(ChecklistCellEditorState.initial(cellController)) {
    on<ChecklistCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveTasks: (data) {
            emit(
              state.copyWith(
                allOptions: _makeChecklistSelectOptions(data),
                percent: data?.percentage ?? 0,
              ),
            );
          },
          newTask: (optionName) async {
            await _createOption(optionName);
            emit(
              state.copyWith(
                createOption: Some(optionName),
              ),
            );
          },
          deleteTask: (option) async {
            await _deleteOption([option]);
          },
          updateTaskName: (option, name) {
            _updateOption(option, name);
          },
          selectTask: (option) async {
            await _checklistCellService.select(optionId: option.id);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await cellController.dispose();
    return super.close();
  }

  Future<void> _createOption(String name) async {
    final result = await _checklistCellService.create(name: name);
    result.fold((l) => {}, (err) => Log.error(err));
  }

  Future<void> _deleteOption(List<SelectOptionPB> options) async {
    final result = await _checklistCellService.delete(
      optionIds: options.map((e) => e.id).toList(),
    );
    result.fold((l) => null, (err) => Log.error(err));
  }

  void _updateOption(SelectOptionPB option, String name) async {
    final result =
        await _checklistCellService.updateName(option: option, name: name);

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _loadOptions() {
    _checklistCellService.getCellData().then((result) {
      if (isClosed) return;

      return result.fold(
        (data) => add(ChecklistCellEditorEvent.didReceiveTasks(data)),
        (err) => Log.error(err),
      );
    });
  }

  void _startListening() {
    cellController.startListening(
      onCellChanged: ((data) {
        if (!isClosed) {
          add(ChecklistCellEditorEvent.didReceiveTasks(data));
        }
      }),
      onCellFieldChanged: () {
        _loadOptions();
      },
    );
  }
}

@freezed
class ChecklistCellEditorEvent with _$ChecklistCellEditorEvent {
  const factory ChecklistCellEditorEvent.initial() = _Initial;
  const factory ChecklistCellEditorEvent.didReceiveTasks(
    ChecklistCellDataPB? data,
  ) = _DidReceiveTasks;
  const factory ChecklistCellEditorEvent.newTask(String taskName) = _NewOption;
  const factory ChecklistCellEditorEvent.selectTask(
    SelectOptionPB option,
  ) = _SelectTask;
  const factory ChecklistCellEditorEvent.updateTaskName(
    SelectOptionPB option,
    String name,
  ) = _UpdateTaskName;
  const factory ChecklistCellEditorEvent.deleteTask(SelectOptionPB option) =
      _DeleteTask;
}

@freezed
class ChecklistCellEditorState with _$ChecklistCellEditorState {
  const factory ChecklistCellEditorState({
    required List<ChecklistSelectOption> allOptions,
    required Option<String> createOption,
    required double percent,
  }) = _ChecklistCellEditorState;

  factory ChecklistCellEditorState.initial(ChecklistCellController context) {
    final data = context.getCellData(loadIfNotExist: true);

    return ChecklistCellEditorState(
      allOptions: _makeChecklistSelectOptions(data),
      createOption: none(),
      percent: data?.percentage ?? 0,
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
