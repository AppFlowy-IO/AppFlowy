import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'settings_user_bloc.freezed.dart';

class SettingsUserViewBloc extends Bloc<SettingsUserEvent, SettingsUserState> {
  final UserService _userService;
  final UserListener _userListener;
  final UserProfile userProfile;

  SettingsUserViewBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userService = UserService(userId: userProfile.id),
        super(SettingsUserState.initial(userProfile)) {
    on<SettingsUserEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
          await _initUser();
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
    super.close();
  }

  Future<void> _initUser() async {
    final result = await _userService.initUser();
    result.fold((l) => null, (error) => Log.error(error));
  }

  void _profileUpdated(Either<UserProfile, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (newUserProfile) => add(SettingsUserEvent.didReceiveUserProfile(newUserProfile)),
      (err) => Log.error(err),
    );
  }
}

@freezed
class SettingsUserEvent with _$SettingsUserEvent {
  const factory SettingsUserEvent.initial() = _Initial;
  const factory SettingsUserEvent.updateUserName(String name) = _UpdateUserName;
  const factory SettingsUserEvent.didReceiveUserProfile(UserProfile newUserProfile) = _DidReceiveUserProfile;
}

@freezed
class SettingsUserState with _$SettingsUserState {
  const factory SettingsUserState({
    required UserProfile userProfile,
    required Either<Unit, String> successOrFailure,
  }) = _SettingsUserState;

  factory SettingsUserState.initial(UserProfile userProfile) => SettingsUserState(
        userProfile: userProfile,
        successOrFailure: left(unit),
      );
}
