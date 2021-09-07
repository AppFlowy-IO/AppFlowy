import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';

class UserRepo {
  final UserProfile user;
  UserRepo({
    required this.user,
  });

  Future<Either<UserProfile, UserError>> fetchUserProfile(
      {required String userId}) {
    return UserEventGetUserProfile().send();
  }

  Future<Either<Unit, WorkspaceError>> deleteWorkspace(
      {required String workspaceId}) {
    throw UnimplementedError();
  }

  Future<Either<Unit, UserError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<List<Workspace>, WorkspaceError>> getWorkspaces() {
    final request = QueryWorkspaceRequest.create();

    return WorkspaceEventReadWorkspaces(request).send().then((result) {
      return result.fold(
        (workspaces) => left(workspaces.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Workspace, WorkspaceError>> openWorkspace(String workspaceId) {
    final request = QueryWorkspaceRequest.create()..workspaceId = workspaceId;
    return WorkspaceEventOpenWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<Workspace, WorkspaceError>> createWorkspace(
      String name, String desc) {
    final request = CreateWorkspaceRequest.create()
      ..name = name
      ..desc = desc;
    return WorkspaceEventCreateWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }
}

class UserWatchRepo {
  StreamSubscription<ObservableSubject>? _subscription;
  WorkspaceListUpdatedCallback? _workspaceListUpdated;
  late UserRepo _repo;
  UserWatchRepo({
    required UserProfile user,
  }) {
    _repo = UserRepo(user: user);
  }

  void startWatching({WorkspaceListUpdatedCallback? workspaceListUpdated}) {
    _workspaceListUpdated = workspaceListUpdated;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.id != _repo.user.id) {
        return;
      }

      final ty = WorkspaceObservable.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty, Uint8List.fromList(observable.payload));
      }
    });
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }

  void _handleObservableType(WorkspaceObservable ty, Uint8List payload) {
    if (_workspaceListUpdated == null) {
      return;
    }

    switch (ty) {
      case WorkspaceObservable.UserCreateWorkspace:
      case WorkspaceObservable.UserDeleteWorkspace:
      case WorkspaceObservable.WorkspaceListUpdated:
        if (_workspaceListUpdated == null) {
          return;
        }

        final workspaces = RepeatedWorkspace.fromBuffer(payload);
        _workspaceListUpdated!(left(workspaces.items));

        break;
      default:
        break;
    }
  }
}
