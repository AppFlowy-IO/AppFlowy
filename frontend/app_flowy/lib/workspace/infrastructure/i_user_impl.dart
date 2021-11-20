import 'dart:typed_data';

import 'package:app_flowy/workspace/infrastructure/repos/helper.dart';
import 'package:dartz/dartz.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-dart-notify/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/errors.pb.dart';
// import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart' as user_error;
import 'package:flowy_sdk/protobuf/flowy-user/observable.pb.dart' as user;
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/workspace_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/observable.pb.dart';
export 'package:app_flowy/workspace/domain/i_user.dart';
export 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'dart:async';

class IUserImpl extends IUser {
  UserRepo repo;
  IUserImpl({
    required this.repo,
  });

  @override
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId) {
    return repo.deleteWorkspace(workspaceId: workspaceId);
  }

  @override
  Future<Either<UserProfile, UserError>> fetchUserProfile(String userId) {
    return repo.fetchUserProfile(userId: userId);
  }

  @override
  Future<Either<Unit, UserError>> signOut() {
    return repo.signOut();
  }

  @override
  UserProfile get user => repo.user;

  @override
  Future<Either<List<Workspace>, WorkspaceError>> fetchWorkspaces() {
    return repo.getWorkspaces();
  }

  @override
  Future<Either<Unit, UserError>> initUser() {
    return repo.initUser();
  }
}

class IUserListenerImpl extends IUserListener {
  StreamSubscription<SubscribeObject>? _subscription;

  @override
  final profileUpdatedNotifier = PublishNotifier<UserProfileUpdatedNotifierValue>();

  @override
  final authDidChangedNotifier = PublishNotifier<AuthNotifierValue>();

  @override
  final workspaceUpdatedNotifier = PublishNotifier<WorkspaceUpdatedNotifierValue>();

  late WorkspaceNotificationParser _workspaceParser;
  late UserNotificationParser _userParser;
  late UserProfile _user;
  IUserListenerImpl({
    required UserProfile user,
  }) {
    _user = user;
  }

  @override
  void start() {
    _workspaceParser = WorkspaceNotificationParser(id: _user.token, callback: _notificationCallback);
    _userParser = UserNotificationParser(id: _user.token, callback: _userNotificationCallback);
    _subscription = RustStreamReceiver.listen((observable) {
      _workspaceParser.parse(observable);
      _userParser.parse(observable);
    });
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
  }

  void _notificationCallback(WorkspaceNotification ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case WorkspaceNotification.UserCreateWorkspace:
      case WorkspaceNotification.UserDeleteWorkspace:
      case WorkspaceNotification.WorkspaceListUpdated:
        result.fold(
          (payload) => workspaceUpdatedNotifier.value = left(RepeatedWorkspace.fromBuffer(payload).items),
          (error) => workspaceUpdatedNotifier.value = right(error),
        );
        break;
      case WorkspaceNotification.UserUnauthorized:
        result.fold(
          (_) {},
          (error) => authDidChangedNotifier.value = right(UserError.create()..code = ErrorCode.UserUnauthorized.value),
        );
        break;
      default:
        break;
    }
  }

  void _userNotificationCallback(user.UserNotification ty, Either<Uint8List, UserError> result) {
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
