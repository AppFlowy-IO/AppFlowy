import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/core/notification/user_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/notification.pb.dart'
    as user;
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flutter/foundation.dart';

typedef DidUpdateUserWorkspaceCallback = void Function(
  UserWorkspacePB workspace,
);
typedef DidUpdateUserWorkspacesCallback = void Function(
  RepeatedUserWorkspacePB workspaces,
);
typedef UserProfileNotifyValue = FlowyResult<UserProfilePB, FlowyError>;
typedef DidUpdateUserWorkspaceSetting = void Function(
  WorkspaceSettingsPB settings,
);

class UserListener {
  UserListener({
    required UserProfilePB userProfile,
  }) : _userProfile = userProfile;

  final UserProfilePB _userProfile;

  UserNotificationParser? _userParser;
  StreamSubscription<SubscribeObject>? _subscription;
  PublishNotifier<UserProfileNotifyValue>? _profileNotifier = PublishNotifier();

  /// Update notification about _all_ of the users workspaces
  ///
  DidUpdateUserWorkspacesCallback? onUserWorkspaceListUpdated;

  /// Update notification about _one_ workspace
  ///
  DidUpdateUserWorkspaceCallback? onUserWorkspaceUpdated;
  DidUpdateUserWorkspaceSetting? onUserWorkspaceSettingUpdated;
  DidUpdateUserWorkspaceCallback? onUserWorkspaceOpened;
  void start({
    void Function(UserProfileNotifyValue)? onProfileUpdated,
    DidUpdateUserWorkspacesCallback? onUserWorkspaceListUpdated,
    void Function(UserWorkspacePB)? onUserWorkspaceUpdated,
    DidUpdateUserWorkspaceSetting? onUserWorkspaceSettingUpdated,
  }) {
    if (onProfileUpdated != null) {
      _profileNotifier?.addPublishListener(onProfileUpdated);
    }

    this.onUserWorkspaceListUpdated = onUserWorkspaceListUpdated;
    this.onUserWorkspaceUpdated = onUserWorkspaceUpdated;
    this.onUserWorkspaceSettingUpdated = onUserWorkspaceSettingUpdated;
    _userParser = UserNotificationParser(
      id: _userProfile.id.toString(),
      callback: _userNotificationCallback,
    );
    _subscription = RustStreamReceiver.listen((observable) {
      _userParser?.parse(observable);
    });
  }

  Future<void> stop() async {
    _userParser = null;
    await _subscription?.cancel();
    _profileNotifier?.dispose();
    _profileNotifier = null;
  }

  void _userNotificationCallback(
    user.UserNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case user.UserNotification.DidUpdateUserProfile:
        result.fold(
          (payload) => _profileNotifier?.value =
              FlowyResult.success(UserProfilePB.fromBuffer(payload)),
          (error) => _profileNotifier?.value = FlowyResult.failure(error),
        );
        break;
      case user.UserNotification.DidUpdateUserWorkspaces:
        result.map(
          (r) {
            final value = RepeatedUserWorkspacePB.fromBuffer(r);
            onUserWorkspaceListUpdated?.call(value);
          },
        );
        break;
      case user.UserNotification.DidUpdateUserWorkspace:
        result.map(
          (r) => onUserWorkspaceUpdated?.call(UserWorkspacePB.fromBuffer(r)),
        );
      case user.UserNotification.DidUpdateWorkspaceSetting:
        result.map(
          (r) => onUserWorkspaceSettingUpdated
              ?.call(WorkspaceSettingsPB.fromBuffer(r)),
        );
        break;
      case user.UserNotification.DidOpenWorkspace:
        result.fold(
          (payload) => _profileNotifier?.value =
              FlowyResult.success(UserProfilePB.fromBuffer(payload)),
          (error) => _profileNotifier?.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }
}

typedef WorkspaceLatestNotifyValue = FlowyResult<WorkspaceLatestPB, FlowyError>;

class FolderListener {
  FolderListener({
    required this.workspaceId,
  });

  final String workspaceId;

  final PublishNotifier<WorkspaceLatestNotifyValue> _latestChangedNotifier =
      PublishNotifier();

  FolderNotificationListener? _listener;

  void start({
    void Function(WorkspaceLatestNotifyValue)? onLatestUpdated,
  }) {
    if (onLatestUpdated != null) {
      _latestChangedNotifier.addPublishListener(onLatestUpdated);
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
      case FolderNotification.DidUpdateWorkspaceSetting:
        result.fold(
          (payload) => _latestChangedNotifier.value =
              FlowyResult.success(WorkspaceLatestPB.fromBuffer(payload)),
          (error) => _latestChangedNotifier.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _latestChangedNotifier.dispose();
  }
}
