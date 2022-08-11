import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:app_flowy/plugins/grid/application/grid_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'property_bloc.freezed.dart';

class GridPropertyBloc extends Bloc<GridPropertyEvent, GridPropertyState> {
  final GridFieldCache _fieldCache;
  Function(List<GridFieldPB>)? _onFieldsFn;

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
            final fieldService =
                FieldService(gridId: gridId, fieldId: value.fieldId);
            final result =
                await fieldService.updateField(visibility: value.visibility);
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
    if (_onFieldsFn != null) {
      _fieldCache.removeListener(onFieldsListener: _onFieldsFn!);
      _onFieldsFn = null;
    }
    return super.close();
  }

  void _startListening() {
    _onFieldsFn =
        (fields) => add(GridPropertyEvent.didReceiveFieldUpdate(fields));
    _fieldCache.addListener(
      onFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class GridPropertyEvent with _$GridPropertyEvent {
  const factory GridPropertyEvent.initial() = _Initial;
  const factory GridPropertyEvent.setFieldVisibility(
      String fieldId, bool visibility) = _SetFieldVisibility;
  const factory GridPropertyEvent.didReceiveFieldUpdate(
      List<GridFieldPB> fields) = _DidReceiveFieldUpdate;
  const factory GridPropertyEvent.moveField(int fromIndex, int toIndex) =
      _MoveField;
}

@freezed
class GridPropertyState with _$GridPropertyState {
  const factory GridPropertyState({
    required String gridId,
    required List<GridFieldPB> fields,
  }) = _GridPropertyState;

  factory GridPropertyState.initial(String gridId, List<GridFieldPB> fields) =>
      GridPropertyState(
        gridId: gridId,
        fields: fields,
      );
}
