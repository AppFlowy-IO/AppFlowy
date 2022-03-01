import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'dart:typed_data';
import 'package:app_flowy/workspace/infrastructure/repos/helper.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/dart_notification.pb.dart' as user;
import 'package:flowy_sdk/rust_stream.dart';


typedef UserProfileUpdatedNotifierValue = Either<UserProfile, FlowyError>;
typedef AuthNotifierValue = Either<Unit, FlowyError>;
typedef WorkspaceUpdatedNotifierValue = Either<List<Workspace>, FlowyError>;

class UserListener {
  StreamSubscription<SubscribeObject>? _subscription;
  final profileUpdatedNotifier = PublishNotifier<UserProfileUpdatedNotifierValue>();
  final authDidChangedNotifier = PublishNotifier<AuthNotifierValue>();
  final workspaceUpdatedNotifier = PublishNotifier<WorkspaceUpdatedNotifierValue>();

  late FolderNotificationParser _workspaceParser;
  late UserNotificationParser _userParser;
  late UserProfile _user;
  UserListener({
    required UserProfile user,
  }) {
    _user = user;
  }

  void start() {
    _workspaceParser = FolderNotificationParser(id: _user.token, callback: _notificationCallback);
    _userParser = UserNotificationParser(id: _user.token, callback: _userNotificationCallback);
    _subscription = RustStreamReceiver.listen((observable) {
      _workspaceParser.parse(observable);
      _userParser.parse(observable);
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    profileUpdatedNotifier.dispose();
    authDidChangedNotifier.dispose();
    workspaceUpdatedNotifier.dispose();
  }

  void _notificationCallback(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.UserCreateWorkspace:
      case FolderNotification.UserDeleteWorkspace:
      case FolderNotification.WorkspaceListUpdated:
        result.fold(
          (payload) => workspaceUpdatedNotifier.value = left(RepeatedWorkspace.fromBuffer(payload).items),
          (error) => workspaceUpdatedNotifier.value = right(error),
        );
        break;
      case FolderNotification.UserUnauthorized:
        result.fold(
          (_) {},
          (error) => authDidChangedNotifier.value = right(FlowyError.create()..code = ErrorCode.UserUnauthorized.value),
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
          (payload) => profileUpdatedNotifier.value = left(UserProfile.fromBuffer(payload)),
          (error) => profileUpdatedNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }
}
