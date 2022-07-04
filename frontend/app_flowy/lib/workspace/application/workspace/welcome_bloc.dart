import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'welcome_bloc.freezed.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final UserService userService;
  final UserWorkspaceListener userWorkspaceListener;
  WelcomeBloc({required this.userService, required this.userWorkspaceListener}) : super(WelcomeState.initial()) {
    on<WelcomeEvent>(
      (event, emit) async {
        await event.map(initial: (e) async {
          userWorkspaceListener.start(
            onWorkspacesUpdated: (result) => add(WelcomeEvent.workspacesReveived(result)),
          );
          //
          await _fetchWorkspaces(emit);
        }, openWorkspace: (e) async {
          await _openWorkspace(e.workspace, emit);
        }, createWorkspace: (e) async {
          await _createWorkspace(e.name, e.desc, emit);
        }, workspacesReveived: (e) async {
          emit(e.workspacesOrFail.fold(
            (workspaces) => state.copyWith(workspaces: workspaces, successOrFailure: left(unit)),
            (error) => state.copyWith(successOrFailure: right(error)),
          ));
        });
      },
    );
  }

  @override
  Future<void> close() async {
    await userWorkspaceListener.stop();
    super.close();
  }

  Future<void> _fetchWorkspaces(Emitter<WelcomeState> emit) async {
    final workspacesOrFailed = await userService.getWorkspaces();
    emit(workspacesOrFailed.fold(
      (workspaces) => state.copyWith(workspaces: workspaces, successOrFailure: left(unit)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    ));
  }

  Future<void> _openWorkspace(Workspace workspace, Emitter<WelcomeState> emit) async {
    final result = await userService.openWorkspace(workspace.id);
    emit(result.fold(
      (workspaces) => state.copyWith(successOrFailure: left(unit)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    ));
  }

  Future<void> _createWorkspace(String name, String desc, Emitter<WelcomeState> emit) async {
    final result = await userService.createWorkspace(name, desc);
    emit(result.fold(
      (workspace) {
        return state.copyWith(successOrFailure: left(unit));
      },
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    ));
  }
}

@freezed
class WelcomeEvent with _$WelcomeEvent {
  const factory WelcomeEvent.initial() = Initial;
  // const factory WelcomeEvent.fetchWorkspaces() = FetchWorkspace;
  const factory WelcomeEvent.createWorkspace(String name, String desc) = CreateWorkspace;
  const factory WelcomeEvent.openWorkspace(Workspace workspace) = OpenWorkspace;
  const factory WelcomeEvent.workspacesReveived(Either<List<Workspace>, FlowyError> workspacesOrFail) =
      WorkspacesReceived;
}

@freezed
class WelcomeState with _$WelcomeState {
  const factory WelcomeState({
    required bool isLoading,
    required List<Workspace> workspaces,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _WelcomeState;

  factory WelcomeState.initial() => WelcomeState(
        isLoading: false,
        workspaces: List.empty(),
        successOrFailure: left(unit),
      );
}
