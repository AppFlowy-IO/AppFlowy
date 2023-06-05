import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'settings_user_bloc.freezed.dart';

class SettingsUserViewBloc extends Bloc<SettingsUserEvent, SettingsUserState> {
  final UserBackendService _userService;
  final UserListener _userListener;
  final UserProfilePB userProfile;

  SettingsUserViewBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(SettingsUserState.initial(userProfile)) {
    on<SettingsUserEvent>((final event, final emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
          await _initUser();
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
        updateUserIcon: (final String iconUrl) {
          _userService.updateUserProfile(iconUrl: iconUrl).then((final result) {
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          });
        },
        updateUserOpenAIKey: (final openAIKey) {
          _userService.updateUserProfile(openAIKey: openAIKey).then((final result) {
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
    super.close();
  }

  Future<void> _initUser() async {
    final result = await _userService.initUser();
    result.fold((final l) => null, (final error) => Log.error(error));
  }

  void _profileUpdated(final Either<UserProfilePB, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (final newUserProfile) =>
          add(SettingsUserEvent.didReceiveUserProfile(newUserProfile)),
      (final err) => Log.error(err),
    );
  }
}

@freezed
class SettingsUserEvent with _$SettingsUserEvent {
  const factory SettingsUserEvent.initial() = _Initial;
  const factory SettingsUserEvent.updateUserName(final String name) = _UpdateUserName;
  const factory SettingsUserEvent.updateUserIcon(final String iconUrl) =
      _UpdateUserIcon;
  const factory SettingsUserEvent.updateUserOpenAIKey(final String openAIKey) =
      _UpdateUserOpenaiKey;
  const factory SettingsUserEvent.didReceiveUserProfile(
    final UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
}

@freezed
class SettingsUserState with _$SettingsUserState {
  const factory SettingsUserState({
    required final UserProfilePB userProfile,
    required final Either<Unit, String> successOrFailure,
  }) = _SettingsUserState;

  factory SettingsUserState.initial(final UserProfilePB userProfile) =>
      SettingsUserState(
        userProfile: userProfile,
        successOrFailure: left(unit),
      );
}
