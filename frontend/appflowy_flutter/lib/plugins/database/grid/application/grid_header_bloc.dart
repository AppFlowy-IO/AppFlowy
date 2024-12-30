import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/field_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  GridHeaderBloc({required this.viewId, required this.fieldController})
      : super(GridHeaderState.initial()) {
    _dispatch();
  }

  final String viewId;
  final FieldController fieldController;

  @override
  Future<void> close() async {
    fieldController.removeListener(onFieldsListener: _onReceiveFields);
    await super.close();
  }

  void _dispatch() {
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
          moveField: (fromIndex, toIndex) async {
            await _moveField(fromIndex, toIndex, emit);
          },
        );
      },
    );
  }

  Future<void> _moveField(
    int fromIndex,
    int toIndex,
    Emitter<GridHeaderState> emit,
  ) async {
    final fromId = state.fields[fromIndex].id;
    final toId = state.fields[toIndex].id;

    final fields = List<FieldInfo>.from(state.fields);
    fields.insert(toIndex, fields.removeAt(fromIndex));
    emit(state.copyWith(fields: fields));

    final result = await FieldBackendService.moveField(
      viewId: viewId,
      fromFieldId: fromId,
      toFieldId: toId,
    );
    result.fold((l) {}, (err) => Log.error(err));
  }

  void _startListening() {
    fieldController.addListener(
      onReceiveFields: _onReceiveFields,
      listenWhen: () => !isClosed,
    );
  }

  void _onReceiveFields(List<FieldInfo> fields) =>
      add(GridHeaderEvent.didReceiveFieldUpdate(fields));
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
