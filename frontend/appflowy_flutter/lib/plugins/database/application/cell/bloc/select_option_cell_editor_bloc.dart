import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/type_option/select_type_option_actions.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/select_option_cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_cell_editor_bloc.freezed.dart';

const String createSelectOptionSuggestionId =
    "create_select_option_suggestion_id";

class SelectOptionCellEditorBloc
    extends Bloc<SelectOptionCellEditorEvent, SelectOptionCellEditorState> {
  SelectOptionCellEditorBloc({required this.cellController})
      : _selectOptionService = SelectOptionCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        _typeOptionAction = cellController.fieldType == FieldType.SingleSelect
            ? SingleSelectAction(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                onTypeOptionUpdated: (typeOptionData) =>
                    FieldBackendService.updateFieldTypeOption(
                  viewId: cellController.viewId,
                  fieldId: cellController.fieldId,
                  typeOptionData: typeOptionData,
                ),
              )
            : MultiSelectAction(
                viewId: cellController.viewId,
                fieldId: cellController.fieldId,
                onTypeOptionUpdated: (typeOptionData) =>
                    FieldBackendService.updateFieldTypeOption(
                  viewId: cellController.viewId,
                  fieldId: cellController.fieldId,
                  typeOptionData: typeOptionData,
                ),
              ),
        super(SelectOptionCellEditorState.initial(cellController)) {
    _dispatch();
    _startListening();
    _loadOptions();
  }

  final SelectOptionCellBackendService _selectOptionService;
  final ISelectOptionAction _typeOptionAction;
  final SelectOptionCellController cellController;

  VoidCallback? _onCellChangedFn;

  final List<SelectOptionPB> allOptions = [];
  String filter = "";

  void _dispatch() {
    on<SelectOptionCellEditorEvent>(
      (event, emit) async {
        await event.when(
          didReceiveOptions: (options, selectedOptions) {
            final result = _getVisibleOptions(options);
            allOptions
              ..clear()
              ..addAll(options);
            emit(
              state.copyWith(
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
            filter = "";
            await _createOption(
              name: state.createSelectOptionSuggestion!.name,
              color: state.createSelectOptionSuggestion!.color,
            );
            emit(state.copyWith(clearFilter: true));
          },
          deleteOption: (option) async {
            await _deleteOption([option]);
          },
          deleteAllOptions: () async {
            if (allOptions.isNotEmpty) {
              await _deleteOption(allOptions);
            }
          },
          updateOption: (option) async {
            await _updateOption(option);
          },
          selectOption: (optionId) async {
            await _selectOptionService.select(optionIds: [optionId]);
          },
          unSelectOption: (optionId) async {
            await _selectOptionService.unSelect(optionIds: [optionId]);
          },
          unSelectLastOption: () async {
            if (state.selectedOptions.isEmpty) {
              return;
            }
            final lastSelectedOptionId = state.selectedOptions.last.id;
            await _selectOptionService
                .unSelect(optionIds: [lastSelectedOptionId]);
          },
          submitTextField: () {
            _submitTextFieldValue(emit);
          },
          selectMultipleOptions: (optionNames, remainder) {
            if (optionNames.isNotEmpty) {
              _selectMultipleOptions(optionNames);
            }
            _filterOption(remainder, emit);
          },
          reorderOption: (fromOptionId, toOptionId) {
            final options = _typeOptionAction.reorderOption(
              allOptions,
              fromOptionId,
              toOptionId,
            );
            allOptions
              ..clear()
              ..addAll(options);
            final result = _getVisibleOptions(options);
            emit(state.copyWith(options: result.options));
          },
          filterOption: (filterText) {
            _filterOption(filterText, emit);
          },
          focusPreviousOption: () {
            _focusOption(true, emit);
          },
          focusNextOption: () {
            _focusOption(false, emit);
          },
          updateFocusedOption: (optionId) {
            emit(state.copyWith(focusedOptionId: optionId));
          },
          resetClearFilterFlag: () {
            emit(state.copyWith(clearFilter: false));
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

  void _submitTextFieldValue(Emitter<SelectOptionCellEditorState> emit) {
    if (state.focusedOptionId == null) {
      return;
    }

    final focusedOptionId = state.focusedOptionId!;

    if (focusedOptionId == createSelectOptionSuggestionId) {
      filter = "";
      _createOption(
        name: state.createSelectOptionSuggestion!.name,
        color: state.createSelectOptionSuggestion!.color,
      );
      emit(
        state.copyWith(
          createSelectOptionSuggestion: null,
          clearFilter: true,
        ),
      );
    } else if (!state.selectedOptions
        .any((option) => option.id == focusedOptionId)) {
      _selectOptionService.select(optionIds: [focusedOptionId]);
    }
  }

  void _selectMultipleOptions(List<String> optionNames) {
    final optionIds = optionNames
        .map(
          (name) => allOptions.firstWhereOrNull(
            (option) => option.name.toLowerCase() == name.toLowerCase(),
          ),
        )
        .nonNulls
        .map((option) => option.id)
        .toList();

    _selectOptionService.select(optionIds: optionIds);
  }

  void _filterOption(
    String filterText,
    Emitter<SelectOptionCellEditorState> emit,
  ) {
    filter = filterText;
    final _MakeOptionResult result = _getVisibleOptions(
      allOptions,
    );
    final focusedOptionId = result.options.isEmpty
        ? result.createSelectOptionSuggestion == null
            ? null
            : createSelectOptionSuggestionId
        : result.options.any((option) => option.id == state.focusedOptionId)
            ? state.focusedOptionId
            : result.options.first.id;
    emit(
      state.copyWith(
        options: result.options,
        createSelectOptionSuggestion: result.createSelectOptionSuggestion,
        focusedOptionId: focusedOptionId,
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

  _MakeOptionResult _getVisibleOptions(
    List<SelectOptionPB> allOptions,
  ) {
    final List<SelectOptionPB> options = List.from(allOptions);
    String newOptionName = filter;

    if (filter.isNotEmpty) {
      options.retainWhere((option) {
        final name = option.name.toLowerCase();
        final lFilter = filter.toLowerCase();

        if (name == lFilter) {
          newOptionName = "";
        }

        return name.contains(lFilter);
      });
    }

    return _MakeOptionResult(
      options: options,
      createSelectOptionSuggestion: newOptionName.isEmpty
          ? null
          : CreateSelectOptionSuggestion(
              name: newOptionName,
              color: newSelectOptionColor(allOptions),
            ),
    );
  }

  void _focusOption(bool previous, Emitter<SelectOptionCellEditorState> emit) {
    if (state.options.isEmpty && state.createSelectOptionSuggestion == null) {
      return;
    }

    final optionIds = [
      ...state.options.map((e) => e.id),
      if (state.createSelectOptionSuggestion != null)
        createSelectOptionSuggestionId,
    ];

    if (state.focusedOptionId == null) {
      emit(
        state.copyWith(
          focusedOptionId: previous ? optionIds.last : optionIds.first,
        ),
      );
      return;
    }

    final currentIndex =
        optionIds.indexWhere((id) => id == state.focusedOptionId);

    final newIndex = currentIndex == -1
        ? 0
        : (currentIndex + (previous ? -1 : 1)) % optionIds.length;

    emit(state.copyWith(focusedOptionId: optionIds[newIndex]));
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
  const factory SelectOptionCellEditorEvent.didReceiveOptions(
    List<SelectOptionPB> options,
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
  const factory SelectOptionCellEditorEvent.createOption() = _CreateOption;
  const factory SelectOptionCellEditorEvent.selectOption(String optionId) =
      _SelectOption;
  const factory SelectOptionCellEditorEvent.unSelectOption(String optionId) =
      _UnSelectOption;
  const factory SelectOptionCellEditorEvent.unSelectLastOption() =
      _UnSelectLastOption;
  const factory SelectOptionCellEditorEvent.updateOption(
    SelectOptionPB option,
  ) = _UpdateOption;
  const factory SelectOptionCellEditorEvent.deleteOption(
    SelectOptionPB option,
  ) = _DeleteOption;
  const factory SelectOptionCellEditorEvent.deleteAllOptions() =
      _DeleteAllOptions;
  const factory SelectOptionCellEditorEvent.reorderOption(
    String fromOptionId,
    String toOptionId,
  ) = _ReorderOption;
  const factory SelectOptionCellEditorEvent.filterOption(String filterText) =
      _SelectOptionFilter;
  const factory SelectOptionCellEditorEvent.submitTextField() =
      _SubmitTextField;
  const factory SelectOptionCellEditorEvent.selectMultipleOptions(
    List<String> optionNames,
    String remainder,
  ) = _SelectMultipleOptions;
  const factory SelectOptionCellEditorEvent.focusPreviousOption() =
      _FocusPreviousOption;
  const factory SelectOptionCellEditorEvent.focusNextOption() =
      _FocusNextOption;
  const factory SelectOptionCellEditorEvent.updateFocusedOption(
    String? optionId,
  ) = _UpdateFocusedOption;
  const factory SelectOptionCellEditorEvent.resetClearFilterFlag() =
      _ResetClearFilterFlag;
}

@freezed
class SelectOptionCellEditorState with _$SelectOptionCellEditorState {
  const factory SelectOptionCellEditorState({
    required List<SelectOptionPB> options,
    required List<SelectOptionPB> selectedOptions,
    required CreateSelectOptionSuggestion? createSelectOptionSuggestion,
    required String? focusedOptionId,
    required bool clearFilter,
  }) = _SelectOptionEditorState;

  factory SelectOptionCellEditorState.initial(
    SelectOptionCellController context,
  ) {
    final data = context.getCellData(loadIfNotExist: false);
    return SelectOptionCellEditorState(
      options: data?.options ?? [],
      selectedOptions: data?.selectOptions ?? [],
      createSelectOptionSuggestion: null,
      focusedOptionId: null,
      clearFilter: false,
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
