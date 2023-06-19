import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';

typedef AppListNotifyValue = Either<List<ViewPB>, FlowyError>;
typedef WorkspaceNotifyValue = Either<WorkspacePB, FlowyError>;

class WorkspaceListener {
  PublishNotifier<AppListNotifyValue>? _appsChangedNotifier = PublishNotifier();
  PublishNotifier<WorkspaceNotifyValue>? _workspaceUpdatedNotifier =
      PublishNotifier();

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

  void _handleObservableType(
    FolderNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateWorkspace:
        result.fold(
          (payload) => _workspaceUpdatedNotifier?.value =
              left(WorkspacePB.fromBuffer(payload)),
          (error) => _workspaceUpdatedNotifier?.value = right(error),
        );
        break;
      case FolderNotification.DidUpdateWorkspaceViews:
        result.fold(
          (payload) => _appsChangedNotifier?.value =
              left(RepeatedViewPB.fromBuffer(payload).items),
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
