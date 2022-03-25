import 'dart:typed_data';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'switch_field_type_bloc.freezed.dart';

class SwitchFieldTypeBloc extends Bloc<SwitchFieldTypeEvent, SwitchFieldTypeState> {
  SwitchFieldTypeBloc(EditFieldContext editContext) : super(SwitchFieldTypeState.initial(editContext)) {
    on<SwitchFieldTypeEvent>(
      (event, emit) async {
        await event.map(
          toFieldType: (_ToFieldType value) async {
            final fieldService = FieldService(gridId: state.gridId);
            final result = await fieldService.getEditFieldContext(value.fieldType);
            result.fold(
              (newEditContext) {
                emit(
                  state.copyWith(
                    field: newEditContext.gridField,
                    typeOptionData: Uint8List.fromList(newEditContext.typeOptionData),
                  ),
                );
              },
              (err) => Log.error(err),
            );
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
class SwitchFieldTypeEvent with _$SwitchFieldTypeEvent {
  const factory SwitchFieldTypeEvent.toFieldType(FieldType fieldType) = _ToFieldType;
}

@freezed
class SwitchFieldTypeState with _$SwitchFieldTypeState {
  const factory SwitchFieldTypeState({
    required String gridId,
    required Field field,
    required Uint8List typeOptionData,
  }) = _SwitchFieldTypeState;

  factory SwitchFieldTypeState.initial(EditFieldContext editContext) => SwitchFieldTypeState(
        gridId: editContext.gridId,
        field: editContext.gridField,
        typeOptionData: Uint8List.fromList(editContext.typeOptionData),
      );
}
