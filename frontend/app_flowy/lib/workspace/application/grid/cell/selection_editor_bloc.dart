import 'package:app_flowy/workspace/application/grid/cell/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/cell/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'select_option_service.dart';

part 'selection_editor_bloc.freezed.dart';

class SelectOptionEditorBloc extends Bloc<SelectOptionEditorEvent, SelectOptionEditorState> {
  final SelectOptionService _selectOptionService;
  final GridCellContext<SelectOptionContext> cellContext;
  Timer? _delayOperation;

  SelectOptionEditorBloc({
    required this.cellContext,
  })  : _selectOptionService = SelectOptionService(gridCell: cellContext.gridCell),
        super(SelectOptionEditorState.initial(cellContext)) {
    on<SelectOptionEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(
              options: value.options,
              selectedOptions: value.selectedOptions,
            ));
          },
          newOption: (_NewOption value) {
            _createOption(value.optionName);
          },
          deleteOption: (_DeleteOption value) {
            _deleteOption(value.option);
          },
          updateOption: (_UpdateOption value) {
            _updateOption(value.option);
          },
          selectOption: (_SelectOption value) {
            _onSelectOption(value.optionId);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _delayOperation?.cancel();
    cellContext.removeListener();
    return super.close();
  }

  void _createOption(String name) async {
    final result = await _selectOptionService.create(name: name);
    result.fold((l) => {}, (err) => Log.error(err));
  }

  void _deleteOption(SelectOption option) async {
    final result = await _selectOptionService.delete(
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _updateOption(SelectOption option) async {
    final result = await _selectOptionService.update(
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _onSelectOption(String optionId) {
    final hasSelected = state.selectedOptions.firstWhereOrNull((option) => option.id == optionId);
    if (hasSelected != null) {
      _selectOptionService.unSelect(optionId: optionId);
    } else {
      _selectOptionService.select(optionId: optionId);
    }
  }

  // void _loadOptions() async {
  //   _delayOperation?.cancel();
  //   _delayOperation = Timer(
  //     const Duration(milliseconds: 1),
  //     () async {
  //       final result = await _selectOptionService.getOpitonContext();
  //       if (isClosed) {
  //         return;
  //       }

  //       result.fold(
  //         (selectOptionContext) => add(SelectOptionEditorEvent.didReceiveOptions(
  //           selectOptionContext.options,
  //           selectOptionContext.selectOptions,
  //         )),
  //         (err) => Log.error(err),
  //       );
  //     },
  //   );
  // }

  void _startListening() {
    cellContext.onCellChanged((selectOptionContext) {
      if (!isClosed) {
        add(SelectOptionEditorEvent.didReceiveOptions(
          selectOptionContext.options,
          selectOptionContext.selectOptions,
        ));
      }
    });

    cellContext.onFieldChanged(() => cellContext.reloadCellData());
  }
}

@freezed
class SelectOptionEditorEvent with _$SelectOptionEditorEvent {
  const factory SelectOptionEditorEvent.initial() = _Initial;
  const factory SelectOptionEditorEvent.didReceiveOptions(
      List<SelectOption> options, List<SelectOption> selectedOptions) = _DidReceiveOptions;
  const factory SelectOptionEditorEvent.newOption(String optionName) = _NewOption;
  const factory SelectOptionEditorEvent.selectOption(String optionId) = _SelectOption;
  const factory SelectOptionEditorEvent.updateOption(SelectOption option) = _UpdateOption;
  const factory SelectOptionEditorEvent.deleteOption(SelectOption option) = _DeleteOption;
}

@freezed
class SelectOptionEditorState with _$SelectOptionEditorState {
  const factory SelectOptionEditorState({
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  }) = _SelectOptionEditorState;

  factory SelectOptionEditorState.initial(GridCellContext<SelectOptionContext> context) {
    final data = context.getCellData();
    return SelectOptionEditorState(
      options: data?.options ?? [],
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
