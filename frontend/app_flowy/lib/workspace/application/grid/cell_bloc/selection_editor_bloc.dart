import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'selection_editor_bloc.freezed.dart';

class SelectionEditorBloc extends Bloc<SelectionEditorEvent, SelectionEditorState> {
  final CellService service = CellService();
  final FieldListener _listener;

  SelectionEditorBloc({
    required String gridId,
    required Field field,
  })  : _listener = FieldListener(fieldId: field.id),
        super(SelectionEditorState.initial(gridId, field)) {
    on<SelectionEditorEvent>(
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
        (field) => add(SelectionEditorEvent.didReceiveFieldUpdate(field)),
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
        add(SelectionEditorEvent.didReceiveOptions(options));
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class SelectionEditorEvent with _$SelectionEditorEvent {
  const factory SelectionEditorEvent.initial() = _Initial;
  const factory SelectionEditorEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
  const factory SelectionEditorEvent.didReceiveOptions(List<SelectOption> options) = _DidReceiveOptions;
}

@freezed
class SelectionEditorState with _$SelectionEditorState {
  const factory SelectionEditorState({
    required String gridId,
    required Field field,
    required List<SelectOption> options,
  }) = _SelectionEditorState;

  factory SelectionEditorState.initial(String gridId, Field field) {
    return SelectionEditorState(
      gridId: gridId,
      field: field,
      options: [],
    );
  }
}
