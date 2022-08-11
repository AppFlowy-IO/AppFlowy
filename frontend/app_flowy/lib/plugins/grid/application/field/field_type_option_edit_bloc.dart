import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'type_option/type_option_data_controller.dart';
part 'field_type_option_edit_bloc.freezed.dart';

class FieldTypeOptionEditBloc
    extends Bloc<FieldTypeOptionEditEvent, FieldTypeOptionEditState> {
  final TypeOptionDataController _dataController;
  void Function()? _fieldListenFn;

  FieldTypeOptionEditBloc(TypeOptionDataController dataController)
      : _dataController = dataController,
        super(FieldTypeOptionEditState.initial(dataController)) {
    on<FieldTypeOptionEditEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _fieldListenFn = dataController.addFieldListener((field) {
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
      _dataController.removeFieldListener(_fieldListenFn!);
    }
    return super.close();
  }
}

@freezed
class FieldTypeOptionEditEvent with _$FieldTypeOptionEditEvent {
  const factory FieldTypeOptionEditEvent.initial() = _Initial;
  const factory FieldTypeOptionEditEvent.didReceiveFieldUpdated(FieldPB field) =
      _DidReceiveFieldUpdated;
}

@freezed
class FieldTypeOptionEditState with _$FieldTypeOptionEditState {
  const factory FieldTypeOptionEditState({
    required FieldPB field,
  }) = _FieldTypeOptionEditState;

  factory FieldTypeOptionEditState.initial(
          TypeOptionDataController fieldContext) =>
      FieldTypeOptionEditState(
        field: fieldContext.field,
      );
}
