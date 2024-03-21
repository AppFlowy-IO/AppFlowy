import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef RootViewsNotifyValue = FlowyResult<List<ViewPB>, FlowyError>;
typedef WorkspaceNotifyValue = FlowyResult<WorkspacePB, FlowyError>;

/// The [WorkspaceListener] listens to the changes including the below:
///
/// - The root views of the workspace. (Not including the views are inside the root views)
/// - The workspace itself.
class WorkspaceListener {
  WorkspaceListener({required this.user, required this.workspaceId});

  final UserProfilePB user;
  final String workspaceId;

  PublishNotifier<RootViewsNotifyValue>? _appsChangedNotifier =
      PublishNotifier();
  PublishNotifier<WorkspaceNotifyValue>? _workspaceUpdatedNotifier =
      PublishNotifier();

  FolderNotificationListener? _listener;

  void start({
    void Function(RootViewsNotifyValue)? appsChanged,
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
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateWorkspace:
        result.fold(
          (payload) => _workspaceUpdatedNotifier?.value =
              FlowyResult.success(WorkspacePB.fromBuffer(payload)),
          (error) =>
              _workspaceUpdatedNotifier?.value = FlowyResult.failure(error),
        );
        break;
      case FolderNotification.DidUpdateWorkspaceViews:
        result.fold(
          (payload) => _appsChangedNotifier?.value =
              FlowyResult.success(RepeatedViewPB.fromBuffer(payload).items),
          (error) => _appsChangedNotifier?.value = FlowyResult.failure(error),
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
