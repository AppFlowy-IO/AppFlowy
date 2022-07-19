import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfilePB;
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';

typedef AppListNotifyValue = Either<List<AppPB>, FlowyError>;
typedef WorkspaceNotifyValue = Either<WorkspacePB, FlowyError>;

class WorkspaceListener {
  PublishNotifier<AppListNotifyValue>? _appsChangedNotifier = PublishNotifier();
  PublishNotifier<WorkspaceNotifyValue>? _workspaceUpdatedNotifier = PublishNotifier();

  FolderNotificationListener? _listener;
  final UserProfilePB user;
  final String workspaceId;

  WorkspaceListener({
    required this.user,
    required this.workspaceId,
  });

  void start({
    void Function(AppListNotifyValue)? appsChanged,
    void Function(WorkspaceNotifyValue)? onWorkspaceUpdated,
  }) {
    if (appsChanged != null) {
      _appsChangedNotifier?.addPublishListener(appsChanged);
    }

    if (onWorkspaceUpdated != null) {
      _workspaceUpdatedNotifier?.addPublishListener(onWorkspaceUpdated);
    }

    _listener = FolderNotificationListener(
      objectId: workspaceId,
      handler: _handleObservableType,
    );
  }

  void _handleObservableType(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.WorkspaceUpdated:
        result.fold(
          (payload) => _workspaceUpdatedNotifier?.value = left(WorkspacePB.fromBuffer(payload)),
          (error) => _workspaceUpdatedNotifier?.value = right(error),
        );
        break;
      case FolderNotification.WorkspaceAppsChanged:
        result.fold(
          (payload) => _appsChangedNotifier?.value = left(RepeatedAppPB.fromBuffer(payload).items),
          (error) => _appsChangedNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _appsChangedNotifier?.dispose();
    _appsChangedNotifier = null;

    _workspaceUpdatedNotifier?.dispose();
    _workspaceUpdatedNotifier = null;
  }
}
