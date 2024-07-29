import 'package:flutter/foundation.dart';

import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
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
    this.userProfile,
    this.workspaceMember, {
    SettingsPage? initPage,
  })  : _userListener = UserListener(userProfile: userProfile),
        super(SettingsDialogState.initial(userProfile, initPage)) {
    _dispatch();
  }

  final UserProfilePB userProfile;
  final WorkspaceMemberPB? workspaceMember;
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

            final isBillingEnabled =
                await _isBillingEnabled(userProfile, workspaceMember);
            if (isBillingEnabled) {
              emit(state.copyWith(isBillingEnabled: true));
            }
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

  Future<bool> _isBillingEnabled(
    UserProfilePB userProfile, [
    WorkspaceMemberPB? member,
  ]) async {
    if ([
      AuthenticatorPB.Local,
      AuthenticatorPB.Supabase,
    ].contains(userProfile.authenticator)) {
      return false;
    }

    if (member == null || member.role != AFRolePB.Owner) {
      return false;
    }

    if (kDebugMode) {
      return true;
    }

    final result = await UserEventGetCloudConfig().send();
    return result.fold(
      (cloudSetting) {
        final whiteList = [
          "https://beta.appflowy.cloud",
          "https://test.appflowy.cloud",
        ];
        if (kDebugMode) {
          whiteList.add("http://localhost:8000");
        }

        return whiteList.contains(cloudSetting.serverUrl);
      },
      (err) {
        Log.error("Failed to get cloud config: $err");
        return false;
      },
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
    required bool isBillingEnabled,
  }) = _SettingsDialogState;

  factory SettingsDialogState.initial(
    UserProfilePB userProfile,
    SettingsPage? page,
  ) =>
      SettingsDialogState(
        userProfile: userProfile,
        page: page ?? SettingsPage.account,
        isBillingEnabled: false,
      );
}
