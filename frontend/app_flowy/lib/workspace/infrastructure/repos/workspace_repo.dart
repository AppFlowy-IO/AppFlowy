import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/workspace_query.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/observable.pb.dart';
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
            return right(WorkspaceError.create()..msg = LocaleKeys.workspace_notFoundError.tr());
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

  void _handleObservableType(WorkspaceNotification ty, Either<Uint8List, WorkspaceError> result) {
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
