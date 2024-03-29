import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/type_option/select_type_option_actions.dart';
import 'package:appflowy/plugins/database/domain/select_option_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_cell_editor_bloc.freezed.dart';

class SelectOptionCellEditorBloc
    extends Bloc<SelectOptionCellEditorEvent, SelectOptionCellEditorState> {
  SelectOptionCellEditorBloc({required this.cellController})
      : _selectOptionService = SelectOptionCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(SelectOptionCellEditorState.initial(cellController)) {
    _dispatch();
  }

  final SelectOptionCellBackendService _selectOptionService;
  final SelectOptionCellController cellController;

  VoidCallback? _onCellChangedFn;

  void _dispatch() {
    on<SelectOptionCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadOptions();
          },
          didReceiveOptions: (options, selectedOptions) {
            final result = _makeOptions(state.filter, options);
            emit(
              state.copyWith(
                allOptions: options,
                options: result.options,
                createSelectOptionSuggestion:
                    result.createSelectOptionSuggestion,
                selectedOptions: selectedOptions,
              ),
            );
          },
          createOption: () async {
            if (state.createSelectOptionSuggestion == null) {
              return;
            }
            await _createOption(
              name: state.createSelectOptionSuggestion!.name,
              color: state.createSelectOptionSuggestion!.color,
            );
            emit(
              state.copyWith(
                filter: null,
              ),
            );
          },
          deleteOption: (option) async {
            await _deleteOption([option]);
          },
          deleteAllOptions: () async {
            if (state.allOptions.isNotEmpty) {
              await _deleteOption(state.allOptions);
            }
          },
          updateOption: (option) async {
            await _updateOption(option);
          },
          selectOption: (optionId) async {
            await _selectOptionService.select(optionIds: [optionId]);
            final selectedOption = [
              ...state.selectedOptions,
              state.options.firstWhere(
                (element) => element.id == optionId,
              ),
            ];
            emit(
              state.copyWith(
                selectedOptions: selectedOption,
              ),
            );
          },
          unSelectOption: (optionId) async {
            await _selectOptionService.unSelect(optionIds: [optionId]);
            final selectedOptions = [...state.selectedOptions]
              ..removeWhere((e) => e.id == optionId);
            emit(
              state.copyWith(
                selectedOptions: selectedOptions,
              ),
            );
          },
          submitTextFieldValue: (optionName) {
            _submitTextFieldValue(optionName, emit);
          },
          selectMultipleOptions: (optionNames, remainder) {
            if (optionNames.isNotEmpty) {
              _selectMultipleOptions(optionNames);
            }
            _filterOption(remainder, emit);
          },
          filterOption: (optionName) {
            _filterOption(optionName, emit);
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
    return super.close();
  }

  Future<void> _createOption({
    required String name,
    required SelectOptionColorPB color,
  }) async {
    final result = await _selectOptionService.create(
      name: name,
      color: color,
    );
    result.fold((l) => {}, (err) => Log.error(err));
  }

  Future<void> _deleteOption(List<SelectOptionPB> options) async {
    final result = await _selectOptionService.delete(options: options);
    result.fold((l) => null, (err) => Log.error(err));
  }

  Future<void> _updateOption(SelectOptionPB option) async {
    final result = await _selectOptionService.update(
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _submitTextFieldValue(
    String optionName,
    Emitter<SelectOptionCellEditorState> emit,
  ) {
    final matchingOption = state.options.firstWhereOrNull(
      (option) => option.name.toLowerCase() == optionName.toLowerCase(),
    );

    // if there isn't a matching option at all, then create it
    if (matchingOption == null) {
      _createOption(
        name: optionName,
        color: state.createSelectOptionSuggestion!.color,
      );
    }

    // if there is an unselected matching option, select it
    else if (!state.selectedOptions.contains(matchingOption)) {
      _selectOptionService.select(optionIds: [matchingOption.id]);
    }

    // clear the filter
    emit(state.copyWith(filter: null));
  }

  void _selectMultipleOptions(List<String> optionNames) {
    // The options are unordered. So in order to keep the inserted [optionNames]
    // order, it needs to get the option id in the [optionNames] order.
    final lowerCaseNames = optionNames.map((e) => e.toLowerCase());
    final Map<String, String> optionIdsMap = {};
    for (final option in state.options) {
      optionIdsMap[option.name.toLowerCase()] = option.id;
    }

    final optionIds = lowerCaseNames
        .where((name) => optionIdsMap[name] != null)
        .map((name) => optionIdsMap[name]!)
        .toList();

    _selectOptionService.select(optionIds: optionIds);
  }

  void _filterOption(
    String optionName,
    Emitter<SelectOptionCellEditorState> emit,
  ) {
    final _MakeOptionResult result = _makeOptions(
      optionName,
      state.allOptions,
    );
    emit(
      state.copyWith(
        filter: optionName,
        options: result.options,
        createSelectOptionSuggestion: result.createSelectOptionSuggestion,
      ),
    );
  }

  Future<void> _loadOptions() async {
    final result = await _selectOptionService.getCellData();
    if (isClosed) {
      Log.warn("Unexpecteded closing the bloc");
      return;
    }

    return result.fold(
      (data) => add(
        SelectOptionCellEditorEvent.didReceiveOptions(
          data.options,
          data.selectOptions,
        ),
      ),
      (err) {
        Log.error(err);
        return null;
      },
    );
  }

  _MakeOptionResult _makeOptions(
    String? filter,
    List<SelectOptionPB> allOptions,
  ) {
    final List<SelectOptionPB> options = List.from(allOptions);
    String? newOptionName = filter;

    if (filter != null && filter.isNotEmpty) {
      options.retainWhere((option) {
        final name = option.name.toLowerCase();
        final lFilter = filter.toLowerCase();

        if (name == lFilter) {
          newOptionName = null;
        }

        return name.contains(lFilter);
      });
    } else {
      newOptionName = null;
    }

    return _MakeOptionResult(
      options: options,
      createSelectOptionSuggestion: newOptionName != null
          ? CreateSelectOptionSuggestion(
              name: newOptionName!,
              color: newSelectOptionColor(allOptions),
            )
          : null,
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (selectOptionContext) {
        _loadOptions();
      },
      onCellFieldChanged: (field) {
        _loadOptions();
      },
    );
  }
}

@freezed
class SelectOptionCellEditorEvent with _$SelectOptionCellEditorEvent {
  const factory SelectOptionCellEditorEvent.initial() = _Initial;
  const factory SelectOptionCellEditorEvent.didReceiveOptions(
    List<SelectOptionPB> options,
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
  const factory SelectOptionCellEditorEvent.createOption() = _CreateOption;
  const factory SelectOptionCellEditorEvent.selectOption(String optionId) =
      _SelectOption;
  const factory SelectOptionCellEditorEvent.unSelectOption(String optionId) =
      _UnSelectOption;
  const factory SelectOptionCellEditorEvent.updateOption(
    SelectOptionPB option,
  ) = _UpdateOption;
  const factory SelectOptionCellEditorEvent.deleteOption(
    SelectOptionPB option,
  ) = _DeleteOption;
  const factory SelectOptionCellEditorEvent.deleteAllOptions() =
      _DeleteAllOptions;
  const factory SelectOptionCellEditorEvent.filterOption(String optionName) =
      _SelectOptionFilter;
  const factory SelectOptionCellEditorEvent.submitTextFieldValue(
    String optionName,
  ) = _SubmitTextFieldValue;
  const factory SelectOptionCellEditorEvent.selectMultipleOptions(
    List<String> optionNames,
    String remainder,
  ) = _SelectMultipleOptions;
}

@freezed
class SelectOptionCellEditorState with _$SelectOptionCellEditorState {
  const factory SelectOptionCellEditorState({
    required List<SelectOptionPB> options,
    required List<SelectOptionPB> allOptions,
    required List<SelectOptionPB> selectedOptions,
    required CreateSelectOptionSuggestion? createSelectOptionSuggestion,
    required String? filter,
  }) = _SelectOptionEditorState;

  factory SelectOptionCellEditorState.initial(
    SelectOptionCellController context,
  ) {
    final data = context.getCellData(loadIfNotExist: false);
    return SelectOptionCellEditorState(
      options: data?.options ?? [],
      allOptions: data?.options ?? [],
      selectedOptions: data?.selectOptions ?? [],
      createSelectOptionSuggestion: null,
      filter: null,
    );
  }
}

class _MakeOptionResult {
  _MakeOptionResult({
    required this.options,
    required this.createSelectOptionSuggestion,
  });

  List<SelectOptionPB> options;
  CreateSelectOptionSuggestion? createSelectOptionSuggestion;
}

class CreateSelectOptionSuggestion {
  CreateSelectOptionSuggestion({
    required this.name,
    required this.color,
  });

  final String name;
  final SelectOptionColorPB color;
}
