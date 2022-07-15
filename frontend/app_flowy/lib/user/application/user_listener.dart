import 'dart:async';
import 'package:app_flowy/core/folder_notification.dart';
import 'package:app_flowy/core/user_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error-code/code.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'dart:typed_data';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/dart_notification.pb.dart' as user;
import 'package:flowy_sdk/rust_stream.dart';

typedef UserProfileNotifyValue = Either<UserProfile, FlowyError>;
typedef AuthNotifyValue = Either<Unit, FlowyError>;

class UserListener {
  StreamSubscription<SubscribeObject>? _subscription;
  PublishNotifier<AuthNotifyValue>? _authNotifier = PublishNotifier();
  PublishNotifier<UserProfileNotifyValue>? _profileNotifier = PublishNotifier();

  UserNotificationParser? _userParser;
  final UserProfile _userProfile;
  UserListener({
    required UserProfile userProfile,
  }) : _userProfile = userProfile;

  void start({
    void Function(AuthNotifyValue)? onAuthChanged,
    void Function(UserProfileNotifyValue)? onProfileUpdated,
  }) {
    if (onProfileUpdated != null) {
      _profileNotifier?.addPublishListener(onProfileUpdated);
    }

    if (onAuthChanged != null) {
      _authNotifier?.addPublishListener(onAuthChanged);
    }

    _userParser = UserNotificationParser(id: _userProfile.token, callback: _userNotificationCallback);
    _subscription = RustStreamReceiver.listen((observable) {
      _userParser?.parse(observable);
    });
  }

  Future<void> stop() async {
    _userParser = null;
    await _subscription?.cancel();
    _profileNotifier?.dispose();
    _profileNotifier = null;

    _authNotifier?.dispose();
    _authNotifier = null;
  }

  void _userNotificationCallback(user.UserNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case user.UserNotification.UserUnauthorized:
        result.fold(
          (_) {},
          (error) => _authNotifier?.value = right(error),
        );
        break;
      case user.UserNotification.UserProfileUpdated:
        result.fold(
          (payload) => _profileNotifier?.value = left(UserProfile.fromBuffer(payload)),
          (error) => _profileNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }
}

typedef WorkspaceListNotifyValue = Either<List<Workspace>, FlowyError>;
typedef WorkspaceSettingNotifyValue = Either<CurrentWorkspaceSetting, FlowyError>;

class UserWorkspaceListener {
  PublishNotifier<AuthNotifyValue>? _authNotifier = PublishNotifier();
  PublishNotifier<WorkspaceListNotifyValue>? _workspacesChangedNotifier = PublishNotifier();
  PublishNotifier<WorkspaceSettingNotifyValue>? _settingChangedNotifier = PublishNotifier();

  FolderNotificationListener? _listener;
  final UserProfile _userProfile;

  UserWorkspaceListener({
    required UserProfile userProfile,
  }) : _userProfile = userProfile;

  void start({
    void Function(AuthNotifyValue)? onAuthChanged,
    void Function(WorkspaceListNotifyValue)? onWorkspacesUpdated,
    void Function(WorkspaceSettingNotifyValue)? onSettingUpdated,
  }) {
    if (onAuthChanged != null) {
      _authNotifier?.addPublishListener(onAuthChanged);
    }

    if (onWorkspacesUpdated != null) {
      _workspacesChangedNotifier?.addPublishListener(onWorkspacesUpdated);
    }

    if (onSettingUpdated != null) {
      _settingChangedNotifier?.addPublishListener(onSettingUpdated);
    }

    _listener = FolderNotificationListener(
      objectId: _userProfile.token,
      handler: _handleObservableType,
    );
  }

  void _handleObservableType(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.UserCreateWorkspace:
      case FolderNotification.UserDeleteWorkspace:
      case FolderNotification.WorkspaceListUpdated:
        result.fold(
          (payload) => _workspacesChangedNotifier?.value = left(RepeatedWorkspace.fromBuffer(payload).items),
          (error) => _workspacesChangedNotifier?.value = right(error),
        );
        break;
      case FolderNotification.WorkspaceSetting:
        result.fold(
          (payload) => _settingChangedNotifier?.value = left(CurrentWorkspaceSetting.fromBuffer(payload)),
          (error) => _settingChangedNotifier?.value = right(error),
        );
        break;
      case FolderNotification.UserUnauthorized:
        result.fold(
          (_) {},
          (error) => _authNotifier?.value = right(FlowyError.create()..code = ErrorCode.UserUnauthorized.value),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _workspacesChangedNotifier?.dispose();
    _workspacesChangedNotifier = null;

    _settingChangedNotifier?.dispose();
    _settingChangedNotifier = null;

    _authNotifier?.dispose();
    _authNotifier = null;
  }
}
