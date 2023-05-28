import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../group/group_service.dart';

part 'group_bloc.freezed.dart';

class DatabaseGroupBloc extends Bloc<DatabaseGroupEvent, DatabaseGroupState> {
  final FieldController _fieldController;
  final GroupBackendService _groupBackendSvc;
  Function(List<FieldInfo>)? _onFieldsFn;

  DatabaseGroupBloc({
    required String viewId,
    required FieldController fieldController,
  })  : _fieldController = fieldController,
        _groupBackendSvc = GroupBackendService(viewId),
        super(DatabaseGroupState.initial(viewId, fieldController.fieldInfos)) {
    on<DatabaseGroupEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (fieldContexts) {
            emit(state.copyWith(fieldContexts: fieldContexts));
          },
          setGroupByField: (String fieldId, FieldType fieldType) async {
            final result = await _groupBackendSvc.groupByField(
              fieldId: fieldId,
              fieldType: fieldType,
            );
            result.fold((l) => null, (err) => Log.error(err));
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
    _onFieldsFn = (fieldContexts) =>
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
    String fieldId,
    FieldType fieldType,
  ) = _DatabaseGroupEvent;
  const factory DatabaseGroupEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;
}

@freezed
class DatabaseGroupState with _$DatabaseGroupState {
  const factory DatabaseGroupState({
    required String viewId,
    required List<FieldInfo> fieldContexts,
  }) = _DatabaseGroupState;

  factory DatabaseGroupState.initial(
    String viewId,
    List<FieldInfo> fieldContexts,
  ) =>
      DatabaseGroupState(
        viewId: viewId,
        fieldContexts: fieldContexts,
      );
}
