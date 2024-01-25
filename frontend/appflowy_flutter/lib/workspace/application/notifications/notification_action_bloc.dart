import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_action_bloc.freezed.dart';

class NotificationActionBloc
    extends Bloc<NotificationActionEvent, NotificationActionState> {
  NotificationActionBloc() : super(const NotificationActionState.initial()) {
    on<NotificationActionEvent>((event, emit) async {
      event.when(
        performAction: (action, nextActions) {
          emit(state.copyWith(action: action, nextActions: nextActions));

          if (nextActions.isNotEmpty) {
            final newActions = [...nextActions];
            final next = newActions.removeAt(0);

            add(
              NotificationActionEvent.performAction(
                action: next,
                nextActions: newActions,
              ),
            );
          }
        },
      );
    });
  }
}

@freezed
class NotificationActionEvent with _$NotificationActionEvent {
  const factory NotificationActionEvent.performAction({
    required NotificationAction action,
    @Default([]) List<NotificationAction> nextActions,
  }) = _PerformAction;
}

class NotificationActionState {
  const NotificationActionState.initial()
      : action = null,
        nextActions = const [];

  const NotificationActionState({
    required this.action,
    this.nextActions = const [],
  });

  final NotificationAction? action;
  final List<NotificationAction> nextActions;

  NotificationActionState copyWith({
    NotificationAction? action,
    List<NotificationAction>? nextActions,
  }) =>
      NotificationActionState(
        action: action ?? this.action,
        nextActions: nextActions ?? this.nextActions,
      );
}
