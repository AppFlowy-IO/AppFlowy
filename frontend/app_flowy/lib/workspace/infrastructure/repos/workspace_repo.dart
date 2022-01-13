import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-core-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/domain/i_workspace.dart';

import 'helper.dart';

class WorkspaceRepo {
  UserProfile user;
  String workspaceId;
  WorkspaceRepo({
    required this.user,
    required this.workspaceId,
  });

  Future<Either<App, FlowyError>> createApp(String appName, String desc) {
    final request = CreateAppRequest.create()
      ..name = appName
      ..workspaceId = workspaceId
      ..desc = desc;
    return WorkspaceEventCreateApp(request).send();
  }

  Future<Either<Workspace, FlowyError>> getWorkspace() {
    final request = QueryWorkspaceRequest.create()..workspaceId = workspaceId;
    return WorkspaceEventReadWorkspaces(request).send().then((result) {
      return result.fold(
        (workspaces) {
          assert(workspaces.items.length == 1);

          if (workspaces.items.isEmpty) {
            return right(FlowyError.create()..msg = LocaleKeys.workspace_notFoundError.tr());
          } else {
            return left(workspaces.items[0]);
          }
        },
        (error) => right(error),
      );
    });
  }

  Future<Either<List<App>, FlowyError>> getApps() {
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
  StreamSubscription<SubscribeObject>? _subscription;
  WorkspaceAppsChangedCallback? _appsChanged;
  WorkspaceUpdatedCallback? _update;
  late WorkspaceNotificationParser _parser;
  final UserProfile user;
  final String workspaceId;

  WorkspaceListenerRepo({
    required this.user,
    required this.workspaceId,
  });

  void startListening({
    WorkspaceAppsChangedCallback? appsChanged,
    WorkspaceUpdatedCallback? update,
  }) {
    _appsChanged = appsChanged;
    _update = update;

    _parser = WorkspaceNotificationParser(
      id: workspaceId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(WorkspaceNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case WorkspaceNotification.WorkspaceUpdated:
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
      case WorkspaceNotification.WorkspaceAppsChanged:
        if (_appsChanged != null) {
          result.fold(
            (payload) => _appsChanged!(
              left(RepeatedApp.fromBuffer(payload).items),
            ),
            (error) => _appsChanged!(right(error)),
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
