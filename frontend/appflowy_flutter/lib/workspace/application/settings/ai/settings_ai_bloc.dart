import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ai_bloc.freezed.dart';

class SettingsAIBloc extends Bloc<SettingsAIEvent, SettingsAIState> {
  SettingsAIBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(SettingsAIState(userProfile: userProfile)) {
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
    on<SettingsAIEvent>((event, emit) {
      event.when(
        started: () {
          _userListener.start(onProfileUpdated: _onProfileUpdated);
        },
        didReceiveUserProfile: (userProfile) =>
            emit(state.copyWith(userProfile: userProfile)),
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
      );
    });
  }

  void _onProfileUpdated(
    FlowyResult<UserProfilePB, FlowyError> userProfileOrFailed,
  ) =>
      userProfileOrFailed.fold(
        (newUserProfile) =>
            add(SettingsAIEvent.didReceiveUserProfile(newUserProfile)),
        (err) => Log.error(err),
      );
}

@freezed
class SettingsAIEvent with _$SettingsAIEvent {
  const factory SettingsAIEvent.started() = _Started;

  const factory SettingsAIEvent.updateUserOpenAIKey(String openAIKey) =
      _UpdateUserOpenaiKey;

  const factory SettingsAIEvent.updateUserStabilityAIKey(
    String stabilityAIKey,
  ) = _UpdateUserStabilityAIKey;

  const factory SettingsAIEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
}

@freezed
class SettingsAIState with _$SettingsAIState {
  const factory SettingsAIState({
    required UserProfilePB userProfile,
  }) = _SettingsAIState;
}
