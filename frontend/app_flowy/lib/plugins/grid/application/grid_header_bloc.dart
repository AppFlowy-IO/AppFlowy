import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'grid_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final GridFieldCache fieldCache;
  final String gridId;

  GridHeaderBloc({
    required this.gridId,
    required this.fieldCache,
  }) : super(GridHeaderState.initial(fieldCache.fields)) {
    on<GridHeaderEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialHeader value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
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
    final fields = List<GridFieldPB>.from(state.fields);
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
    fieldCache.addListener(
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
  const factory GridHeaderEvent.didReceiveFieldUpdate(
      List<GridFieldPB> fields) = _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.moveField(
      GridFieldPB field, int fromIndex, int toIndex) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required List<GridFieldPB> fields}) =
      _GridHeaderState;

  factory GridHeaderState.initial(List<GridFieldPB> fields) {
    // final List<GridFieldPB> newFields = List.from(fields);
    // newFields.retainWhere((field) => field.visibility);
    return GridHeaderState(fields: fields);
  }
}
