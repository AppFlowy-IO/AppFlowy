import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'field_editor_pannel_bloc.freezed.dart';

class FieldEditorPannelBloc extends Bloc<FieldEditorPannelEvent, FieldEditorPannelState> {
  FieldEditorPannelBloc(FieldTypeOptionData editContext) : super(FieldEditorPannelState.initial(editContext)) {
    on<FieldEditorPannelEvent>(
      (event, emit) async {
        await event.map(
          toFieldType: (_ToFieldType value) async {
            emit(state.copyWith(
              field: value.field,
              typeOptionData: Uint8List.fromList(value.typeOptionData),
            ));
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
class FieldEditorPannelEvent with _$FieldEditorPannelEvent {
  const factory FieldEditorPannelEvent.toFieldType(Field field, List<int> typeOptionData) = _ToFieldType;
  const factory FieldEditorPannelEvent.didUpdateTypeOptionData(Uint8List typeOptionData) = _DidUpdateTypeOptionData;
}

@freezed
class FieldEditorPannelState with _$FieldEditorPannelState {
  const factory FieldEditorPannelState({
    required String gridId,
    required Field field,
    required Uint8List typeOptionData,
  }) = _FieldEditorPannelState;

  factory FieldEditorPannelState.initial(FieldTypeOptionData data) => FieldEditorPannelState(
        gridId: data.gridId,
        field: data.field_2,
        typeOptionData: Uint8List.fromList(data.typeOptionData),
      );
}
