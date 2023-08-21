import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_error_bloc.freezed.dart';

class WorkspaceErrorBloc
    extends Bloc<WorkspaceErrorEvent, WorkspaceErrorState> {
  final UserFolderPB userFolder;

  WorkspaceErrorBloc({
    required this.userFolder,
    required FlowyError error,
  }) : super(WorkspaceErrorState.initial(error)) {
    on<WorkspaceErrorEvent>((event, emit) async {
      await event.when(
        init: () {
          _loadSnapshots();
        },
        didLoadSnapshots: (List<FolderSnapshotPB> snapshots) {
          emit(state.copyWith(snapshots: snapshots));
        },
        resetWorkspace: () async {
          final payload = ResetWorkspacePB.create()
            ..workspaceId = userFolder.workspaceId
            ..uid = userFolder.uid;
          final result = await UserEventResetWorkspace(payload).send();
          result.fold(
            (l) => emit(
              state.copyWith(workspaceState: const WorkspaceState.reset()),
            ),
            (r) => Log.error(r),
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
    });
  }

  void _loadSnapshots() {
    final payload = WorkspaceIdPB.create()..value = userFolder.workspaceId;
    FolderEventGetFolderSnapshots(payload).send().then((result) {
      result.fold(
        (snapshots) {
          if (isClosed) {
            return;
          }

          add(WorkspaceErrorEvent.didLoadSnapshots(snapshots.items));
        },
        (err) => Log.error(err),
      );
    });
  }

  bool isLoading() {
    final loadingState = state.loadingState;
    if (loadingState != null) {
      return loadingState.when(loading: () => true, finish: (_) => false);
    }
    return false;
  }
}

@freezed
class WorkspaceErrorEvent with _$WorkspaceErrorEvent {
  const factory WorkspaceErrorEvent.init() = _Init;
  const factory WorkspaceErrorEvent.logout() = _DidLogout;

  const factory WorkspaceErrorEvent.didLoadSnapshots(
    List<FolderSnapshotPB> snapshots,
  ) = _DidLoadSnapshots;

  const factory WorkspaceErrorEvent.resetWorkspace() = _ResetWorkspace;
}

@freezed
class WorkspaceErrorState with _$WorkspaceErrorState {
  const factory WorkspaceErrorState({
    required FlowyError initialError,
    LoadingState? loadingState,
    required WorkspaceState workspaceState,
    required List<FolderSnapshotPB> snapshots,
  }) = _WorkspaceErrorState;

  factory WorkspaceErrorState.initial(FlowyError error) => WorkspaceErrorState(
        initialError: error,
        workspaceState: const WorkspaceState.initial(),
        snapshots: [],
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
