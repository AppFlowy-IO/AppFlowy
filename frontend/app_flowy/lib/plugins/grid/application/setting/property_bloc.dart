import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../field/field_controller.dart';

part 'property_bloc.freezed.dart';

class GridPropertyBloc extends Bloc<GridPropertyEvent, GridPropertyState> {
  final GridFieldController _fieldController;
  Function(List<FieldInfo>)? _onFieldsFn;

  GridPropertyBloc(
      {required String gridId, required GridFieldController fieldController})
      : _fieldController = fieldController,
        super(GridPropertyState.initial(gridId, fieldController.fieldInfos)) {
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
            emit(state.copyWith(fieldContexts: value.fields));
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
      _fieldController.removeListener(onFieldsListener: _onFieldsFn!);
      _onFieldsFn = null;
    }
    return super.close();
  }

  void _startListening() {
    _onFieldsFn =
        (fields) => add(GridPropertyEvent.didReceiveFieldUpdate(fields));
    _fieldController.addListener(
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
      List<FieldInfo> fields) = _DidReceiveFieldUpdate;
  const factory GridPropertyEvent.moveField(int fromIndex, int toIndex) =
      _MoveField;
}

@freezed
class GridPropertyState with _$GridPropertyState {
  const factory GridPropertyState({
    required String gridId,
    required List<FieldInfo> fieldContexts,
  }) = _GridPropertyState;

  factory GridPropertyState.initial(
    String gridId,
    List<FieldInfo> fieldContexts,
  ) =>
      GridPropertyState(
        gridId: gridId,
        fieldContexts: fieldContexts,
      );
}
