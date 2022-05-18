import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'type_option_service.dart';

part 'multi_select_bloc.freezed.dart';

typedef MultiSelectTypeOptionContext = TypeOptionContext<MultiSelectTypeOption>;

class MultiSelectTypeOptionDataBuilder extends TypeOptionDataBuilder<MultiSelectTypeOption> {
  @override
  MultiSelectTypeOption fromBuffer(List<int> buffer) {
    return MultiSelectTypeOption.fromBuffer(buffer);
  }
}

class MultiSelectTypeOptionBloc extends Bloc<MultiSelectTypeOptionEvent, MultiSelectTypeOptionState> {
  final TypeOptionService service;

  MultiSelectTypeOptionBloc(MultiSelectTypeOptionContext typeOptionContext)
      : service = TypeOptionService(
          gridId: typeOptionContext.gridId,
          fieldId: typeOptionContext.field.id,
        ),
        super(MultiSelectTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<MultiSelectTypeOptionEvent>(
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

  MultiSelectTypeOption _insertOption(SelectOption option) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      typeOption.options.insert(0, option);
    });
  }

  MultiSelectTypeOption _updateOption(SelectOption option) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      final index = typeOption.options.indexWhere((element) => element.id == option.id);
      if (index != -1) {
        typeOption.options[index] = option;
      }
    });
  }

  MultiSelectTypeOption _deleteOption(SelectOption option) {
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
class MultiSelectTypeOptionEvent with _$MultiSelectTypeOptionEvent {
  const factory MultiSelectTypeOptionEvent.createOption(String optionName) = _CreateOption;
  const factory MultiSelectTypeOptionEvent.updateOption(SelectOption option) = _UpdateOption;
  const factory MultiSelectTypeOptionEvent.deleteOption(SelectOption option) = _DeleteOption;
}

@freezed
class MultiSelectTypeOptionState with _$MultiSelectTypeOptionState {
  const factory MultiSelectTypeOptionState({
    required MultiSelectTypeOption typeOption,
  }) = _MultiSelectTypeOptionState;

  factory MultiSelectTypeOptionState.initial(MultiSelectTypeOption typeOption) => MultiSelectTypeOptionState(
        typeOption: typeOption,
      );
}
