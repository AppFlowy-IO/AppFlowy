import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_user_bloc.freezed.dart';

class SettingsUserViewBloc extends Bloc<SettingsUserEvent, SettingsUserState> {
  SettingsUserViewBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(SettingsUserState.initial(userProfile)) {
    _dispatch();
  }

  final UserBackendService _userService;
  final UserListener _userListener;
  final UserProfilePB userProfile;

  @override
  Future<void> close() async {
    await _userListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<SettingsUserEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _loadUserProfile();
            _userListener.start(onProfileUpdated: _profileUpdated);
          },
          didReceiveUserProfile: (UserProfilePB newUserProfile) {
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
          updateUserIcon: (String iconUrl) {
            _userService.updateUserProfile(iconUrl: iconUrl).then((result) {
              result.fold(
                (l) => null,
                (err) => Log.error(err),
              );
            });
          },
          removeUserIcon: () {
            // Empty Icon URL = No icon
            _userService.updateUserProfile(iconUrl: "").then((result) {
              result.fold(
                (l) => null,
                (err) => Log.error(err),
              );
            });
          },
          updateUserEmail: (String email) {
            _userService.updateUserProfile(email: email).then((result) {
              result.fold(
                (l) => null,
                (err) => Log.error(err),
              );
            });
          },
        );
      },
    );
  }

  void _loadUserProfile() {
    UserBackendService.getCurrentUserProfile().then((result) {
      if (isClosed) {
        return;
      }

      result.fold(
        (userProfile) => add(
          SettingsUserEvent.didReceiveUserProfile(userProfile),
        ),
        (err) => Log.error(err),
      );
    });
  }

  void _profileUpdated(
    FlowyResult<UserProfilePB, FlowyError> userProfileOrFailed,
  ) =>
      userProfileOrFailed.fold(
        (newUserProfile) =>
            add(SettingsUserEvent.didReceiveUserProfile(newUserProfile)),
        (err) => Log.error(err),
      );
}

@freezed
class SettingsUserEvent with _$SettingsUserEvent {
  const factory SettingsUserEvent.initial() = _Initial;
  const factory SettingsUserEvent.updateUserName(String name) = _UpdateUserName;
  const factory SettingsUserEvent.updateUserEmail(String email) = _UpdateEmail;
  const factory SettingsUserEvent.updateUserIcon({required String iconUrl}) =
      _UpdateUserIcon;
  const factory SettingsUserEvent.removeUserIcon() = _RemoveUserIcon;
  const factory SettingsUserEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
}

@freezed
class SettingsUserState with _$SettingsUserState {
  const factory SettingsUserState({
    required UserProfilePB userProfile,
    required FlowyResult<void, String> successOrFailure,
  }) = _SettingsUserState;

  factory SettingsUserState.initial(UserProfilePB userProfile) =>
      SettingsUserState(
        userProfile: userProfile,
        successOrFailure: FlowyResult.success(null),
      );
}
