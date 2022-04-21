import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'type_option_service.dart';

part 'single_select_bloc.freezed.dart';

class SingleSelectTypeOptionBloc extends Bloc<SingleSelectTypeOptionEvent, SingleSelectTypeOptionState> {
  final TypeOptionService service;

  SingleSelectTypeOptionBloc(
    TypeOptionContext typeOptionContext,
  )   : service = TypeOptionService(gridId: typeOptionContext.gridId, fieldId: typeOptionContext.field.id),
        super(
          SingleSelectTypeOptionState.initial(SingleSelectTypeOption.fromBuffer(typeOptionContext.data)),
        ) {
    on<SingleSelectTypeOptionEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) async {
            final result = await service.newOption(name: value.optionName);
            result.fold(
              (option) {
                emit(state.copyWith(typeOption: _insertOption(option)));
              },
              (err) => Log.error(err),
            );
          },
          updateOption: (_UpdateOption value) async {
            emit(state.copyWith(typeOption: _updateOption(value.option)));
          },
          deleteOption: (_DeleteOption value) {
            emit(state.copyWith(typeOption: _deleteOption(value.option)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }

  SingleSelectTypeOption _insertOption(SelectOption option) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      typeOption.options.insert(0, option);
    });
  }

  SingleSelectTypeOption _updateOption(SelectOption option) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      final index = typeOption.options.indexWhere((element) => element.id == option.id);
      if (index != -1) {
        typeOption.options[index] = option;
      }
    });
  }

  SingleSelectTypeOption _deleteOption(SelectOption option) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      final index = typeOption.options.indexWhere((element) => element.id == option.id);
      if (index != -1) {
        typeOption.options.removeAt(index);
      }
    });
  }
}

@freezed
class SingleSelectTypeOptionEvent with _$SingleSelectTypeOptionEvent {
  const factory SingleSelectTypeOptionEvent.createOption(String optionName) = _CreateOption;
  const factory SingleSelectTypeOptionEvent.updateOption(SelectOption option) = _UpdateOption;
  const factory SingleSelectTypeOptionEvent.deleteOption(SelectOption option) = _DeleteOption;
}

@freezed
class SingleSelectTypeOptionState with _$SingleSelectTypeOptionState {
  const factory SingleSelectTypeOptionState({
    required SingleSelectTypeOption typeOption,
  }) = _SingleSelectTypeOptionState;

  factory SingleSelectTypeOptionState.initial(SingleSelectTypeOption typeOption) => SingleSelectTypeOptionState(
        typeOption: typeOption,
      );
}
