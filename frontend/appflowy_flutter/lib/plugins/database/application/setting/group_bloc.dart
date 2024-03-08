import 'dart:async';

import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/group_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/board_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_bloc.freezed.dart';

class DatabaseGroupBloc extends Bloc<DatabaseGroupEvent, DatabaseGroupState> {
  DatabaseGroupBloc({
    required String viewId,
    required DatabaseController databaseController,
  })  : _databaseController = databaseController,
        _groupBackendSvc = GroupBackendService(viewId),
        super(
          DatabaseGroupState.initial(
            viewId,
            databaseController.fieldController.fieldInfos,
            databaseController.databaseLayoutSetting!.board,
          ),
        ) {
    _dispatch();
  }

  final DatabaseController _databaseController;
  final GroupBackendService _groupBackendSvc;
  Function(List<FieldInfo>)? _onFieldsFn;
  DatabaseLayoutSettingCallbacks? _layoutSettingCallbacks;

  @override
  Future<void> close() async {
    if (_onFieldsFn != null) {
      _databaseController.fieldController
          .removeListener(onFieldsListener: _onFieldsFn!);
      _onFieldsFn = null;
    }
    _layoutSettingCallbacks = null;
    return super.close();
  }

  void _dispatch() {
    on<DatabaseGroupEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (fieldInfos) {
            emit(state.copyWith(fieldInfos: fieldInfos));
          },
          setGroupByField: (String fieldId, FieldType fieldType) async {
            final result = await _groupBackendSvc.groupByField(
              fieldId: fieldId,
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
          didUpdateLayoutSettings: (layoutSettings) {
            emit(state.copyWith(layoutSettings: layoutSettings));
          },
        );
      },
    );
  }

  void _startListening() {
    _onFieldsFn = (fieldInfos) =>
        add(DatabaseGroupEvent.didReceiveFieldUpdate(fieldInfos));
    _databaseController.fieldController.addListener(
      onReceiveFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );

    _layoutSettingCallbacks = DatabaseLayoutSettingCallbacks(
      onLayoutSettingsChanged: (layoutSettings) {
        if (isClosed || !layoutSettings.hasBoard()) {
          return;
        }
        add(
          DatabaseGroupEvent.didUpdateLayoutSettings(layoutSettings.board),
        );
      },
    );
    _databaseController.addListener(
      onLayoutSettingsChanged: _layoutSettingCallbacks,
    );
  }
}

@freezed
class DatabaseGroupEvent with _$DatabaseGroupEvent {
  const factory DatabaseGroupEvent.initial() = _Initial;
  const factory DatabaseGroupEvent.setGroupByField(
    String fieldId,
    FieldType fieldType,
  ) = _DatabaseGroupEvent;
  const factory DatabaseGroupEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;
  const factory DatabaseGroupEvent.didUpdateLayoutSettings(
    BoardLayoutSettingPB layoutSettings,
  ) = _DidUpdateLayoutSettings;
}

@freezed
class DatabaseGroupState with _$DatabaseGroupState {
  const factory DatabaseGroupState({
    required String viewId,
    required List<FieldInfo> fieldInfos,
    required BoardLayoutSettingPB layoutSettings,
  }) = _DatabaseGroupState;

  factory DatabaseGroupState.initial(
    String viewId,
    List<FieldInfo> fieldInfos,
    BoardLayoutSettingPB layoutSettings,
  ) =>
      DatabaseGroupState(
        viewId: viewId,
        fieldInfos: fieldInfos,
        layoutSettings: layoutSettings,
      );
}
