import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_navigation_bloc.freezed.dart';

class ActionNavigationBloc
    extends Bloc<ActionNavigationEvent, ActionNavigationState> {
  ActionNavigationBloc() : super(const ActionNavigationState.initial()) {
    on<ActionNavigationEvent>((event, emit) async {
      event.when(
        performAction: (action, nextActions) {
          emit(state.copyWith(action: action, nextActions: nextActions));

          if (nextActions.isNotEmpty) {
            final newActions = [...nextActions];
            final next = newActions.removeAt(0);

            add(
              ActionNavigationEvent.performAction(
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
class ActionNavigationEvent with _$ActionNavigationEvent {
  const factory ActionNavigationEvent.performAction({
    required NavigationAction action,
    @Default([]) List<NavigationAction> nextActions,
  }) = _PerformAction;
}

class ActionNavigationState {
  const ActionNavigationState.initial()
      : action = null,
        nextActions = const [];

  const ActionNavigationState({
    required this.action,
    this.nextActions = const [],
  });

  final NavigationAction? action;
  final List<NavigationAction> nextActions;

  ActionNavigationState copyWith({
    NavigationAction? action,
    List<NavigationAction>? nextActions,
  }) =>
      ActionNavigationState(
        action: action ?? this.action,
        nextActions: nextActions ?? this.nextActions,
      );
}
