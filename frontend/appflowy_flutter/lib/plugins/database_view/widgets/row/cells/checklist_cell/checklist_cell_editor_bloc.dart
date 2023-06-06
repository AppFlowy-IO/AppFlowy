import 'dart:async';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/checklist_cell_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_cell_editor_bloc.freezed.dart';

class ChecklistCellEditorBloc
    extends Bloc<ChecklistCellEditorEvent, ChecklistCellEditorState> {
  final ChecklistCellBackendService _checklistCellService;
  final ChecklistCellController cellController;

  ChecklistCellEditorBloc({
    required this.cellController,
  })  : _checklistCellService = ChecklistCellBackendService(
          cellContext: cellController.cellContext,
        ),
        super(ChecklistCellEditorState.initial(cellController)) {
    on<ChecklistCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveOptions: (data) {
            emit(
              state.copyWith(
                allOptions: _makeChecklistSelectOptions(data, state.predicate),
                percent: data.percentage,
              ),
            );
          },
          newOption: (optionName) {
            _createOption(optionName);
            emit(
              state.copyWith(
                createOption: Some(optionName),
                predicate: '',
              ),
            );
          },
          deleteOption: (option) {
            _deleteOption([option]);
          },
          updateOption: (option) {
            _updateOption(option);
          },
          selectOption: (option) async {
            await _checklistCellService.select(optionId: option.data.id);
          },
          filterOption: (String predicate) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await cellController.dispose();
    return super.close();
  }

  void _createOption(String name) async {
    final result = await _checklistCellService.create(name: name);
    result.fold((l) => {}, (err) => Log.error(err));
  }

  void _deleteOption(List<SelectOptionPB> options) async {
    final result = await _checklistCellService.delete(
      optionIds: options.map((e) => e.id).toList(),
    );
    result.fold((l) => null, (err) => Log.error(err));
  }

  void _updateOption(SelectOptionPB option) async {
    final result = await _checklistCellService.update(
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _loadOptions() {
    _checklistCellService.getCellData().then((result) {
      if (isClosed) return;

      return result.fold(
        (data) => add(ChecklistCellEditorEvent.didReceiveOptions(data)),
        (err) => Log.error(err),
      );
    });
  }

  void _startListening() {
    cellController.startListening(
      onCellChanged: ((data) {
        if (!isClosed && data != null) {
          add(ChecklistCellEditorEvent.didReceiveOptions(data));
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
  const factory ChecklistCellEditorEvent.didReceiveOptions(
    ChecklistCellDataPB data,
  ) = _DidReceiveOptions;
  const factory ChecklistCellEditorEvent.newOption(String optionName) =
      _NewOption;
  const factory ChecklistCellEditorEvent.selectOption(
    ChecklistSelectOption option,
  ) = _SelectOption;
  const factory ChecklistCellEditorEvent.updateOption(SelectOptionPB option) =
      _UpdateOption;
  const factory ChecklistCellEditorEvent.deleteOption(SelectOptionPB option) =
      _DeleteOption;
  const factory ChecklistCellEditorEvent.filterOption(String predicate) =
      _FilterOption;
}

@freezed
class ChecklistCellEditorState with _$ChecklistCellEditorState {
  const factory ChecklistCellEditorState({
    required List<ChecklistSelectOption> allOptions,
    required Option<String> createOption,
    required double percent,
    required String predicate,
  }) = _ChecklistCellEditorState;

  factory ChecklistCellEditorState.initial(ChecklistCellController context) {
    final data = context.getCellData(loadIfNotExist: true);

    return ChecklistCellEditorState(
      allOptions: _makeChecklistSelectOptions(data, ''),
      createOption: none(),
      percent: data?.percentage ?? 0,
      predicate: '',
    );
  }
}

List<ChecklistSelectOption> _makeChecklistSelectOptions(
  ChecklistCellDataPB? data,
  String predicate,
) {
  if (data == null) {
    return [];
  }

  final List<ChecklistSelectOption> options = [];
  final List<SelectOptionPB> allOptions = List.from(data.options);
  if (predicate.isNotEmpty) {
    allOptions.retainWhere((element) => element.name.contains(predicate));
  }
  final selectedOptionIds = data.selectedOptions.map((e) => e.id).toList();

  for (final option in allOptions) {
    options.add(
      ChecklistSelectOption(selectedOptionIds.contains(option.id), option),
    );
  }

  return options;
}

class ChecklistSelectOption {
  final bool isSelected;
  final SelectOptionPB data;

  ChecklistSelectOption(this.isSelected, this.data);
}
