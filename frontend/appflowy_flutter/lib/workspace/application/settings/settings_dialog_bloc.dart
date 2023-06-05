import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'settings_dialog_bloc.freezed.dart';

enum SettingsPage {
  appearance,
  language,
  files,
  user,
}

class SettingsDialogBloc
    extends Bloc<SettingsDialogEvent, SettingsDialogState> {
  final UserListener _userListener;
  final UserProfilePB userProfile;

  SettingsDialogBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        super(SettingsDialogState.initial(userProfile)) {
    on<SettingsDialogEvent>((final event, final emit) async {
      await event.when(
        initial: () async {
          _userListener.start(onProfileUpdated: _profileUpdated);
        },
        didReceiveUserProfile: (final UserProfilePB newUserProfile) {
          emit(state.copyWith(userProfile: newUserProfile));
        },
        setSelectedPage: (final SettingsPage page) {
          emit(state.copyWith(page: page));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _userListener.stop();
    super.close();
  }

  void _profileUpdated(final Either<UserProfilePB, FlowyError> userProfileOrFailed) {
    userProfileOrFailed.fold(
      (final newUserProfile) =>
          add(SettingsDialogEvent.didReceiveUserProfile(newUserProfile)),
      (final err) => Log.error(err),
    );
  }
}

@freezed
class SettingsDialogEvent with _$SettingsDialogEvent {
  const factory SettingsDialogEvent.initial() = _Initial;
  const factory SettingsDialogEvent.didReceiveUserProfile(
    final UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
  const factory SettingsDialogEvent.setSelectedPage(final SettingsPage page) =
      _SetViewIndex;
}

@freezed
class SettingsDialogState with _$SettingsDialogState {
  const factory SettingsDialogState({
    required final UserProfilePB userProfile,
    required final Either<Unit, String> successOrFailure,
    required final SettingsPage page,
  }) = _SettingsDialogState;

  factory SettingsDialogState.initial(final UserProfilePB userProfile) =>
      SettingsDialogState(
        userProfile: userProfile,
        successOrFailure: left(unit),
        page: SettingsPage.appearance,
      );
}
