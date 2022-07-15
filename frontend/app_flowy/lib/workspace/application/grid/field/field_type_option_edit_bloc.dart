import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'field_service.dart';

part 'field_type_option_edit_bloc.freezed.dart';

class FieldTypeOptionEditBloc extends Bloc<FieldTypeOptionEditEvent, FieldTypeOptionEditState> {
  final GridFieldContext _fieldContext;
  void Function()? _fieldListenFn;

  FieldTypeOptionEditBloc(GridFieldContext fieldContext)
      : _fieldContext = fieldContext,
        super(FieldTypeOptionEditState.initial(fieldContext)) {
    on<FieldTypeOptionEditEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _fieldListenFn = fieldContext.addFieldListener((field) {
              add(FieldTypeOptionEditEvent.didReceiveFieldUpdated(field));
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
class FieldTypeOptionEditEvent with _$FieldTypeOptionEditEvent {
  const factory FieldTypeOptionEditEvent.initial() = _Initial;
  const factory FieldTypeOptionEditEvent.didReceiveFieldUpdated(Field field) = _DidReceiveFieldUpdated;
}

@freezed
class FieldTypeOptionEditState with _$FieldTypeOptionEditState {
  const factory FieldTypeOptionEditState({
    required Field field,
  }) = _FieldTypeOptionEditState;

  factory FieldTypeOptionEditState.initial(GridFieldContext fieldContext) => FieldTypeOptionEditState(
        field: fieldContext.field,
      );
}
