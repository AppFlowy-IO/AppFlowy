import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_user_bloc.freezed.dart';

class SettingsUserViewBloc extends Bloc<SettingsUserEvent, SettingsUserState> {
  final UserBackendService _userService;
  final UserListener _userListener;
  final UserProfilePB userProfile;

  SettingsUserViewBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(SettingsUserState.initial(userProfile)) {
    on<SettingsUserEvent>((event, emit) async {
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
        updateUserOpenAIKey: (openAIKey) {
          _userService.updateUserProfile(openAIKey: openAIKey).then((result) {
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          });
        },
        updateUserStabilityAIKey: (stabilityAIKey) {
          _userService
              .updateUserProfile(stabilityAiKey: stabilityAIKey)
              .then((result) {
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          });
        },
        didLoadHistoricalUsers: (List<HistoricalUserPB> historicalUsers) {
          emit(state.copyWith(historicalUsers: historicalUsers));
        },
        openHistoricalUser: (HistoricalUserPB historicalUser) async {
          await UserBackendService.openHistoricalUser(historicalUser);
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
    });
  }

  @override
  Future<void> close() async {
    await _userListener.stop();
    super.close();
  }

  void _loadUserProfile() {
    UserBackendService.getCurrentUserProfile().then((result) {
      if (isClosed) {
        return;
      }

      result.fold(
        (err) => Log.error(err),
        (userProfile) => add(
          SettingsUserEvent.didReceiveUserProfile(userProfile),
        ),
      );
    });
  }

  void _profileUpdated(Either<UserProfilePB, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (newUserProfile) {
        add(SettingsUserEvent.didReceiveUserProfile(newUserProfile));
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class SettingsUserEvent with _$SettingsUserEvent {
  const factory SettingsUserEvent.initial() = _Initial;
  const factory SettingsUserEvent.updateUserName(String name) = _UpdateUserName;
  const factory SettingsUserEvent.updateUserEmail(String email) = _UpdateEmail;
  const factory SettingsUserEvent.updateUserIcon({required String iconUrl}) =
      _UpdateUserIcon;
  const factory SettingsUserEvent.removeUserIcon() = _RemoveUserIcon;
  const factory SettingsUserEvent.updateUserOpenAIKey(String openAIKey) =
      _UpdateUserOpenaiKey;
  const factory SettingsUserEvent.updateUserStabilityAIKey(
    String stabilityAIKey,
  ) = _UpdateUserStabilityAIKey;
  const factory SettingsUserEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
  const factory SettingsUserEvent.didLoadHistoricalUsers(
    List<HistoricalUserPB> historicalUsers,
  ) = _DidLoadHistoricalUsers;
  const factory SettingsUserEvent.openHistoricalUser(
    HistoricalUserPB historicalUser,
  ) = _OpenHistoricalUser;
}

@freezed
class SettingsUserState with _$SettingsUserState {
  const factory SettingsUserState({
    required UserProfilePB userProfile,
    required List<HistoricalUserPB> historicalUsers,
    required Either<Unit, String> successOrFailure,
  }) = _SettingsUserState;

  factory SettingsUserState.initial(UserProfilePB userProfile) =>
      SettingsUserState(
        userProfile: userProfile,
        historicalUsers: [],
        successOrFailure: left(unit),
      );
}
