import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../field/field_cache.dart';
import 'setting_controller.dart';

part 'group_bloc.freezed.dart';

class GridGroupBloc extends Bloc<GridGroupEvent, GridGroupState> {
  final GridFieldCache _fieldCache;
  final SettingController _settingController;
  Function(List<FieldPB>)? _onFieldsFn;

  GridGroupBloc({required String viewId, required GridFieldCache fieldCache})
      : _fieldCache = fieldCache,
        _settingController = SettingController(viewId: viewId),
        super(GridGroupState.initial(viewId, fieldCache.fields)) {
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
    _onFieldsFn = (fields) => add(GridGroupEvent.didReceiveFieldUpdate(fields));
    _fieldCache.addListener(
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
  const factory GridGroupEvent.didReceiveFieldUpdate(List<FieldPB> fields) =
      _DidReceiveFieldUpdate;
  const factory GridGroupEvent.moveField(int fromIndex, int toIndex) =
      _MoveField;
}

@freezed
class GridGroupState with _$GridGroupState {
  const factory GridGroupState({
    required String gridId,
    required List<FieldPB> fields,
  }) = _GridGroupState;

  factory GridGroupState.initial(String gridId, List<FieldPB> fields) =>
      GridGroupState(
        gridId: gridId,
        fields: fields,
      );
}
