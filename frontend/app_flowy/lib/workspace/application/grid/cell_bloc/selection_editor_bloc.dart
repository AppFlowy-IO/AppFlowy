import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
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
  final FieldListener _fieldListener;
  final CellListener _cellListener;
  Timer? _delayOperation;

  SelectOptionEditorBloc({
    required CellData cellData,
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  })  : _selectOptionService = SelectOptionService(),
        _fieldListener = FieldListener(fieldId: cellData.field.id),
        _cellListener = CellListener(rowId: cellData.rowId, fieldId: cellData.field.id),
        super(SelectOptionEditorState.initial(cellData, options, selectedOptions)) {
    on<SelectOptionEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
            _loadOptions();
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
            _makeOptionAsSelected(value.optionId);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _delayOperation?.cancel();
    await _fieldListener.stop();
    await _cellListener.stop();
    return super.close();
  }

  void _createOption(String name) async {
    final result = await _selectOptionService.create(
      gridId: state.gridId,
      fieldId: state.field.id,
      rowId: state.rowId,
      name: name,
    );
    result.fold((l) => _loadOptions(), (err) => Log.error(err));
  }

  void _deleteOption(SelectOption option) async {
    final result = await _selectOptionService.delete(
      gridId: state.gridId,
      fieldId: state.field.id,
      rowId: state.rowId,
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _updateOption(SelectOption option) async {
    final result = await _selectOptionService.update(
      gridId: state.gridId,
      fieldId: state.field.id,
      rowId: state.rowId,
      option: option,
    );

    result.fold((l) => null, (err) => Log.error(err));
  }

  void _makeOptionAsSelected(String optionId) {
    _selectOptionService.select(
      gridId: state.gridId,
      fieldId: state.field.id,
      rowId: state.rowId,
      optionId: optionId,
    );
  }

  void _loadOptions() async {
    _delayOperation?.cancel();
    _delayOperation = Timer(
      const Duration(milliseconds: 1),
      () async {
        final result = await _selectOptionService.getOpitonContext(
          gridId: state.gridId,
          fieldId: state.field.id,
          rowId: state.rowId,
        );

        result.fold(
          (selectOptionContext) {
            if (!isClosed) {
              add(SelectOptionEditorEvent.didReceiveOptions(
                selectOptionContext.options,
                selectOptionContext.selectOptions,
              ));
            }
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  void _startListening() {
    _cellListener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (notificationData) => _loadOptions(),
        (err) => Log.error(err),
      );
    });
    _cellListener.start();

    _fieldListener.updateFieldNotifier.addPublishListener((result) {
      result.fold(
        (field) => add(SelectOptionEditorEvent.didReceiveFieldUpdate(field)),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
  }
}

@freezed
class SelectOptionEditorEvent with _$SelectOptionEditorEvent {
  const factory SelectOptionEditorEvent.initial() = _Initial;
  const factory SelectOptionEditorEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
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
    required String gridId,
    required Field field,
    required String rowId,
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  }) = _SelectOptionEditorState;

  factory SelectOptionEditorState.initial(
    CellData cellData,
    List<SelectOption> options,
    List<SelectOption> selectedOptions,
  ) {
    return SelectOptionEditorState(
      gridId: cellData.gridId,
      field: cellData.field,
      rowId: cellData.rowId,
      options: options,
      selectedOptions: selectedOptions,
    );
  }
}
