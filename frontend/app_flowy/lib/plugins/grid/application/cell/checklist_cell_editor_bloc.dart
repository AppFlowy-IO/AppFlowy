import 'dart:async';

import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'select_option_service.dart';

part 'checklist_cell_editor_bloc.freezed.dart';

class ChecklistCellEditorBloc
    extends Bloc<ChecklistCellEditorEvent, ChecklistCellEditorState> {
  final SelectOptionFFIService _selectOptionService;
  final GridChecklistCellController cellController;
  Timer? _delayOperation;

  ChecklistCellEditorBloc({
    required this.cellController,
  })  : _selectOptionService =
            SelectOptionFFIService(cellId: cellController.cellId),
        super(ChecklistCellEditorState.initial(cellController)) {
    on<ChecklistCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveOptions: (data) {
            emit(state.copyWith(
              allOptions: _makeChecklistSelectOptions(data, state.predicate),
              percent: _percentFromSelectOptionCellData(data),
            ));
          },
          newOption: (optionName) {
            _createOption(optionName);
            emit(state.copyWith(
              predicate: '',
            ));
          },
          deleteOption: (option) {
            _deleteOption([option]);
          },
          updateOption: (option) {
            _updateOption(option);
          },
          selectOption: (optionId) {
            _selectOptionService.select(optionIds: [optionId]);
          },
          unSelectOption: (optionId) {
            _selectOptionService.unSelect(optionIds: [optionId]);
          },
          filterOption: (String predicate) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _delayOperation?.cancel();
    await cellController.dispose();
    return super.close();
  }

  void _createOption(String name) async {
    final result = await _selectOptionService.create(
      name: name,
      isSelected: false,
    );
    result.fold((l) => {}, (err) => Log.error(err));
  }

  void _deleteOption(List<SelectOptionPB> options) async {
    final result = await _selectOptionService.delete(options: options);
    result.fold((l) => null, (err) => Log.error(err));
  }

  void _updateOption(SelectOptionPB option) async {
    final result = await _selectOptionService.update(
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _loadOptions() {
    _selectOptionService.getOptionContext().then((result) {
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
      SelectOptionCellDataPB data) = _DidReceiveOptions;
  const factory ChecklistCellEditorEvent.newOption(String optionName) =
      _NewOption;
  const factory ChecklistCellEditorEvent.selectOption(String optionId) =
      _SelectOption;
  const factory ChecklistCellEditorEvent.unSelectOption(String optionId) =
      _UnSelectOption;
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

  factory ChecklistCellEditorState.initial(
      GridSelectOptionCellController context) {
    final data = context.getCellData(loadIfNotExist: true);

    return ChecklistCellEditorState(
      allOptions: _makeChecklistSelectOptions(data, ''),
      createOption: none(),
      percent: _percentFromSelectOptionCellData(data),
      predicate: '',
    );
  }
}

double _percentFromSelectOptionCellData(SelectOptionCellDataPB? data) {
  if (data == null) return 0;

  final a = data.selectOptions.length.toDouble();
  final b = data.options.length.toDouble();

  if (a > b) return 1.0;

  return a / b;
}

List<ChecklistSelectOption> _makeChecklistSelectOptions(
    SelectOptionCellDataPB? data, String predicate) {
  if (data == null) {
    return [];
  }

  final List<ChecklistSelectOption> options = [];
  final List<SelectOptionPB> allOptions = List.from(data.options);
  if (predicate.isNotEmpty) {
    allOptions.retainWhere((element) => element.name.contains(predicate));
  }
  final selectedOptionIds = data.selectOptions.map((e) => e.id).toList();

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
