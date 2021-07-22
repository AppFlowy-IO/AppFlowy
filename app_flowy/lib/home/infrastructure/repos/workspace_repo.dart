import 'dart:async';

import 'package:app_flowy/home/domain/i_workspace.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

class WorkspaceRepo {
  String workspaceId;
  WorkspaceRepo({
    required this.workspaceId,
  });

  Future<Either<App, WorkspaceError>> createApp(String appName, String desc) {
    return WorkspaceEventGetCurWorkspace().send().then((result) {
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
      ..workspaceId = workspaceId
      ..readApps = readApps;

    return WorkspaceEventGetWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }
}

class WorkspaceWatchRepo {
  StreamSubscription<ObservableSubject>? _subscription;
  WorkspaceAddAppCallback? _addAppCallback;
  WorkspaceUpdatedCallback? _updatedCallback;
  final String workspaceId;
  late WorkspaceRepo _repo;

  WorkspaceWatchRepo({
    required this.workspaceId,
  }) {
    _repo = WorkspaceRepo(workspaceId: workspaceId);
  }

  void startWatching(
      {WorkspaceAddAppCallback? addAppCallback,
      WorkspaceUpdatedCallback? updatedCallback}) {
    _addAppCallback = addAppCallback;
    _updatedCallback = updatedCallback;

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
      case WorkspaceObservable.WorkspaceUpdateDesc:
        if (_updatedCallback == null) {
          return;
        }
        _repo.getWorkspace().then((result) {
          result.fold(
            (workspace) => _updatedCallback!(workspace.name, workspace.desc),
            (error) => Log.error(error),
          );
        });
        break;
      case WorkspaceObservable.WorkspaceAddApp:
        if (_addAppCallback == null) {
          return;
        }
        _repo.getWorkspace(readApps: true).then((result) {
          result.fold(
            (workspace) => _addAppCallback!(left(workspace.apps.items)),
            (error) => _addAppCallback!(right(error)),
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
