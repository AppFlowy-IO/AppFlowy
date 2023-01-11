import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field/field_controller.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final GridFieldController fieldController;
  final String gridId;

  GridHeaderBloc({
    required this.gridId,
    required this.fieldController,
  }) : super(GridHeaderState.initial(fieldController.fieldInfos)) {
    on<GridHeaderEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialHeader value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(
              state.copyWith(
                fields: value.fields
                    .where((element) => element.visibility)
                    .toList(),
              ),
            );
          },
          moveField: (_MoveField value) async {
            await _moveField(value, emit);
          },
        );
      },
    );
  }

  Future<void> _moveField(
      _MoveField value, Emitter<GridHeaderState> emit) async {
    final fields = List<FieldInfo>.from(state.fields);
    fields.insert(value.toIndex, fields.removeAt(value.fromIndex));
    emit(state.copyWith(fields: fields));

    final fieldService = FieldService(gridId: gridId, fieldId: value.field.id);
    final result = await fieldService.moveField(
      value.fromIndex,
      value.toIndex,
    );
    result.fold((l) {}, (err) => Log.error(err));
  }

  Future<void> _startListening() async {
    fieldController.addListener(
      onFields: (fields) => add(GridHeaderEvent.didReceiveFieldUpdate(fields)),
      listenWhen: () => !isClosed,
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
  const factory GridHeaderEvent.didReceiveFieldUpdate(List<FieldInfo> fields) =
      _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.moveField(
      FieldPB field, int fromIndex, int toIndex) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required List<FieldInfo> fields}) =
      _GridHeaderState;

  factory GridHeaderState.initial(List<FieldInfo> fields) {
    // final List<FieldPB> newFields = List.from(fields);
    // newFields.retainWhere((field) => field.visibility);
    return GridHeaderState(fields: fields);
  }
}
