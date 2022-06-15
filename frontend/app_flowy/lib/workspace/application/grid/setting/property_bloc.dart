import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/field.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'property_bloc.freezed.dart';

class GridPropertyBloc extends Bloc<GridPropertyEvent, GridPropertyState> {
  final GridFieldCache _fieldCache;
  Function()? _listenFieldCallback;

  GridPropertyBloc({required String gridId, required GridFieldCache fieldCache})
      : _fieldCache = fieldCache,
        super(GridPropertyState.initial(gridId, fieldCache.fields)) {
    on<GridPropertyEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          setFieldVisibility: (_SetFieldVisibility value) async {
            final fieldService = FieldService(gridId: gridId, fieldId: value.fieldId);
            final result = await fieldService.updateField(visibility: value.visibility);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
          },
          moveField: (_MoveField value) {
            //
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_listenFieldCallback != null) {
      _fieldCache.removeListener(_listenFieldCallback!);
    }
    return super.close();
  }

  void _startListening() {
    _listenFieldCallback = _fieldCache.addListener(
      onChanged: (fields) => add(GridPropertyEvent.didReceiveFieldUpdate(fields)),
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class GridPropertyEvent with _$GridPropertyEvent {
  const factory GridPropertyEvent.initial() = _Initial;
  const factory GridPropertyEvent.setFieldVisibility(String fieldId, bool visibility) = _SetFieldVisibility;
  const factory GridPropertyEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
  const factory GridPropertyEvent.moveField(int fromIndex, int toIndex) = _MoveField;
}

@freezed
class GridPropertyState with _$GridPropertyState {
  const factory GridPropertyState({
    required String gridId,
    required List<Field> fields,
  }) = _GridPropertyState;

  factory GridPropertyState.initial(String gridId, List<Field> fields) => GridPropertyState(
        gridId: gridId,
        fields: fields,
      );
}
