import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'selection_editor_bloc.freezed.dart';

class SelectOptionEditorBloc extends Bloc<SelectOptionEditorEvent, SelectOptionEditorState> {
  final TypeOptionService _typeOptionService;
  final CellService _cellService;
  final FieldListener _listener;

  SelectOptionEditorBloc({
    required CellData cellData,
    required List<SelectOption> options,
    required List<SelectOption> selectedOptions,
  })  : _cellService = CellService(),
        _typeOptionService = TypeOptionService(fieldId: cellData.field.id),
        _listener = FieldListener(fieldId: cellData.field.id),
        super(SelectOptionEditorState.initial(cellData, options, selectedOptions)) {
    on<SelectOptionEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
            _loadOptions();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
            _loadOptions();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(options: value.options));
          },
          newOption: (_NewOption value) async {
            final result = await _typeOptionService.createOption(value.optionName, selected: true);
            result.fold((l) => null, (err) => Log.error(err));
          },
          selectOption: (_SelectOption value) {
            _cellService.addSelectOpiton(
              gridId: state.gridId,
              fieldId: state.field.id,
              rowId: state.rowId,
              optionId: value.optionId,
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _startListening() {
    _listener.updateFieldNotifier.addPublishListener((result) {
      result.fold(
        (field) => add(SelectOptionEditorEvent.didReceiveFieldUpdate(field)),
        (err) => Log.error(err),
      );
    });
  }

  void _loadOptions() async {
    final result = await FieldContextLoaderAdaptor(gridId: state.gridId, field: state.field).load();
    result.fold(
      (context) {
        List<SelectOption> options = [];
        switch (state.field.fieldType) {
          case FieldType.MultiSelect:
            options.addAll(MultiSelectTypeOption.fromBuffer(context.typeOptionData).options);
            break;
          case FieldType.SingleSelect:
            options.addAll(SingleSelectTypeOption.fromBuffer(context.typeOptionData).options);
            break;
          default:
            Log.error("Invalid field type, expect single select or multiple select");
            break;
        }
        add(SelectOptionEditorEvent.didReceiveOptions(options));
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class SelectOptionEditorEvent with _$SelectOptionEditorEvent {
  const factory SelectOptionEditorEvent.initial() = _Initial;
  const factory SelectOptionEditorEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
  const factory SelectOptionEditorEvent.didReceiveOptions(List<SelectOption> options) = _DidReceiveOptions;
  const factory SelectOptionEditorEvent.newOption(String optionName) = _NewOption;
  const factory SelectOptionEditorEvent.selectOption(String optionId) = _SelectOption;
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
