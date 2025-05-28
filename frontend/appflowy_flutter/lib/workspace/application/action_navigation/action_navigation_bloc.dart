import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_navigation_bloc.freezed.dart';

class ActionNavigationBloc
    extends Bloc<ActionNavigationEvent, ActionNavigationState> {
  ActionNavigationBloc() : super(const ActionNavigationState.initial()) {
    on<ActionNavigationEvent>((event, emit) async {
      await event.when(
        performAction: (action, showErrorToast, nextActions) async {
          NavigationAction currentAction = action;
          if (currentAction.arguments?[ActionArgumentKeys.view] == null &&
              action.type == ActionType.openView) {
            final result = await ViewBackendService.getView(action.objectId);
            final view = result.toNullable();
            if (view != null) {
              if (currentAction.arguments == null) {
                currentAction = currentAction.copyWith(arguments: {});
              }
              currentAction.arguments?.addAll({ActionArgumentKeys.view: view});

            } else {
              Log.error('Open view failed: ${action.objectId}');
              if (showErrorToast) {
                showToastNotification(
                  message: LocaleKeys.search_pageNotExist.tr(),
                  type: ToastificationType.error,
                );
              }
            }
          }

          emit(state.copyWith(action: currentAction, nextActions: nextActions));

          if (nextActions.isNotEmpty) {
            final newActions = [...nextActions];
            final next = newActions.removeAt(0);

            add(
              ActionNavigationEvent.performAction(
                action: next,
                nextActions: newActions,
              ),
            );
          } else {
            emit(state.setNoAction());
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
    @Default(false) bool showErrorToast,
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

  ActionNavigationState setNoAction() =>
      const ActionNavigationState(action: null);
}
