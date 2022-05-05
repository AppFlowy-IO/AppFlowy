import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/dart_notification.pb.dart' as user;
import 'package:flowy_sdk/rust_stream.dart';

typedef UserProfileDidUpdate = Either<UserProfile, FlowyError>;
typedef AuthDidUpdate = Either<Unit, FlowyError>;
typedef WorkspaceListDidUpdate = Either<List<Workspace>, FlowyError>;
typedef WorkspaceSettingDidUpdate = Either<CurrentWorkspaceSetting, FlowyError>;

class UserListener {
  StreamSubscription<SubscribeObject>? _subscription;
  final _profileNotifier = PublishNotifier<UserProfileDidUpdate>();
  final _authNotifier = PublishNotifier<AuthDidUpdate>();
  final _workspaceListNotifier = PublishNotifier<WorkspaceListDidUpdate>();
  final _workSettingNotifier = PublishNotifier<WorkspaceSettingDidUpdate>();

  FolderNotificationParser? _workspaceParser;
  UserNotificationParser? _userParser;
  final UserProfile _user;
  UserListener({
    required UserProfile user,
  }) : _user = user;

  void start({
    void Function(AuthDidUpdate)? authDidChange,
    void Function(UserProfileDidUpdate)? profileDidUpdate,
    void Function(WorkspaceListDidUpdate)? workspaceListDidUpdate,
    void Function(WorkspaceSettingDidUpdate)? workspaceSettingDidUpdate,
  }) {
    if (authDidChange != null) {
      _authNotifier.addListener(() {
        authDidChange(_authNotifier.currentValue!);
      });
    }

    if (profileDidUpdate != null) {
      _profileNotifier.addListener(() {
        profileDidUpdate(_profileNotifier.currentValue!);
      });
    }

    if (workspaceListDidUpdate != null) {
      _workspaceListNotifier.addListener(() {
        workspaceListDidUpdate(_workspaceListNotifier.currentValue!);
      });
    }

    if (workspaceSettingDidUpdate != null) {
      _workSettingNotifier.addListener(() {
        workspaceSettingDidUpdate(_workSettingNotifier.currentValue!);
      });
    }

    _workspaceParser = FolderNotificationParser(id: _user.token, callback: _notificationCallback);
    _userParser = UserNotificationParser(id: _user.token, callback: _userNotificationCallback);
    _subscription = RustStreamReceiver.listen((observable) {
      _workspaceParser?.parse(observable);
      _userParser?.parse(observable);
    });
  }

  Future<void> stop() async {
    _workspaceParser = null;
    _userParser = null;
    await _subscription?.cancel();
    _profileNotifier.dispose();
    _authNotifier.dispose();
    _workspaceListNotifier.dispose();
  }

  void _notificationCallback(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.UserCreateWorkspace:
      case FolderNotification.UserDeleteWorkspace:
      case FolderNotification.WorkspaceListUpdated:
        result.fold(
          (payload) => _workspaceListNotifier.value = left(RepeatedWorkspace.fromBuffer(payload).items),
          (error) => _workspaceListNotifier.value = right(error),
        );
        break;
      case FolderNotification.WorkspaceSetting:
        result.fold(
          (payload) => _workSettingNotifier.value = left(CurrentWorkspaceSetting.fromBuffer(payload)),
          (error) => _workSettingNotifier.value = right(error),
        );
        break;
      case FolderNotification.UserUnauthorized:
        result.fold(
          (_) {},
          (error) => _authNotifier.value = right(FlowyError.create()..code = ErrorCode.UserUnauthorized.value),
        );
        break;

      default:
        break;
    }
  }

  void _userNotificationCallback(user.UserNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case user.UserNotification.UserUnauthorized:
        result.fold(
          (payload) => _profileNotifier.value = left(UserProfile.fromBuffer(payload)),
          (error) => _profileNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }
}
