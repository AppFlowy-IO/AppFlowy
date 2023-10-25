import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../group/group_service.dart';

part 'group_bloc.freezed.dart';

class DatabaseGroupBloc extends Bloc<DatabaseGroupEvent, DatabaseGroupState> {
  final DatabaseController _databaseController;
  final GroupBackendService _groupBackendSvc;
  Function(List<FieldInfo>)? _onFieldsFn;
  GroupCallbacks? _groupCallbacks;

  DatabaseGroupBloc({
    required String viewId,
    required DatabaseController databaseController,
  })  : _databaseController = databaseController,
        _groupBackendSvc = GroupBackendService(viewId),
        super(
          DatabaseGroupState.initial(
            viewId,
            databaseController.fieldController.fieldInfos,
          ),
        ) {
    on<DatabaseGroupEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _loadGroupConfigurations();
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
          didUpdateHideUngrouped: (bool hideUngrouped) {
            emit(state.copyWith(hideUngrouped: hideUngrouped));
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
    _groupCallbacks = null;
    return super.close();
  }

  void _startListening() {
    _onFieldsFn = (fieldInfos) =>
        add(DatabaseGroupEvent.didReceiveFieldUpdate(fieldInfos));
    _databaseController.fieldController.addListener(
      onReceiveFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );

    _groupCallbacks = GroupCallbacks(
      onGroupConfigurationChanged: (configurations) {
        if (isClosed) {
          return;
        }
        final configuration = configurations.first;
        add(
          DatabaseGroupEvent.didUpdateHideUngrouped(
            configuration.hideUngrouped,
          ),
        );
      },
    );
    _databaseController.addListener(onGroupChanged: _groupCallbacks);
  }

  void _loadGroupConfigurations() async {
    final configResult = await _databaseController.loadGroupConfiguration(
      viewId: _databaseController.viewId,
    );
    configResult.fold(
      (configurations) {
        final hideUngrouped = configurations.first.hideUngrouped;
        if (hideUngrouped) {
          add(DatabaseGroupEvent.didUpdateHideUngrouped(hideUngrouped));
        }
      },
      (err) => Log.error(err),
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
  const factory DatabaseGroupEvent.didUpdateHideUngrouped(bool hideUngrouped) =
      _DidUpdateHideUngrouped;
}

@freezed
class DatabaseGroupState with _$DatabaseGroupState {
  const factory DatabaseGroupState({
    required String viewId,
    required List<FieldInfo> fieldInfos,
    required bool hideUngrouped,
  }) = _DatabaseGroupState;

  factory DatabaseGroupState.initial(
    String viewId,
    List<FieldInfo> fieldInfos,
  ) =>
      DatabaseGroupState(
        viewId: viewId,
        fieldInfos: fieldInfos,
        hideUngrouped: false,
      );
}
