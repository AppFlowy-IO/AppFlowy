import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'group_bloc.freezed.dart';

class DatabaseGroupBloc extends Bloc<DatabaseGroupEvent, DatabaseGroupState> {
  final FieldController _fieldController;
  final SettingBackendService _settingBackendSvc;
  Function(List<FieldInfo>)? _onFieldsFn;

  DatabaseGroupBloc({
    required final String viewId,
    required final FieldController fieldController,
  })  : _fieldController = fieldController,
        _settingBackendSvc = SettingBackendService(viewId: viewId),
        super(DatabaseGroupState.initial(viewId, fieldController.fieldInfos)) {
    on<DatabaseGroupEvent>(
      (final event, final emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (final fieldContexts) {
            emit(state.copyWith(fieldContexts: fieldContexts));
          },
          setGroupByField: (final String fieldId, final FieldType fieldType) async {
            final result = await _settingBackendSvc.groupByField(
              fieldId: fieldId,
              fieldType: fieldType,
            );
            result.fold((final l) => null, (final err) => Log.error(err));
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
    _onFieldsFn = (final fieldContexts) =>
        add(DatabaseGroupEvent.didReceiveFieldUpdate(fieldContexts));
    _fieldController.addListener(
      onReceiveFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class DatabaseGroupEvent with _$DatabaseGroupEvent {
  const factory DatabaseGroupEvent.initial() = _Initial;
  const factory DatabaseGroupEvent.setGroupByField(
    final String fieldId,
    final FieldType fieldType,
  ) = _DatabaseGroupEvent;
  const factory DatabaseGroupEvent.didReceiveFieldUpdate(
    final List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;
}

@freezed
class DatabaseGroupState with _$DatabaseGroupState {
  const factory DatabaseGroupState({
    required final String viewId,
    required final List<FieldInfo> fieldContexts,
  }) = _DatabaseGroupState;

  factory DatabaseGroupState.initial(
    final String viewId,
    final List<FieldInfo> fieldContexts,
  ) =>
      DatabaseGroupState(
        viewId: viewId,
        fieldContexts: fieldContexts,
      );
}
