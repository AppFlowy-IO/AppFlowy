import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_dialog_bloc.freezed.dart';

enum SettingsPage {
  // NEW
  account,
  workspace,
  manageData,
  shortcuts,
  ai,
  plan,
  billing,
  // OLD
  notifications,
  cloud,
  member,
  featureFlags,
}

class SettingsDialogBloc
    extends Bloc<SettingsDialogEvent, SettingsDialogState> {
  SettingsDialogBloc(
    this.userProfile, {
    SettingsPage? initPage,
  })  : _userListener = UserListener(userProfile: userProfile),
        super(SettingsDialogState.initial(userProfile, initPage)) {
    _dispatch();
  }

  final UserProfilePB userProfile;
  final UserListener _userListener;

  @override
  Future<void> close() async {
    await _userListener.stop();
    await super.close();
  }

  void _dispatch() {
    on<SettingsDialogEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _userListener.start(onProfileUpdated: _profileUpdated);
          },
          didReceiveUserProfile: (UserProfilePB newUserProfile) {
            emit(state.copyWith(userProfile: newUserProfile));
          },
          setSelectedPage: (SettingsPage page) {
            emit(state.copyWith(page: page));
          },
        );
      },
    );
  }

  void _profileUpdated(
    FlowyResult<UserProfilePB, FlowyError> userProfileOrFailed,
  ) {
    userProfileOrFailed.fold(
      (newUserProfile) =>
          add(SettingsDialogEvent.didReceiveUserProfile(newUserProfile)),
      (err) => Log.error(err),
    );
  }
}

@freezed
class SettingsDialogEvent with _$SettingsDialogEvent {
  const factory SettingsDialogEvent.initial() = _Initial;
  const factory SettingsDialogEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
  const factory SettingsDialogEvent.setSelectedPage(SettingsPage page) =
      _SetViewIndex;
}

@freezed
class SettingsDialogState with _$SettingsDialogState {
  const factory SettingsDialogState({
    required UserProfilePB userProfile,
    required SettingsPage page,
  }) = _SettingsDialogState;

  factory SettingsDialogState.initial(
    UserProfilePB userProfile,
    SettingsPage? page,
  ) =>
      SettingsDialogState(
        userProfile: userProfile,
        page: page ?? SettingsPage.account,
      );
}
