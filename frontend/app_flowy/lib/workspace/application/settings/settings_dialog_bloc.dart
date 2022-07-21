import 'package:app_flowy/user/application/user_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'settings_dialog_bloc.freezed.dart';

class SettingsDialogBloc extends Bloc<SettingsDialogEvent, SettingsDialogState> {
  final UserListener _userListener;
  final UserProfile userProfile;

  SettingsDialogBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        super(SettingsDialogState.initial(userProfile)) {
    on<SettingsDialogEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
        },
        didReceiveUserProfile: (UserProfile newUserProfile) {
          emit(state.copyWith(userProfile: newUserProfile));
        },
        setViewIndex: (int viewIndex) {
          emit(state.copyWith(viewIndex: viewIndex));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _userListener.stop();
    super.close();
  }

  void _profileUpdated(Either<UserProfile, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (newUserProfile) => add(SettingsDialogEvent.didReceiveUserProfile(newUserProfile)),
      (err) => Log.error(err),
    );
  }
}

@freezed
class SettingsDialogEvent with _$SettingsDialogEvent {
  const factory SettingsDialogEvent.initial() = _Initial;
  const factory SettingsDialogEvent.didReceiveUserProfile(UserProfile newUserProfile) = _DidReceiveUserProfile;
  const factory SettingsDialogEvent.setViewIndex(int index) = _SetViewIndex;
}

@freezed
class SettingsDialogState with _$SettingsDialogState {
  const factory SettingsDialogState({
    required UserProfile userProfile,
    required Either<Unit, String> successOrFailure,
    required int viewIndex,
  }) = _SettingsDialogState;

  factory SettingsDialogState.initial(UserProfile userProfile) => SettingsDialogState(
        userProfile: userProfile,
        successOrFailure: left(unit),
        viewIndex: 0,
      );
}
