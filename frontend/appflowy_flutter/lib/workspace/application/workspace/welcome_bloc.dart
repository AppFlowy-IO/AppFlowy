import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'welcome_bloc.freezed.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final UserBackendService userService;
  final UserWorkspaceListener userWorkspaceListener;
  WelcomeBloc({required this.userService, required this.userWorkspaceListener})
      : super(WelcomeState.initial()) {
    on<WelcomeEvent>(
      (final event, final emit) async {
        await event.map(
          initial: (final e) async {
            userWorkspaceListener.start(
              onWorkspacesUpdated: (final result) =>
                  add(WelcomeEvent.workspacesReveived(result)),
            );
            //
            await _fetchWorkspaces(emit);
          },
          openWorkspace: (final e) async {
            await _openWorkspace(e.workspace, emit);
          },
          createWorkspace: (final e) async {
            await _createWorkspace(e.name, e.desc, emit);
          },
          workspacesReveived: (final e) async {
            emit(
              e.workspacesOrFail.fold(
                (final workspaces) => state.copyWith(
                  workspaces: workspaces,
                  successOrFailure: left(unit),
                ),
                (final error) => state.copyWith(successOrFailure: right(error)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await userWorkspaceListener.stop();
    super.close();
  }

  Future<void> _fetchWorkspaces(final Emitter<WelcomeState> emit) async {
    final workspacesOrFailed = await userService.getWorkspaces();
    emit(
      workspacesOrFailed.fold(
        (final workspaces) => state.copyWith(
          workspaces: workspaces,
          successOrFailure: left(unit),
        ),
        (final error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _openWorkspace(
    final WorkspacePB workspace,
    final Emitter<WelcomeState> emit,
  ) async {
    final result = await userService.openWorkspace(workspace.id);
    emit(
      result.fold(
        (final workspaces) => state.copyWith(successOrFailure: left(unit)),
        (final error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  Future<void> _createWorkspace(
    final String name,
    final String desc,
    final Emitter<WelcomeState> emit,
  ) async {
    final result = await userService.createWorkspace(name, desc);
    emit(
      result.fold(
        (final workspace) {
          return state.copyWith(successOrFailure: left(unit));
        },
        (final error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }
}

@freezed
class WelcomeEvent with _$WelcomeEvent {
  const factory WelcomeEvent.initial() = Initial;
  // const factory WelcomeEvent.fetchWorkspaces() = FetchWorkspace;
  const factory WelcomeEvent.createWorkspace(final String name, final String desc) =
      CreateWorkspace;
  const factory WelcomeEvent.openWorkspace(final WorkspacePB workspace) =
      OpenWorkspace;
  const factory WelcomeEvent.workspacesReveived(
    final Either<List<WorkspacePB>, FlowyError> workspacesOrFail,
  ) = WorkspacesReceived;
}

@freezed
class WelcomeState with _$WelcomeState {
  const factory WelcomeState({
    required final bool isLoading,
    required final List<WorkspacePB> workspaces,
    required final Either<Unit, FlowyError> successOrFailure,
  }) = _WelcomeState;

  factory WelcomeState.initial() => WelcomeState(
        isLoading: false,
        workspaces: List.empty(),
        successOrFailure: left(unit),
      );
}
