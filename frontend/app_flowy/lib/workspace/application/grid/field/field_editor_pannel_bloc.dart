import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'field_service.dart';

part 'field_editor_pannel_bloc.freezed.dart';

class FieldEditorPannelBloc extends Bloc<FieldEditorPannelEvent, FieldEditorPannelState> {
  final GridFieldContext _fieldContext;
  void Function()? _fieldListenFn;

  FieldEditorPannelBloc(GridFieldContext fieldContext)
      : _fieldContext = fieldContext,
        super(FieldEditorPannelState.initial(fieldContext)) {
    on<FieldEditorPannelEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _fieldListenFn = fieldContext.addFieldListener((field) {
              add(FieldEditorPannelEvent.didReceiveFieldUpdated(field));
            });
          },
          didReceiveFieldUpdated: (field) {
            emit(state.copyWith(field: field));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_fieldListenFn != null) {
      _fieldContext.removeFieldListener(_fieldListenFn!);
    }
    return super.close();
  }
}

@freezed
class FieldEditorPannelEvent with _$FieldEditorPannelEvent {
  const factory FieldEditorPannelEvent.initial() = _Initial;
  const factory FieldEditorPannelEvent.didReceiveFieldUpdated(Field field) = _DidReceiveFieldUpdated;
}

@freezed
class FieldEditorPannelState with _$FieldEditorPannelState {
  const factory FieldEditorPannelState({
    required Field field,
  }) = _FieldEditorPannelState;

  factory FieldEditorPannelState.initial(GridFieldContext fieldContext) => FieldEditorPannelState(
        field: fieldContext.field,
      );
}
