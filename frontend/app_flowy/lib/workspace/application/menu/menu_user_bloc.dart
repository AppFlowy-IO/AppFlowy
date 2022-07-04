import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'menu_user_bloc.freezed.dart';

class MenuUserBloc extends Bloc<MenuUserEvent, MenuUserState> {
  final UserService _userService;
  final UserListener _userListener;
  final UserWorkspaceListener _userWorkspaceListener;
  final UserProfile userProfile;

  MenuUserBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userWorkspaceListener = UserWorkspaceListener(userProfile: userProfile),
        _userService = UserService(userId: userProfile.id),
        super(MenuUserState.initial(userProfile)) {
    on<MenuUserEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
          _userWorkspaceListener.start(onWorkspacesUpdated: _workspaceListUpdated);
          await _initUser();
        },
        fetchWorkspaces: () async {
          //
        },
        didReceiveUserProfile: (UserProfile newUserProfile) {
          emit(state.copyWith(userProfile: newUserProfile));
        },
        updateUserName: (String name) {
          _userService.updateUserProfile(name: name).then((result) {
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          });
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _userListener.stop();
    await _userWorkspaceListener.stop();
    super.close();
  }

  Future<void> _initUser() async {
    final result = await _userService.initUser();
    result.fold((l) => null, (error) => Log.error(error));
  }

  void _profileUpdated(Either<UserProfile, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (newUserProfile) => add(MenuUserEvent.didReceiveUserProfile(newUserProfile)),
      (err) => Log.error(err),
    );
  }

  void _workspaceListUpdated(Either<List<Workspace>, FlowyError> workspacesOrFailed) {
    // Do nothing by now
  }
}

@freezed
class MenuUserEvent with _$MenuUserEvent {
  const factory MenuUserEvent.initial() = _Initial;
  const factory MenuUserEvent.fetchWorkspaces() = _FetchWorkspaces;
  const factory MenuUserEvent.updateUserName(String name) = _UpdateUserName;
  const factory MenuUserEvent.didReceiveUserProfile(UserProfile newUserProfile) = _DidReceiveUserProfile;
}

@freezed
class MenuUserState with _$MenuUserState {
  const factory MenuUserState({
    required UserProfile userProfile,
    required Option<List<Workspace>> workspaces,
    required Either<Unit, String> successOrFailure,
  }) = _MenuUserState;

  factory MenuUserState.initial(UserProfile userProfile) => MenuUserState(
        userProfile: userProfile,
        workspaces: none(),
        successOrFailure: left(unit),
      );
}
