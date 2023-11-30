import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../application/field/field_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final FieldController fieldController;
  final String viewId;

  GridHeaderBloc({
    required this.viewId,
    required this.fieldController,
  }) : super(GridHeaderState.initial()) {
    on<GridHeaderEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
            add(
              GridHeaderEvent.didReceiveFieldUpdate(fieldController.fieldInfos),
            );
          },
          didReceiveFieldUpdate: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                fields: fields
                    .where(
                      (element) =>
                          element.visibility != null &&
                          element.visibility != FieldVisibility.AlwaysHidden,
                    )
                    .toList(),
              ),
            );
          },
          startEditingField: (fieldId) {
            emit(state.copyWith(editingFieldId: fieldId));
          },
          startEditingNewField: (fieldId) {
            emit(state.copyWith(editingFieldId: fieldId, newFieldId: fieldId));
          },
          endEditingField: () {
            emit(state.copyWith(editingFieldId: null, newFieldId: null));
          },
          moveField: (field, fromIndex, toIndex) async {
            await _moveField(field, fromIndex, toIndex, emit);
          },
        );
      },
    );
  }

  Future<void> _moveField(
    FieldPB field,
    int fromIndex,
    int toIndex,
    Emitter<GridHeaderState> emit,
  ) async {
    final fields = List<FieldInfo>.from(state.fields);
    fields.insert(toIndex, fields.removeAt(fromIndex));
    emit(state.copyWith(fields: fields));

    final fieldService = FieldBackendService(viewId: viewId, fieldId: field.id);
    final result = await fieldService.moveField(fromIndex, toIndex);
    result.fold((l) {}, (err) => Log.error(err));
  }

  void _startListening() {
    fieldController.addListener(
      onReceiveFields: (fields) =>
          add(GridHeaderEvent.didReceiveFieldUpdate(fields)),
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
  const factory GridHeaderEvent.didReceiveFieldUpdate(List<FieldInfo> fields) =
      _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.startEditingField(String fieldId) =
      _StartEditingField;
  const factory GridHeaderEvent.startEditingNewField(String fieldId) =
      _StartEditingNewField;
  const factory GridHeaderEvent.endEditingField() = _EndEditingField;
  const factory GridHeaderEvent.moveField(
    FieldPB field,
    int fromIndex,
    int toIndex,
  ) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({
    required List<FieldInfo> fields,
    required String? editingFieldId,
    required String? newFieldId,
  }) = _GridHeaderState;

  factory GridHeaderState.initial() =>
      const GridHeaderState(fields: [], editingFieldId: null, newFieldId: null);
}
