import 'dart:async';

import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
          initial: () async {
            _startListening();
            add(
              GridHeaderEvent.didReceiveFieldUpdate(fieldController.fields),
            );
          },
          didReceiveFieldUpdate: (fields) {
            final newFields = List<FieldPB>.from(fields);
            newFields.retainWhere(
              (field) => field.visibility != FieldVisibility.AlwaysHidden,
            );
            emit(GridHeaderState(fields: newFields));
          },
          moveField: (FieldPB field, int fromIndex, int toIndex) async {
            await _moveField(field.id, fromIndex, toIndex, emit);
          },
        );
      },
    );
  }

  Future<void> _moveField(
    String fieldId,
    int fromIndex,
    int toIndex,
    Emitter<GridHeaderState> emit,
  ) async {
    final fields = List<FieldPB>.from(state.fields);
    fields.insert(toIndex, fields.removeAt(fromIndex));
    emit(state.copyWith(fields: fields));

    final result = await FieldBackendService.moveField(
      viewId: viewId,
      fieldId: fieldId,
      fromIndex: fromIndex,
      toIndex: toIndex,
    );
    result.fold((l) {}, (err) => Log.error(err));
  }

  Future<void> _startListening() async {
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
  const factory GridHeaderEvent.didReceiveFieldUpdate(List<FieldPB> fields) =
      _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.moveField(
    FieldPB field,
    int fromIndex,
    int toIndex,
  ) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required List<FieldPB> fields}) =
      _GridHeaderState;

  factory GridHeaderState.initial() => const GridHeaderState(fields: []);
}
