import 'dart:async';

import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

class WorkspaceRepo {
  UserDetail user;
  WorkspaceRepo({
    required this.user,
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

  Future<Either<Workspace, WorkspaceError>> getWorkspace(
      {bool readApps = false}) {
    final request = QueryWorkspaceRequest.create()
      ..workspaceId = user.workspace
      ..user_id = user.id
      ..readApps = readApps;

    return WorkspaceEventReadWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
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
  final UserDetail user;
  late WorkspaceRepo _repo;

  WorkspaceWatchRepo({
    required this.user,
  }) {
    _repo = WorkspaceRepo(user: user);
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
      if (observable.subjectId != user.workspace) {
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
        _repo.getWorkspace(readApps: true).then((result) {
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
        _repo.getWorkspace(readApps: true).then((result) {
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
