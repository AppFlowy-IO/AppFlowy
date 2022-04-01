import 'dart:typed_data';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'switch_field_type_bloc.freezed.dart';

class FieldSwitchBloc extends Bloc<FieldSwitchEvent, FieldSwitchState> {
  FieldSwitchBloc(SwitchFieldContext editContext) : super(FieldSwitchState.initial(editContext)) {
    on<FieldSwitchEvent>(
      (event, emit) async {
        await event.map(
          toFieldType: (_ToFieldType value) async {
            final fieldService = FieldService(gridId: state.gridId);
            final result = await fieldService.switchToField(state.field.id, value.fieldType);
            result.fold(
              (newEditContext) {
                final typeOptionData = Uint8List.fromList(newEditContext.typeOptionData);
                emit(state.copyWith(field: newEditContext.gridField, typeOptionData: typeOptionData));
              },
              (err) => Log.error(err),
            );
          },
          didUpdateTypeOptionData: (_DidUpdateTypeOptionData value) {
            emit(state.copyWith(typeOptionData: value.typeOptionData));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class FieldSwitchEvent with _$FieldSwitchEvent {
  const factory FieldSwitchEvent.toFieldType(FieldType fieldType) = _ToFieldType;
  const factory FieldSwitchEvent.didUpdateTypeOptionData(Uint8List typeOptionData) = _DidUpdateTypeOptionData;
}

@freezed
class FieldSwitchState with _$FieldSwitchState {
  const factory FieldSwitchState({
    required String gridId,
    required Field field,
    required Uint8List typeOptionData,
  }) = _FieldSwitchState;

  factory FieldSwitchState.initial(SwitchFieldContext switchContext) => FieldSwitchState(
        gridId: switchContext.gridId,
        field: switchContext.field,
        typeOptionData: Uint8List.fromList(switchContext.typeOptionData),
      );
}

class SwitchFieldContext {
  final String gridId;
  final Field field;
  final List<int> typeOptionData;

  SwitchFieldContext(this.gridId, this.field, this.typeOptionData);
}
