import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-observable/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

typedef AppUpdatedCallback = void Function(List<App> apps);

class WorkspaceRepository {
  StreamSubscription<ObservableSubject>? _subscription;
  AppUpdatedCallback? _appUpdatedCallback;
  String workspaceId;
  WorkspaceRepository({
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

  Future<Either<List<App>, WorkspaceError>> getApps(
      {required String workspaceId}) {
    final request = QueryWorkspaceRequest.create()
      ..workspaceId = workspaceId
      ..readApps = true;

    return WorkspaceEventGetWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace.apps.items),
        (error) => right(error),
      );
    });
  }

  void startWatching({AppUpdatedCallback? appUpdatedCallback}) {
    _appUpdatedCallback = appUpdatedCallback;
    _subscription = RustStreamReceiver.listen((observable) {
      if (observable.subjectId != workspaceId) {
        return;
      }

      final ty = WorkspaceObservableType.valueOf(observable.ty);
      if (ty != null) {
        _handleObservableType(ty);
      }
    });
  }

  void _handleObservableType(WorkspaceObservableType ty) {
    switch (ty) {
      case WorkspaceObservableType.WorkspaceUpdated:
        if (_appUpdatedCallback == null) {
          return;
        }
        getApps(workspaceId: workspaceId).then((result) {
          result.fold(
            (apps) => _appUpdatedCallback!(apps),
            (error) => Log.error(error),
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
