import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'dart:typed_data';
import 'package:app_flowy/workspace/infrastructure/repos/helper.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
// import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart' as user_error;
import 'package:flowy_sdk/protobuf/flowy-user/dart_notification.pb.dart' as user;
import 'package:flowy_sdk/rust_stream.dart';

class UserRepo {
  final UserProfile user;
  UserRepo({
    required this.user,
  });

  Future<Either<UserProfile, FlowyError>> fetchUserProfile({required String userId}) {
    return UserEventGetUserProfile().send();
  }

  Future<Either<Unit, FlowyError>> deleteWorkspace({required String workspaceId}) {
    throw UnimplementedError();
  }

  Future<Either<Unit, FlowyError>> signOut() {
    return UserEventSignOut().send();
  }

  Future<Either<Unit, FlowyError>> initUser() async {
    return UserEventInitUser().send();
  }

  Future<Either<List<Workspace>, FlowyError>> getWorkspaces() {
    final request = QueryWorkspaceRequest.create();

    return FolderEventReadWorkspaces(request).send().then((result) {
      return result.fold(
        (workspaces) => left(workspaces.items),
        (error) => right(error),
      );
    });
  }

  Future<Either<Workspace, FlowyError>> openWorkspace(String workspaceId) {
    final request = QueryWorkspaceRequest.create()..workspaceId = workspaceId;
    return FolderEventOpenWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }

  Future<Either<Workspace, FlowyError>> createWorkspace(String name, String desc) {
    final request = CreateWorkspaceRequest.create()
      ..name = name
      ..desc = desc;
    return FolderEventCreateWorkspace(request).send().then((result) {
      return result.fold(
        (workspace) => left(workspace),
        (error) => right(error),
      );
    });
  }
}

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
