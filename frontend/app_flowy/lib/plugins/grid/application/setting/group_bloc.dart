import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../field/field_cache.dart';
import 'setting_controller.dart';

part 'group_bloc.freezed.dart';

class GridGroupBloc extends Bloc<GridGroupEvent, GridGroupState> {
  final GridFieldController _fieldController;
  final SettingController _settingController;
  Function(List<GridFieldContext>)? _onFieldsFn;

  GridGroupBloc(
      {required String viewId, required GridFieldController fieldController})
      : _fieldController = fieldController,
        _settingController = SettingController(viewId: viewId),
        super(GridGroupState.initial(viewId, fieldController.fieldContexts)) {
    on<GridGroupEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          setFieldVisibility: (_SetFieldVisibility value) async {
            final fieldService =
                FieldService(gridId: viewId, fieldId: value.fieldId);
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
    _onFieldsFn = (fields) => add(GridGroupEvent.didReceiveFieldUpdate(fields));
    _fieldController.addListener(
      onFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );

    _settingController.startListeing(
      onSettingUpdated: (setting) {},
      onError: (err) {},
    );
  }
}

@freezed
class GridGroupEvent with _$GridGroupEvent {
  const factory GridGroupEvent.initial() = _Initial;
  const factory GridGroupEvent.setFieldVisibility(
      String fieldId, bool visibility) = _SetFieldVisibility;
  const factory GridGroupEvent.didReceiveFieldUpdate(
      List<GridFieldContext> fields) = _DidReceiveFieldUpdate;
  const factory GridGroupEvent.moveField(int fromIndex, int toIndex) =
      _MoveField;
}

@freezed
class GridGroupState with _$GridGroupState {
  const factory GridGroupState({
    required String gridId,
    required List<GridFieldContext> fieldContexts,
  }) = _GridGroupState;

  factory GridGroupState.initial(
          String gridId, List<GridFieldContext> fieldContexts) =>
      GridGroupState(
        gridId: gridId,
        fieldContexts: fieldContexts,
      );
}
