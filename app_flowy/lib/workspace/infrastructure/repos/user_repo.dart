import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';

class UserRepo {
  final UserDetail user;
  UserRepo({
    required this.user,
  });

  Future<Either<UserDetail, UserError>> fetchUserDetail(
      {required String userId}) {
    return UserEventGetStatus().send();
  }

  Future<Either<Unit, WorkspaceError>> deleteWorkspace(
      {required String workspaceId}) {
    throw UnimplementedError();
  }

  Future<Either<Unit, UserError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces() {
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
  UserCreateWorkspaceCallback? _createWorkspace;
  UserDeleteWorkspaceCallback? _deleteWorkspace;
  late UserRepo _repo;
  UserWatchRepo({
    required UserDetail user,
  }) {
    _repo = UserRepo(user: user);
  }

  void startWatching(
      {UserCreateWorkspaceCallback? createWorkspace,
      UserDeleteWorkspaceCallback? deleteWorkspace}) {
    _createWorkspace = createWorkspace;
    _deleteWorkspace = deleteWorkspace;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != _repo.user.id) {
        return;
      }

      final ty = WorkspaceObservable.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }

  void _handleObservableType(WorkspaceObservable ty) {
    switch (ty) {
      case WorkspaceObservable.UserCreateWorkspace:
        if (_createWorkspace == null) {
          return;
        }
        _repo.fetchWorkspaces().then((result) {
          result.fold(
            (workspaces) => _createWorkspace!(left(workspaces)),
            (error) => _createWorkspace!(right(error)),
          );
        });
        break;
      case WorkspaceObservable.UserDeleteWorkspace:
        if (_deleteWorkspace == null) {
          return;
        }
        _repo.fetchWorkspaces().then((result) {
          result.fold(
            (workspaces) => _deleteWorkspace!(left(workspaces)),
            (error) => _deleteWorkspace!(right(error)),
          );
        });
        break;

      default:
        break;
    }
  }
}
