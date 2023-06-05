import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'select_option_service.dart';

part 'select_option_editor_bloc.freezed.dart';

class SelectOptionCellEditorBloc
    extends Bloc<SelectOptionEditorEvent, SelectOptionEditorState> {
  final SelectOptionBackendService _selectOptionService;
  final SelectOptionCellController cellController;

  SelectOptionCellEditorBloc({
    required this.cellController,
  })  : _selectOptionService =
            SelectOptionBackendService(cellId: cellController.cellId),
        super(SelectOptionEditorState.initial(cellController)) {
    on<SelectOptionEditorEvent>(
      (final event, final emit) async {
        await event.map(
          initial: (final _Initial value) async {
            _startListening();
            await _loadOptions();
          },
          didReceiveOptions: (final _DidReceiveOptions value) {
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
          newOption: (final _NewOption value) async {
            await _createOption(value.optionName);
            emit(
              state.copyWith(
                filter: none(),
              ),
            );
          },
          deleteOption: (final _DeleteOption value) async {
            await _deleteOption([value.option]);
          },
          deleteAllOptions: (final _DeleteAllOptions value) async {
            if (state.allOptions.isNotEmpty) {
              await _deleteOption(state.allOptions);
            }
          },
          updateOption: (final _UpdateOption value) async {
            await _updateOption(value.option);
          },
          selectOption: (final _SelectOption value) async {
            await _selectOptionService.select(optionIds: [value.optionId]);
          },
          unSelectOption: (final _UnSelectOption value) async {
            await _selectOptionService.unSelect(optionIds: [value.optionId]);
          },
          trySelectOption: (final _TrySelectOption value) {
            _trySelectOption(value.optionName, emit);
          },
          selectMultipleOptions: (final _SelectMultipleOptions value) {
            if (value.optionNames.isNotEmpty) {
              _selectMultipleOptions(value.optionNames);
            }
            _filterOption(value.remainder, emit);
          },
          filterOption: (final _SelectOptionFilter value) {
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

  Future<void> _createOption(final String name) async {
    final result = await _selectOptionService.create(name: name);
    result.fold((final l) => {}, (final err) => Log.error(err));
  }

  Future<void> _deleteOption(final List<SelectOptionPB> options) async {
    final result = await _selectOptionService.delete(options: options);
    result.fold((final l) => null, (final err) => Log.error(err));
  }

  Future<void> _updateOption(final SelectOptionPB option) async {
    final result = await _selectOptionService.update(
      option: option,
    );

    result.fold((final l) => null, (final err) => Log.error(err));
  }

  void _trySelectOption(
    final String optionName,
    final Emitter<SelectOptionEditorState> emit,
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

  void _selectMultipleOptions(final List<String> optionNames) {
    // The options are unordered. So in order to keep the inserted [optionNames]
    // order, it needs to get the option id in the [optionNames] order.
    final lowerCaseNames = optionNames.map((final e) => e.toLowerCase());
    final Map<String, String> optionIdsMap = {};
    for (final option in state.options) {
      optionIdsMap[option.name.toLowerCase()] = option.id;
    }

    final optionIds = lowerCaseNames
        .where((final name) => optionIdsMap[name] != null)
        .map((final name) => optionIdsMap[name]!)
        .toList();

    _selectOptionService.select(optionIds: optionIds);
  }

  void _filterOption(final String optionName, final Emitter<SelectOptionEditorState> emit) {
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
      (final data) => add(
        SelectOptionEditorEvent.didReceiveOptions(
          data.options,
          data.selectOptions,
        ),
      ),
      (final err) {
        Log.error(err);
        return null;
      },
    );
  }

  _MakeOptionResult _makeOptions(
    final Option<String> filter,
    final List<SelectOptionPB> allOptions,
  ) {
    final List<SelectOptionPB> options = List.from(allOptions);
    Option<String> createOption = filter;

    filter.foldRight(null, (final filter, final previous) {
      if (filter.isNotEmpty) {
        options.retainWhere((final option) {
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
      onCellChanged: ((final selectOptionContext) {
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
    final List<SelectOptionPB> options,
    final List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
  const factory SelectOptionEditorEvent.newOption(final String optionName) =
      _NewOption;
  const factory SelectOptionEditorEvent.selectOption(final String optionId) =
      _SelectOption;
  const factory SelectOptionEditorEvent.unSelectOption(final String optionId) =
      _UnSelectOption;
  const factory SelectOptionEditorEvent.updateOption(final SelectOptionPB option) =
      _UpdateOption;
  const factory SelectOptionEditorEvent.deleteOption(final SelectOptionPB option) =
      _DeleteOption;
  const factory SelectOptionEditorEvent.deleteAllOptions() = _DeleteAllOptions;
  const factory SelectOptionEditorEvent.filterOption(final String optionName) =
      _SelectOptionFilter;
  const factory SelectOptionEditorEvent.trySelectOption(final String optionName) =
      _TrySelectOption;
  const factory SelectOptionEditorEvent.selectMultipleOptions(
    final List<String> optionNames,
    final String remainder,
  ) = _SelectMultipleOptions;
}

@freezed
class SelectOptionEditorState with _$SelectOptionEditorState {
  const factory SelectOptionEditorState({
    required final List<SelectOptionPB> options,
    required final List<SelectOptionPB> allOptions,
    required final List<SelectOptionPB> selectedOptions,
    required final Option<String> createOption,
    required final Option<String> filter,
  }) = _SelectOptionEditorState;

  factory SelectOptionEditorState.initial(final SelectOptionCellController context) {
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
