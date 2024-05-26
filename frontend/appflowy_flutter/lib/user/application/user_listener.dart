import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/core/notification/user_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/notification.pb.dart'
    as user;
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef DidUpdateUserWorkspaceCallback = void Function(
  UserWorkspacePB workspace,
);
typedef DidUpdateUserWorkspacesCallback = void Function(
  RepeatedUserWorkspacePB workspaces,
);
typedef UserProfileNotifyValue = FlowyResult<UserProfilePB, FlowyError>;

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
  DidUpdateUserWorkspacesCallback? didUpdateUserWorkspaces;

  /// Update notification about _one_ workspace
  ///
  DidUpdateUserWorkspaceCallback? didUpdateUserWorkspace;

  void start({
    void Function(UserProfileNotifyValue)? onProfileUpdated,
    void Function(RepeatedUserWorkspacePB)? didUpdateUserWorkspaces,
    void Function(UserWorkspacePB)? didUpdateUserWorkspace,
  }) {
    if (onProfileUpdated != null) {
      _profileNotifier?.addPublishListener(onProfileUpdated);
    }

    if (didUpdateUserWorkspaces != null) {
      this.didUpdateUserWorkspaces = didUpdateUserWorkspaces;
    }

    if (didUpdateUserWorkspace != null) {
      this.didUpdateUserWorkspace = didUpdateUserWorkspace;
    }

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
            didUpdateUserWorkspaces?.call(value);
          },
        );
        break;
      case user.UserNotification.DidUpdateUserWorkspace:
        result.map(
          (r) => didUpdateUserWorkspace?.call(UserWorkspacePB.fromBuffer(r)),
        );
        break;
      default:
        break;
    }
  }
}

typedef WorkspaceSettingNotifyValue
    = FlowyResult<WorkspaceSettingPB, FlowyError>;

class UserWorkspaceListener {
  UserWorkspaceListener();

  final PublishNotifier<WorkspaceSettingNotifyValue> _settingChangedNotifier =
      PublishNotifier();

  FolderNotificationListener? _listener;

  void start({
    void Function(WorkspaceSettingNotifyValue)? onSettingUpdated,
  }) {
    if (onSettingUpdated != null) {
      _settingChangedNotifier.addPublishListener(onSettingUpdated);
    }

    // The "current-workspace" is predefined in the backend. Do not try to
    // modify it
    _listener = FolderNotificationListener(
      objectId: "current-workspace",
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
          (payload) => _settingChangedNotifier.value =
              FlowyResult.success(WorkspaceSettingPB.fromBuffer(payload)),
          (error) => _settingChangedNotifier.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _settingChangedNotifier.dispose();
  }
}
