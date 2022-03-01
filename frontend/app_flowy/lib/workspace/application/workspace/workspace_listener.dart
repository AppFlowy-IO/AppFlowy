import 'dart:async';
import 'dart:typed_data';

import 'package:app_flowy/core/notification_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';


typedef WorkspaceAppsChangedCallback = void Function(Either<List<App>, FlowyError> appsOrFail);
typedef WorkspaceUpdatedCallback = void Function(String name, String desc);

class WorkspaceListener {
  WorkspaceListenerService service;
  WorkspaceListener({
    required this.service,
  });

  void start({WorkspaceAppsChangedCallback? addAppCallback, WorkspaceUpdatedCallback? updatedCallback}) {
    service.startListening(appsChanged: addAppCallback, update: updatedCallback);
  }

  Future<void> stop() async {
    await service.close();
  }
}


class WorkspaceListenerService {
  StreamSubscription<SubscribeObject>? _subscription;
  WorkspaceAppsChangedCallback? _appsChanged;
  WorkspaceUpdatedCallback? _update;
  late FolderNotificationParser _parser;
  final UserProfile user;
  final String workspaceId;

  WorkspaceListenerService({
    required this.user,
    required this.workspaceId,
  });

  void startListening({
    WorkspaceAppsChangedCallback? appsChanged,
    WorkspaceUpdatedCallback? update,
  }) {
    _appsChanged = appsChanged;
    _update = update;

    _parser = FolderNotificationParser(
      id: workspaceId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.WorkspaceUpdated:
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
      case FolderNotification.WorkspaceAppsChanged:
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
    // _appsChanged = null;
    // _update = null;
  }
}
