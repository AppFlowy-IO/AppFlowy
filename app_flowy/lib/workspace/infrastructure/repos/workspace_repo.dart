import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_query.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/workspace/domain/i_workspace.dart';

import 'helper.dart';

class WorkspaceRepo {
  UserProfile user;
  String workspaceId;
  WorkspaceRepo({
    required this.user,
    required this.workspaceId,
  });

  Future<Either<App, WorkspaceError>> createApp(String appName, String desc) {
    final request = CreateAppRequest.create()
      ..name = appName
      ..workspaceId = workspaceId
      ..desc = desc;
    return WorkspaceEventCreateApp(request).send();
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

  Future<Either<List<App>, WorkspaceError>> getApps() {
    final request = QueryWorkspaceRequest.create()..workspaceId = workspaceId;
    return WorkspaceEventReadWorkspaceApps(request).send().then((result) {
      return result.fold(
        (apps) => left(apps.items),
        (error) => right(error),
      );
    });
  }
}

class WorkspaceListenerRepo {
  StreamSubscription<ObservableSubject>? _subscription;
  WorkspaceCreateAppCallback? _createApp;
  WorkspaceDeleteAppCallback? _deleteApp;
  WorkspaceUpdatedCallback? _update;
  late WorkspaceNotificationParser _extractor;
  final UserProfile user;
  final String workspaceId;

  WorkspaceListenerRepo({
    required this.user,
    required this.workspaceId,
  });

  void startListen({
    WorkspaceCreateAppCallback? createApp,
    WorkspaceDeleteAppCallback? deleteApp,
    WorkspaceUpdatedCallback? update,
  }) {
    _createApp = createApp;
    _deleteApp = deleteApp;
    _update = update;

    _extractor = WorkspaceNotificationParser(
      id: workspaceId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _extractor.parse(observable));
  }

  void _handleObservableType(Notification ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case Notification.WorkspaceUpdated:
        if (_update != null) {
          result.fold(
            (payload) {
              final workspace = Workspace.fromBuffer(payload);
              _update!(workspace.name, workspace.desc);
            },
            (error) => Log.error(error),
          );
        }
        break;
      case Notification.WorkspaceCreateApp:
        if (_createApp != null) {
          result.fold(
            (payload) => _createApp!(
              left(RepeatedApp.fromBuffer(payload).items),
            ),
            (error) => _createApp!(right(error)),
          );
        }
        break;
      case Notification.WorkspaceDeleteApp:
        if (_deleteApp != null) {
          result.fold(
            (payload) => _deleteApp!(
              left(RepeatedApp.fromBuffer(payload).items),
            ),
            (error) => _deleteApp!(right(error)),
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
