import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_action_bloc.freezed.dart';

class NotificationActionBloc
    extends Bloc<NotificationActionEvent, NotificationActionState> {
  NotificationActionBloc() : super(const NotificationActionState.initial()) {
    on<NotificationActionEvent>((event, emit) async {
      event.when(
        performAction: (action) {
          emit(state.copyWith(action: action));
        },
      );
    });
  }
}

@freezed
class NotificationActionEvent with _$NotificationActionEvent {
  const factory NotificationActionEvent.performAction({
    required NotificationAction action,
  }) = _PerformAction;
}

class NotificationActionState {
  const NotificationActionState({required this.action});

  final NotificationAction? action;

  const NotificationActionState.initial() : action = null;

  NotificationActionState copyWith({
    NotificationAction? action,
  }) =>
      NotificationActionState(action: action ?? this.action);
}
