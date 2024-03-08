import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_error_bloc.freezed.dart';

class WorkspaceErrorBloc
    extends Bloc<WorkspaceErrorEvent, WorkspaceErrorState> {
  WorkspaceErrorBloc({required this.userFolder, required FlowyError error})
      : super(WorkspaceErrorState.initial(error)) {
    _dispatch();
  }

  final UserFolderPB userFolder;

  void _dispatch() {
    on<WorkspaceErrorEvent>(
      (event, emit) async {
        await event.when(
          init: () {
            // _loadSnapshots();
          },
          resetWorkspace: () async {
            emit(state.copyWith(loadingState: const LoadingState.loading()));
            final payload = ResetWorkspacePB.create()
              ..workspaceId = userFolder.workspaceId
              ..uid = userFolder.uid;
            final result = await UserEventResetWorkspace(payload).send();
            if (!isClosed) {
              add(WorkspaceErrorEvent.didResetWorkspace(result));
            }
          },
          didResetWorkspace: (result) {
            result.fold(
              (_) {
                emit(
                  state.copyWith(
                    loadingState: LoadingState.finish(result),
                    workspaceState: const WorkspaceState.reset(),
                  ),
                );
              },
              (err) {
                emit(state.copyWith(loadingState: LoadingState.finish(result)));
              },
            );
          },
          logout: () {
            emit(
              state.copyWith(
                workspaceState: const WorkspaceState.logout(),
              ),
            );
          },
        );
      },
    );
  }
}

@freezed
class WorkspaceErrorEvent with _$WorkspaceErrorEvent {
  const factory WorkspaceErrorEvent.init() = _Init;
  const factory WorkspaceErrorEvent.logout() = _DidLogout;
  const factory WorkspaceErrorEvent.resetWorkspace() = _ResetWorkspace;
  const factory WorkspaceErrorEvent.didResetWorkspace(
    FlowyResult<void, FlowyError> result,
  ) = _DidResetWorkspace;
}

@freezed
class WorkspaceErrorState with _$WorkspaceErrorState {
  const factory WorkspaceErrorState({
    required FlowyError initialError,
    LoadingState? loadingState,
    required WorkspaceState workspaceState,
  }) = _WorkspaceErrorState;

  factory WorkspaceErrorState.initial(FlowyError error) => WorkspaceErrorState(
        initialError: error,
        workspaceState: const WorkspaceState.initial(),
      );
}

@freezed
class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState.initial() = _Initial;
  const factory WorkspaceState.logout() = _Logout;
  const factory WorkspaceState.reset() = _Reset;
  const factory WorkspaceState.createNewWorkspace() = _NewWorkspace;
  const factory WorkspaceState.restoreFromSnapshot() = _RestoreFromSnapshot;
}
