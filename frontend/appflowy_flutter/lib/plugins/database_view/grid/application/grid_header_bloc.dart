import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
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
  }) : super(GridHeaderState.initial(fieldController.fieldInfos)) {
    on<GridHeaderEvent>(
      (final event, final emit) async {
        await event.map(
          initial: (final _InitialHeader value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (final _DidReceiveFieldUpdate value) {
            emit(
              state.copyWith(
                fields: value.fields
                    .where((final element) => element.visibility)
                    .toList(),
              ),
            );
          },
          moveField: (final _MoveField value) async {
            await _moveField(value, emit);
          },
        );
      },
    );
  }

  Future<void> _moveField(
    final _MoveField value,
    final Emitter<GridHeaderState> emit,
  ) async {
    final fields = List<FieldInfo>.from(state.fields);
    fields.insert(value.toIndex, fields.removeAt(value.fromIndex));
    emit(state.copyWith(fields: fields));

    final fieldService =
        FieldBackendService(viewId: viewId, fieldId: value.field.id);
    final result = await fieldService.moveField(
      value.fromIndex,
      value.toIndex,
    );
    result.fold((final l) {}, (final err) => Log.error(err));
  }

  Future<void> _startListening() async {
    fieldController.addListener(
      onReceiveFields: (final fields) =>
          add(GridHeaderEvent.didReceiveFieldUpdate(fields)),
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
  const factory GridHeaderEvent.didReceiveFieldUpdate(final List<FieldInfo> fields) =
      _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.moveField(
    final FieldPB field,
    final int fromIndex,
    final int toIndex,
  ) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required final List<FieldInfo> fields}) =
      _GridHeaderState;

  factory GridHeaderState.initial(final List<FieldInfo> fields) {
    // final List<FieldPB> newFields = List.from(fields);
    // newFields.retainWhere((field) => field.visibility);
    return GridHeaderState(fields: fields);
  }
}
