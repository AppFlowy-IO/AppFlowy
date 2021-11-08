import 'dart:typed_data';

import 'package:app_flowy/workspace/infrastructure/repos/helper.dart';
import 'package:dartz/dartz.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
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
  WorkspacesUpdatedCallback? _workspacesUpdated;
  AuthChangedCallback? _authChanged;
  UserProfileUpdateCallback? _profileUpdated;

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

  @override
  void setAuthCallback(AuthChangedCallback authCallback) {
    _authChanged = authCallback;
  }

  @override
  void setProfileCallback(UserProfileUpdateCallback profileCallback) {
    _profileUpdated = profileCallback;
  }

  @override
  void setWorkspacesCallback(WorkspacesUpdatedCallback workspacesCallback) {
    _workspacesUpdated = workspacesCallback;
  }

  void _notificationCallback(WorkspaceNotification ty, Either<Uint8List, WorkspaceError> result) {
    switch (ty) {
      case WorkspaceNotification.UserCreateWorkspace:
      case WorkspaceNotification.UserDeleteWorkspace:
      case WorkspaceNotification.WorkspaceListUpdated:
        if (_workspacesUpdated != null) {
          result.fold(
            (payload) {
              final workspaces = RepeatedWorkspace.fromBuffer(payload);
              _workspacesUpdated!(left(workspaces.items));
            },
            (error) => _workspacesUpdated!(right(error)),
          );
        }
        break;
      case WorkspaceNotification.UserUnauthorized:
        if (_authChanged != null) {
          result.fold(
            (_) {},
            (error) => {_authChanged!(right(UserError.create()..code = ErrorCode.UserUnauthorized.value))},
          );
        }
        break;
      default:
        break;
    }
  }

  void _userNotificationCallback(user.UserNotification ty, Either<Uint8List, UserError> result) {
    switch (ty) {
      case user.UserNotification.UserUnauthorized:
        if (_profileUpdated != null) {
          result.fold(
            (payload) {
              final userProfile = UserProfile.fromBuffer(payload);
              _profileUpdated!(left(userProfile));
            },
            (error) => _profileUpdated!(right(error)),
          );
        }
        break;
      default:
        break;
    }
  }
}
