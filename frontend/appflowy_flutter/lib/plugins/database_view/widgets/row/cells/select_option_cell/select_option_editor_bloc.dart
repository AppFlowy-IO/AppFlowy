import 'dart:async';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../application/cell/select_option_cell_service.dart';

part 'select_option_editor_bloc.freezed.dart';

class SelectOptionCellEditorBloc
    extends Bloc<SelectOptionEditorEvent, SelectOptionEditorState> {
  final SelectOptionCellBackendService _selectOptionService;
  final SelectOptionCellController cellController;

  SelectOptionCellEditorBloc({
    required this.cellController,
  })  : _selectOptionService = SelectOptionCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(SelectOptionEditorState.initial(cellController)) {
    on<SelectOptionEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
            await _loadOptions();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            final result = _makeOptions(state.filter, value.options);
            emit(
              state.copyWith(
                allOptions: value.options,
                options: result.options,
                createOption: result.createOption,
                selectedOptions: value.selectedOptions,
              ),
            );
          },
          newOption: (_NewOption value) async {
            await _createOption(value.optionName);
            emit(
              state.copyWith(
                filter: none(),
              ),
            );
          },
          deleteOption: (_DeleteOption value) async {
            await _deleteOption([value.option]);
          },
          deleteAllOptions: (_DeleteAllOptions value) async {
            if (state.allOptions.isNotEmpty) {
              await _deleteOption(state.allOptions);
            }
          },
          updateOption: (_UpdateOption value) async {
            await _updateOption(value.option);
          },
          selectOption: (_SelectOption value) async {
            await _selectOptionService.select(optionIds: [value.optionId]);
            final selectedOption = [
              ...state.selectedOptions,
              state.options.firstWhere(
                (element) => element.id == value.optionId,
              ),
            ];
            emit(
              state.copyWith(
                selectedOptions: selectedOption,
              ),
            );
          },
          unSelectOption: (_UnSelectOption value) async {
            await _selectOptionService.unSelect(optionIds: [value.optionId]);
            final selectedOptions = [...state.selectedOptions]
              ..removeWhere((e) => e.id == value.optionId);
            emit(
              state.copyWith(
                selectedOptions: selectedOptions,
              ),
            );
          },
          trySelectOption: (_TrySelectOption value) {
            _trySelectOption(value.optionName, emit);
          },
          selectMultipleOptions: (_SelectMultipleOptions value) {
            if (value.optionNames.isNotEmpty) {
              _selectMultipleOptions(value.optionNames);
            }
            _filterOption(value.remainder, emit);
          },
          filterOption: (_SelectOptionFilter value) {
            _filterOption(value.optionName, emit);
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
    final result = await _selectOptionService.create(name: name);
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

  void _trySelectOption(
    String optionName,
    Emitter<SelectOptionEditorState> emit,
  ) {
    SelectOptionPB? matchingOption;
    bool optionExistsButSelected = false;

    for (final option in state.options) {
      if (option.name.toLowerCase() == optionName.toLowerCase()) {
        if (!state.selectedOptions.contains(option)) {
          matchingOption = option;
          break;
        } else {
          optionExistsButSelected = true;
        }
      }
    }

    // if there isn't a matching option at all, then create it
    if (matchingOption == null && !optionExistsButSelected) {
      _createOption(optionName);
    }

    // if there is an unselected matching option, select it
    if (matchingOption != null) {
      _selectOptionService.select(optionIds: [matchingOption.id]);
    }

    // clear the filter
    emit(state.copyWith(filter: none()));
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

  void _filterOption(String optionName, Emitter<SelectOptionEditorState> emit) {
    final _MakeOptionResult result = _makeOptions(
      Some(optionName),
      state.allOptions,
    );
    emit(
      state.copyWith(
        filter: Some(optionName),
        options: result.options,
        createOption: result.createOption,
      ),
    );
  }

  Future<void> _loadOptions() async {
    final result = await _selectOptionService.getCellData();
    if (isClosed) {
      Log.warn("Unexpected closing the bloc");
      return;
    }

    return result.fold(
      (data) => add(
        SelectOptionEditorEvent.didReceiveOptions(
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
    Option<String> filter,
    List<SelectOptionPB> allOptions,
  ) {
    final List<SelectOptionPB> options = List.from(allOptions);
    Option<String> createOption = filter;

    filter.foldRight(null, (filter, previous) {
      if (filter.isNotEmpty) {
        options.retainWhere((option) {
          final name = option.name.toLowerCase();
          final lFilter = filter.toLowerCase();

          if (name == lFilter) {
            createOption = none();
          }

          return name.contains(lFilter);
        });
      } else {
        createOption = none();
      }
    });

    return _MakeOptionResult(
      options: options,
      createOption: createOption,
    );
  }

  void _startListening() {
    cellController.startListening(
      onCellChanged: ((selectOptionContext) {
        _loadOptions();
      }),
      onCellFieldChanged: () {
        _loadOptions();
      },
    );
  }
}

@freezed
class SelectOptionEditorEvent with _$SelectOptionEditorEvent {
  const factory SelectOptionEditorEvent.initial() = _Initial;
  const factory SelectOptionEditorEvent.didReceiveOptions(
    List<SelectOptionPB> options,
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
  const factory SelectOptionEditorEvent.newOption(String optionName) =
      _NewOption;
  const factory SelectOptionEditorEvent.selectOption(String optionId) =
      _SelectOption;
  const factory SelectOptionEditorEvent.unSelectOption(String optionId) =
      _UnSelectOption;
  const factory SelectOptionEditorEvent.updateOption(SelectOptionPB option) =
      _UpdateOption;
  const factory SelectOptionEditorEvent.deleteOption(SelectOptionPB option) =
      _DeleteOption;
  const factory SelectOptionEditorEvent.deleteAllOptions() = _DeleteAllOptions;
  const factory SelectOptionEditorEvent.filterOption(String optionName) =
      _SelectOptionFilter;
  const factory SelectOptionEditorEvent.trySelectOption(String optionName) =
      _TrySelectOption;
  const factory SelectOptionEditorEvent.selectMultipleOptions(
    List<String> optionNames,
    String remainder,
  ) = _SelectMultipleOptions;
}

@freezed
class SelectOptionEditorState with _$SelectOptionEditorState {
  const factory SelectOptionEditorState({
    required List<SelectOptionPB> options,
    required List<SelectOptionPB> allOptions,
    required List<SelectOptionPB> selectedOptions,
    required Option<String> createOption,
    required Option<String> filter,
  }) = _SelectOptionEditorState;

  factory SelectOptionEditorState.initial(SelectOptionCellController context) {
    final data = context.getCellData(loadIfNotExist: false);
    return SelectOptionEditorState(
      options: data?.options ?? [],
      allOptions: data?.options ?? [],
      selectedOptions: data?.selectOptions ?? [],
      createOption: none(),
      filter: none(),
    );
  }
}

class _MakeOptionResult {
  List<SelectOptionPB> options;
  Option<String> createOption;

  _MakeOptionResult({
    required this.options,
    required this.createOption,
  });
}
