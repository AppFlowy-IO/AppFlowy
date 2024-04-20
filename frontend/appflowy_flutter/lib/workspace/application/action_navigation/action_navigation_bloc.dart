import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_navigation_bloc.freezed.dart';

class ActionNavigationBloc
    extends Bloc<ActionNavigationEvent, ActionNavigationState> {
  ActionNavigationBloc() : super(const ActionNavigationState.initial()) {
    on<ActionNavigationEvent>((event, emit) async {
      await event.when(
        initialize: () async {
          final views = await ViewBackendService().fetchViews();
          emit(state.copyWith(views: views));
          await initializeListeners();
        },
        viewsChanged: (views) {
          emit(state.copyWith(views: views));
        },
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
          } else {
            emit(state.setNoAction());
          }
        },
      );
    });
  }

  WorkspaceListener? _workspaceListener;

  @override
  Future<void> close() async {
    await _workspaceListener?.stop();
    return super.close();
  }

  Future<void> initializeListeners() async {
    if (_workspaceListener != null) {
      return;
    }

    final userOrFailure = await getIt<AuthService>().getUser();
    final user = userOrFailure.fold((s) => s, (f) => null);
    if (user == null) {
      _workspaceListener = null;
      return;
    }

    final workspaceSettingsOrFailure =
        await FolderEventGetCurrentWorkspaceSetting().send();
    final workspaceId = workspaceSettingsOrFailure.fold(
      (s) => s.workspaceId,
      (f) => null,
    );
    if (workspaceId == null) {
      _workspaceListener = null;
      return;
    }

    _workspaceListener = WorkspaceListener(
      user: user,
      workspaceId: workspaceId,
    );

    _workspaceListener?.start(
      appsChanged: (_) async {
        final views = await ViewBackendService().fetchViews();
        add(ActionNavigationEvent.viewsChanged(views));
      },
    );
  }
}

@freezed
class ActionNavigationEvent with _$ActionNavigationEvent {
  const factory ActionNavigationEvent.initialize() = _Initialize;

  const factory ActionNavigationEvent.performAction({
    required NavigationAction action,
    @Default([]) List<NavigationAction> nextActions,
  }) = _PerformAction;

  const factory ActionNavigationEvent.viewsChanged(List<ViewPB> views) =
      _ViewsChanged;
}

class ActionNavigationState {
  const ActionNavigationState.initial()
      : action = null,
        nextActions = const [],
        views = const [];

  const ActionNavigationState({
    required this.action,
    this.nextActions = const [],
    this.views = const [],
  });

  final NavigationAction? action;
  final List<NavigationAction> nextActions;
  final List<ViewPB> views;

  ActionNavigationState copyWith({
    NavigationAction? action,
    List<NavigationAction>? nextActions,
    List<ViewPB>? views,
  }) =>
      ActionNavigationState(
        action: action ?? this.action,
        nextActions: nextActions ?? this.nextActions,
        views: views ?? this.views,
      );

  ActionNavigationState setNoAction() =>
      ActionNavigationState(action: null, nextActions: [], views: views);
}
