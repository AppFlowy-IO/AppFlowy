import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'setting_bloc.freezed.dart';

class GridSettingBloc extends Bloc<GridSettingEvent, GridSettingState> {
  final String gridId;
  GridSettingBloc({required this.gridId}) : super(GridSettingState.initial()) {
    on<GridSettingEvent>(
      (event, emit) async {
        event.map(performAction: (_PerformAction value) {
          emit(state.copyWith(selectedAction: Some(value.action)));
        });
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class GridSettingEvent with _$GridSettingEvent {
  const factory GridSettingEvent.performAction(GridSettingAction action) = _PerformAction;
}

@freezed
class GridSettingState with _$GridSettingState {
  const factory GridSettingState({
    required Option<GridSettingAction> selectedAction,
  }) = _GridSettingState;

  factory GridSettingState.initial() => GridSettingState(
        selectedAction: none(),
      );
}

enum GridSettingAction {
  filter,
  sortBy,
  properties,
}
