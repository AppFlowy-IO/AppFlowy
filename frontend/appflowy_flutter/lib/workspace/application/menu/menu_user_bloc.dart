import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'menu_user_bloc.freezed.dart';

class MenuUserBloc extends Bloc<MenuUserEvent, MenuUserState> {
  final UserBackendService _userService;
  final UserListener _userListener;
  final UserWorkspaceListener _userWorkspaceListener;
  final UserProfilePB userProfile;

  MenuUserBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userWorkspaceListener =
            UserWorkspaceListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(MenuUserState.initial(userProfile)) {
    on<MenuUserEvent>((final event, final emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
          _userWorkspaceListener.start(
            onWorkspacesUpdated: _workspaceListUpdated,
          );
          await _initUser();
        },
        fetchWorkspaces: () async {
          //
        },
        didReceiveUserProfile: (final UserProfilePB newUserProfile) {
          emit(state.copyWith(userProfile: newUserProfile));
        },
        updateUserName: (final String name) {
          _userService.updateUserProfile(name: name).then((final result) {
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
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
    result.fold((final l) => null, (final error) => Log.error(error));
  }

  void _profileUpdated(final Either<UserProfilePB, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (final newUserProfile) =>
          add(MenuUserEvent.didReceiveUserProfile(newUserProfile)),
      (final err) => Log.error(err),
    );
  }

  void _workspaceListUpdated(
    final Either<List<WorkspacePB>, FlowyError> workspacesOrFailed,
  ) {
    // Do nothing by now
  }
}

@freezed
class MenuUserEvent with _$MenuUserEvent {
  const factory MenuUserEvent.initial() = _Initial;
  const factory MenuUserEvent.fetchWorkspaces() = _FetchWorkspaces;
  const factory MenuUserEvent.updateUserName(final String name) = _UpdateUserName;
  const factory MenuUserEvent.didReceiveUserProfile(
    final UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
}

@freezed
class MenuUserState with _$MenuUserState {
  const factory MenuUserState({
    required final UserProfilePB userProfile,
    required final Option<List<WorkspacePB>> workspaces,
    required final Either<Unit, String> successOrFailure,
  }) = _MenuUserState;

  factory MenuUserState.initial(final UserProfilePB userProfile) => MenuUserState(
        userProfile: userProfile,
        workspaces: none(),
        successOrFailure: left(unit),
      );
}
