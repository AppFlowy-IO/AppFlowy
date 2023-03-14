import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'setting_bloc.freezed.dart';

class DatabaseSettingBloc
    extends Bloc<DatabaseSettingEvent, DatabaseSettingState> {
  final String viewId;
  DatabaseSettingBloc({required this.viewId})
      : super(DatabaseSettingState.initial()) {
    on<DatabaseSettingEvent>(
      (event, emit) async {
        event.map(performAction: (_PerformAction value) {
          emit(state.copyWith(selectedAction: Some(value.action)));
        });
      },
    );
  }
}

@freezed
class DatabaseSettingEvent with _$DatabaseSettingEvent {
  const factory DatabaseSettingEvent.performAction(
      DatabaseSettingAction action) = _PerformAction;
}

@freezed
class DatabaseSettingState with _$DatabaseSettingState {
  const factory DatabaseSettingState({
    required Option<DatabaseSettingAction> selectedAction,
  }) = _DatabaseSettingState;

  factory DatabaseSettingState.initial() => DatabaseSettingState(
        selectedAction: none(),
      );
}

enum DatabaseSettingAction {
  showFilters,
  sortBy,
  showProperties,
}
