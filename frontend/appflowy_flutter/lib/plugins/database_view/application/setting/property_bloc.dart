import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../field/field_service.dart';

part 'property_bloc.freezed.dart';

class DatabasePropertyBloc
    extends Bloc<DatabasePropertyEvent, DatabasePropertyState> {
  final FieldController _fieldController;
  Function(List<FieldInfo>)? _onFieldsFn;

  DatabasePropertyBloc({
    required String viewId,
    required FieldController fieldController,
  })  : _fieldController = fieldController,
        super(
          DatabasePropertyState.initial(viewId, fieldController.fieldInfos),
        ) {
    on<DatabasePropertyEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          setFieldVisibility: (_SetFieldVisibility value) async {
            final fieldSettingsSvc = FieldSettingsBackendService(
              viewId: viewId,
            );

            final result = await fieldSettingsSvc.updateFieldSettings(
              fieldId: value.fieldId,
              fieldVisibility: value.visibility,
            );

            result.fold((l) => null, (err) => Log.error(err));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fieldContexts: value.fields));
          },
          moveField: (_MoveField value) async {
            final fieldBackendService = FieldBackendService(
              viewId: viewId,
              fieldId: value.fieldId,
            );

            final result = await fieldBackendService.moveField(
              value.fromIndex,
              value.toIndex,
            );

            result.fold((l) => null, (r) => Log.error(r));
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
        (fields) => add(DatabasePropertyEvent.didReceiveFieldUpdate(fields));
    _fieldController.addListener(
      onReceiveFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class DatabasePropertyEvent with _$DatabasePropertyEvent {
  const factory DatabasePropertyEvent.initial() = _Initial;
  const factory DatabasePropertyEvent.setFieldVisibility(
    String fieldId,
    FieldVisibility visibility,
  ) = _SetFieldVisibility;
  const factory DatabasePropertyEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;
  const factory DatabasePropertyEvent.moveField({
    required String fieldId,
    required int fromIndex,
    required int toIndex,
  }) = _MoveField;
}

@freezed
class DatabasePropertyState with _$DatabasePropertyState {
  const factory DatabasePropertyState({
    required String viewId,
    required List<FieldInfo> fieldContexts,
  }) = _GridPropertyState;

  factory DatabasePropertyState.initial(
    String viewId,
    List<FieldInfo> fieldContexts,
  ) =>
      DatabasePropertyState(
        viewId: viewId,
        fieldContexts: fieldContexts,
      );
}
