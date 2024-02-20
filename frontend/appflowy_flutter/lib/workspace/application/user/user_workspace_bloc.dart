import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_workspace_bloc.freezed.dart';

class UserWorkspaceBloc extends Bloc<UserWorkspaceEvent, UserWorkspaceState> {
  UserWorkspaceBloc({
    required this.userProfile,
  })  : _userService = UserBackendService(userId: userProfile.id),
        super(UserWorkspaceState.initial()) {
    on<UserWorkspaceEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            await _fetchCurrentWorkspace(emit);
            await _fetchWorkspaces(emit);
          },
          createWorkspace: (e) async {
            await _createWorkspace(e.name, e.desc, emit);
          },
          workspacesReceived: (e) async {
            emit(
              e.workspacesOrFail.fold(
                (workspaces) => state.copyWith(
                  workspaces: workspaces,
                  successOrFailure: left(unit),
                ),
                (error) => state.copyWith(successOrFailure: right(error)),
              ),
            );
          },
        );
      },
    );
  }

  final UserProfilePB userProfile;
  final UserBackendService _userService;

  Future<void> _fetchCurrentWorkspace(Emitter<UserWorkspaceState> emit) async {
    final currentWorkspace = await _userService.getCurrentWorkspace();
    emit(
      currentWorkspace.fold(
        (workspace) => state.copyWith(
          currentWorkspace: workspace,
          successOrFailure: left(unit),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _fetchWorkspaces(Emitter<UserWorkspaceState> emit) async {
    final workspacesOrFailed = await _userService.getWorkspaces();
    emit(
      workspacesOrFailed.fold(
        (workspaces) => state.copyWith(
          workspaces: workspaces,
          successOrFailure: left(unit),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _createWorkspace(
    String name,
    String desc,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _userService.createUserWorkspace(name);
    emit(
      result.fold(
        (workspace) {
          return state.copyWith(successOrFailure: left(unit));
        },
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }
}

@freezed
class UserWorkspaceEvent with _$UserWorkspaceEvent {
  const factory UserWorkspaceEvent.initial() = Initial;
  const factory UserWorkspaceEvent.createWorkspace(String name, String desc) =
      CreateWorkspace;
  const factory UserWorkspaceEvent.workspacesReceived(
    Either<List<UserWorkspacePB>, FlowyError> workspacesOrFail,
  ) = WorkspacesReceived;
}

@freezed
class UserWorkspaceState with _$UserWorkspaceState {
  const factory UserWorkspaceState({
    required bool isLoading,
    required WorkspacePB? currentWorkspace,
    required List<UserWorkspacePB> workspaces,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _UserWorkspaceState;

  factory UserWorkspaceState.initial() => UserWorkspaceState(
        isLoading: false,
        currentWorkspace: null,
        workspaces: [],
        successOrFailure: left(unit),
      );
}
