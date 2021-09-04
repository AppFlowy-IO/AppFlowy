import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/workspace/domain/i_workspace.dart';

class WorkspaceRepo {
  UserProfile user;
  String workspaceId;
  WorkspaceRepo({
    required this.user,
    required this.workspaceId,
  });

  Future<Either<App, WorkspaceError>> createApp(String appName, String desc) {
    return WorkspaceEventReadCurWorkspace().send().then((result) {
      return result.fold(
        (workspace) {
          final request = CreateAppRequest.create()
            ..name = appName
            ..workspaceId = workspace.id
            ..desc = desc;
          return WorkspaceEventCreateApp(request).send();
        },
        (error) {
          return right(error);
        },
      );
    });
  }

  Future<Either<Workspace, WorkspaceError>> getWorkspace() {
    final request = QueryWorkspaceRequest.create()..workspaceId = workspaceId;

    return WorkspaceEventReadWorkspaces(request).send().then((result) {
      return result.fold(
        (workspaces) {
          assert(workspaces.items.length == 1);

          if (workspaces.items.isEmpty) {
            return right(WorkspaceError.create()..msg = "Workspace not found");
          } else {
            return left(workspaces.items[0]);
          }
        },
        (error) => right(error),
      );
    });
  }
}

class WorkspaceWatchRepo {
  StreamSubscription<ObservableSubject>? _subscription;
  WorkspaceCreateAppCallback? _createApp;
  WorkspaceDeleteAppCallback? _deleteApp;
  WorkspaceUpdatedCallback? _update;
  final UserProfile user;
  final String workspaceId;
  late WorkspaceRepo _repo;

  WorkspaceWatchRepo({
    required this.user,
    required this.workspaceId,
  }) {
    _repo = WorkspaceRepo(user: user, workspaceId: workspaceId);
  }

  void startWatching({
    WorkspaceCreateAppCallback? createApp,
    WorkspaceDeleteAppCallback? deleteApp,
    WorkspaceUpdatedCallback? update,
  }) {
    _createApp = createApp;
    _deleteApp = deleteApp;
    _update = update;

    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != workspaceId) {
        return;
      }

      final ty = WorkspaceObservable.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }

  void _handleObservableType(WorkspaceObservable ty) {
    switch (ty) {
      case WorkspaceObservable.WorkspaceUpdated:
        if (_update == null) {
          return;
        }
        _repo.getWorkspace().then((result) {
          result.fold(
            (workspace) => _update!(workspace.name, workspace.desc),
            (error) => Log.error(error),
          );
        });
        break;
      case WorkspaceObservable.WorkspaceCreateApp:
        if (_createApp == null) {
          return;
        }

        _repo.getWorkspace().then((result) {
          result.fold(
            (workspace) => _createApp!(left(workspace.apps.items)),
            (error) => _createApp!(right(error)),
          );
        });

        break;
      case WorkspaceObservable.WorkspaceDeleteApp:
        if (_deleteApp == null) {
          return;
        }
        _repo.getWorkspace().then((result) {
          result.fold(
            (workspace) => _deleteApp!(left(workspace.apps.items)),
            (error) => _deleteApp!(right(error)),
          );
        });
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
