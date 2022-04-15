import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'grid_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final FieldService _fieldService;
  final GridFieldCache fieldCache;

  GridHeaderBloc({
    required String gridId,
    required this.fieldCache,
  })  : _fieldService = FieldService(gridId: gridId),
        super(GridHeaderState.initial(fieldCache.clonedFields)) {
    on<GridHeaderEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialHeader value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
          },
          moveField: (_MoveField value) {},
        );
      },
    );
  }

  Future<void> _startListening() async {
    fieldCache.addListener(() {}, onChanged: (fields) {
      if (!isClosed) {
        add(GridHeaderEvent.didReceiveFieldUpdate(fields));
      }
    });
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
  const factory GridHeaderEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
  const factory GridHeaderEvent.moveField(int fromIndex, int toIndex) = _MoveField;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required List<Field> fields}) = _GridHeaderState;

  factory GridHeaderState.initial(List<Field> fields) {
    // final List<Field> newFields = List.from(fields);
    // newFields.retainWhere((field) => field.visibility);
    return GridHeaderState(fields: fields);
  }
}
