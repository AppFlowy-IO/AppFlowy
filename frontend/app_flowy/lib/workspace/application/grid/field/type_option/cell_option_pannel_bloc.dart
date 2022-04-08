import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'package:dartz/dartz.dart';
part 'cell_option_pannel_bloc.freezed.dart';

class CellOptionPannelBloc extends Bloc<CellOptionPannelEvent, CellOptionPannelState> {
  CellOptionPannelBloc({required SelectOption option}) : super(CellOptionPannelState.initial(option)) {
    on<CellOptionPannelEvent>(
      (event, emit) async {
        event.map(
          updateName: (_UpdateName value) {
            emit(state.copyWith(option: _updateName(value.name)));
          },
          updateColor: (_UpdateColor value) {
            emit(state.copyWith(option: _updateColor(value.color)));
          },
          delete: (_Delete value) {
            emit(state.copyWith(deleted: const Some(true)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }

  SelectOption _updateColor(SelectOptionColor color) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.color = color;
    });
  }

  SelectOption _updateName(String name) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.name = name;
    });
  }
}

@freezed
class CellOptionPannelEvent with _$CellOptionPannelEvent {
  const factory CellOptionPannelEvent.updateName(String name) = _UpdateName;
  const factory CellOptionPannelEvent.updateColor(SelectOptionColor color) = _UpdateColor;
  const factory CellOptionPannelEvent.delete() = _Delete;
}

@freezed
class CellOptionPannelState with _$CellOptionPannelState {
  const factory CellOptionPannelState({
    required SelectOption option,
    required Option<bool> deleted,
  }) = _EditOptionState;

  factory CellOptionPannelState.initial(SelectOption option) => CellOptionPannelState(
        option: option,
        deleted: none(),
      );
}
