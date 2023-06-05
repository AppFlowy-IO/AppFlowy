import 'dart:async';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_cell_editor_bloc.freezed.dart';

class ChecklistCellEditorBloc
    extends Bloc<ChecklistCellEditorEvent, ChecklistCellEditorState> {
  final SelectOptionBackendService _selectOptionService;
  final ChecklistCellController cellController;

  ChecklistCellEditorBloc({
    required this.cellController,
  })  : _selectOptionService =
            SelectOptionBackendService(cellId: cellController.cellId),
        super(ChecklistCellEditorState.initial(cellController)) {
    on<ChecklistCellEditorEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadOptions();
          },
          didReceiveOptions: (final data) {
            emit(
              state.copyWith(
                allOptions: _makeChecklistSelectOptions(data, state.predicate),
                percent: percentFromSelectOptionCellData(data),
              ),
            );
          },
          newOption: (final optionName) {
            _createOption(optionName);
            emit(
              state.copyWith(
                predicate: '',
              ),
            );
          },
          deleteOption: (final option) {
            _deleteOption([option]);
          },
          updateOption: (final option) {
            _updateOption(option);
          },
          selectOption: (final option) async {
            if (option.isSelected) {
              await _selectOptionService.unSelect(optionIds: [option.data.id]);
            } else {
              await _selectOptionService.select(optionIds: [option.data.id]);
            }
          },
          filterOption: (final String predicate) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await cellController.dispose();
    return super.close();
  }

  void _createOption(final String name) async {
    final result = await _selectOptionService.create(
      name: name,
      isSelected: false,
    );
    result.fold((final l) => {}, (final err) => Log.error(err));
  }

  void _deleteOption(final List<SelectOptionPB> options) async {
    final result = await _selectOptionService.delete(options: options);
    result.fold((final l) => null, (final err) => Log.error(err));
  }

  void _updateOption(final SelectOptionPB option) async {
    final result = await _selectOptionService.update(
      option: option,
    );

    result.fold((final l) => null, (final err) => Log.error(err));
  }

  void _loadOptions() {
    _selectOptionService.getCellData().then((final result) {
      if (isClosed) return;

      return result.fold(
        (final data) => add(ChecklistCellEditorEvent.didReceiveOptions(data)),
        (final err) => Log.error(err),
      );
    });
  }

  void _startListening() {
    cellController.startListening(
      onCellChanged: ((final data) {
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
    final SelectOptionCellDataPB data,
  ) = _DidReceiveOptions;
  const factory ChecklistCellEditorEvent.newOption(final String optionName) =
      _NewOption;
  const factory ChecklistCellEditorEvent.selectOption(
    final ChecklistSelectOption option,
  ) = _SelectOption;
  const factory ChecklistCellEditorEvent.updateOption(final SelectOptionPB option) =
      _UpdateOption;
  const factory ChecklistCellEditorEvent.deleteOption(final SelectOptionPB option) =
      _DeleteOption;
  const factory ChecklistCellEditorEvent.filterOption(final String predicate) =
      _FilterOption;
}

@freezed
class ChecklistCellEditorState with _$ChecklistCellEditorState {
  const factory ChecklistCellEditorState({
    required final List<ChecklistSelectOption> allOptions,
    required final Option<String> createOption,
    required final double percent,
    required final String predicate,
  }) = _ChecklistCellEditorState;

  factory ChecklistCellEditorState.initial(final SelectOptionCellController context) {
    final data = context.getCellData(loadIfNotExist: true);

    return ChecklistCellEditorState(
      allOptions: _makeChecklistSelectOptions(data, ''),
      createOption: none(),
      percent: percentFromSelectOptionCellData(data),
      predicate: '',
    );
  }
}

double percentFromSelectOptionCellData(final SelectOptionCellDataPB? data) {
  if (data == null) return 0;

  final b = data.options.length.toDouble();
  if (b == 0) {
    return 0;
  }

  final a = data.selectOptions.length.toDouble();
  if (a > b) return 1.0;

  return a / b;
}

List<ChecklistSelectOption> _makeChecklistSelectOptions(
  final SelectOptionCellDataPB? data,
  final String predicate,
) {
  if (data == null) {
    return [];
  }

  final List<ChecklistSelectOption> options = [];
  final List<SelectOptionPB> allOptions = List.from(data.options);
  if (predicate.isNotEmpty) {
    allOptions.retainWhere((final element) => element.name.contains(predicate));
  }
  final selectedOptionIds = data.selectOptions.map((final e) => e.id).toList();

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
