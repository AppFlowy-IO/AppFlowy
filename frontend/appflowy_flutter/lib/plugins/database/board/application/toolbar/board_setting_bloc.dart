import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_setting_bloc.freezed.dart';

class BoardSettingBloc extends Bloc<BoardSettingEvent, BoardSettingState> {
  BoardSettingBloc({required this.viewId})
      : super(BoardSettingState.initial()) {
    on<BoardSettingEvent>(
      (event, emit) async {
        event.when(
          performAction: (action) {
            emit(state.copyWith(selectedAction: action));
          },
        );
      },
    );
  }

  final String viewId;
}

@freezed
class BoardSettingEvent with _$BoardSettingEvent {
  const factory BoardSettingEvent.performAction(BoardSettingAction action) =
      _PerformAction;
}

@freezed
class BoardSettingState with _$BoardSettingState {
  const factory BoardSettingState({
    required BoardSettingAction? selectedAction,
  }) = _BoardSettingState;

  factory BoardSettingState.initial() => const BoardSettingState(
        selectedAction: null,
      );
}

enum BoardSettingAction {
  properties,
  groups,
}
