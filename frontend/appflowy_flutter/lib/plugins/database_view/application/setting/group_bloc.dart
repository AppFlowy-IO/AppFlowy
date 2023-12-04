import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/board_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../group/group_service.dart';

part 'group_bloc.freezed.dart';

class DatabaseGroupBloc extends Bloc<DatabaseGroupEvent, DatabaseGroupState> {
  final DatabaseController _databaseController;
  final GroupBackendService _groupBackendSvc;
  Function(List<FieldInfo>)? _onFieldsFn;
  DatabaseLayoutSettingCallbacks? _layoutSettingCallbacks;

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
            databaseController.fieldController.groupSettings,
          ),
        ) {
    on<DatabaseGroupEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (fieldInfos) {
            emit(
              state.copyWith(
                fieldInfos: fieldInfos,
                groupSettings: databaseController.fieldController.groupSettings,
              ),
            );
          },
          setGroupByField: (
            String fieldId,
            FieldType fieldType, [
            int condition = 0,
            bool hideEmpty = false,
          ]) async {
            final result = await _groupBackendSvc.groupByField(
              fieldId: fieldId,
              condition: condition,
              hideEmpty: hideEmpty,
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
    FieldType fieldType, [
    @Default(0) int condition,
    @Default(false) bool hideEmpty,
  ]) = _DatabaseGroupEvent;
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
    required List<GroupSettingPB> groupSettings,
  }) = _DatabaseGroupState;

  factory DatabaseGroupState.initial(
    String viewId,
    List<FieldInfo> fieldInfos,
    BoardLayoutSettingPB layoutSettings,
    List<GroupSettingPB> groupSettings,
  ) =>
      DatabaseGroupState(
        viewId: viewId,
        fieldInfos: fieldInfos,
        layoutSettings: layoutSettings,
        groupSettings: groupSettings,
      );
}
