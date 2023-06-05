import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/log.dart';
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
    required final String viewId,
    required final FieldController fieldController,
  })  : _fieldController = fieldController,
        super(
          DatabasePropertyState.initial(viewId, fieldController.fieldInfos),
        ) {
    on<DatabasePropertyEvent>(
      (final event, final emit) async {
        await event.map(
          initial: (final _Initial value) {
            _startListening();
          },
          setFieldVisibility: (final _SetFieldVisibility value) async {
            final fieldBackendSvc =
                FieldBackendService(viewId: viewId, fieldId: value.fieldId);
            final result =
                await fieldBackendSvc.updateField(visibility: value.visibility);
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          didReceiveFieldUpdate: (final _DidReceiveFieldUpdate value) {
            emit(state.copyWith(fieldContexts: value.fields));
          },
          moveField: (final _MoveField value) {
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
        (final fields) => add(DatabasePropertyEvent.didReceiveFieldUpdate(fields));
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
    final String fieldId,
    final bool visibility,
  ) = _SetFieldVisibility;
  const factory DatabasePropertyEvent.didReceiveFieldUpdate(
    final List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;
  const factory DatabasePropertyEvent.moveField(final int fromIndex, final int toIndex) =
      _MoveField;
}

@freezed
class DatabasePropertyState with _$DatabasePropertyState {
  const factory DatabasePropertyState({
    required final String viewId,
    required final List<FieldInfo> fieldContexts,
  }) = _GridPropertyState;

  factory DatabasePropertyState.initial(
    final String viewId,
    final List<FieldInfo> fieldContexts,
  ) =>
      DatabasePropertyState(
        viewId: viewId,
        fieldContexts: fieldContexts,
      );
}
