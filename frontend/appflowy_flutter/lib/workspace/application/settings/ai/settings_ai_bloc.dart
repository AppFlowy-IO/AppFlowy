import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ai_bloc.freezed.dart';

class SettingsAIBloc extends Bloc<SettingsAIEvent, SettingsAIState> {
  SettingsAIBloc(this.userProfile)
      : _userListener = UserListener(userProfile: userProfile),
        super(SettingsAIState(userProfile: userProfile)) {
    _dispatch();
  }

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
          _userListener.start(
            onProfileUpdated: _onProfileUpdated,
            onUserWorkspaceSettingUpdated: (settings) {
              if (!isClosed) {
                add(SettingsAIEvent.didLoadAISetting(settings));
              }
            },
          );
          _loadUserWorkspaceSetting();
        },
        didReceiveUserProfile: (userProfile) {
          emit(state.copyWith(userProfile: userProfile));
        },
        toggleAISearch: () {
          _updateUserWorkspaceSetting(
            disableSearchIndexing:
                !(state.aiSettings?.disableSearchIndexing ?? false),
          );
        },
        selectModel: (AIModelPB model) {
          _updateUserWorkspaceSetting(model: model);
        },
        didLoadAISetting: (UseAISettingPB settings) {
          emit(
            state.copyWith(
              aiSettings: settings,
              enableSearchIndexing: !settings.disableSearchIndexing,
            ),
          );
        },
      );
    });
  }

  void _updateUserWorkspaceSetting({
    bool? disableSearchIndexing,
    AIModelPB? model,
  }) {
    final payload = UpdateUserWorkspaceSettingPB(
      workspaceId: userProfile.workspaceId,
    );
    if (disableSearchIndexing != null) {
      payload.disableSearchIndexing = disableSearchIndexing;
    }
    if (model != null) {
      payload.aiModel = model;
    }
    UserEventUpdateWorkspaceSetting(payload).send();
  }

  void _onProfileUpdated(
    FlowyResult<UserProfilePB, FlowyError> userProfileOrFailed,
  ) =>
      userProfileOrFailed.fold(
        (profile) => add(SettingsAIEvent.didReceiveUserProfile(profile)),
        (err) => Log.error(err),
      );

  void _loadUserWorkspaceSetting() {
    final payload = UserWorkspaceIdPB(workspaceId: userProfile.workspaceId);
    UserEventGetWorkspaceSetting(payload).send().then((result) {
      result.fold((settings) {
        if (!isClosed) {
          add(SettingsAIEvent.didLoadAISetting(settings));
        }
      }, (err) {
        Log.error(err);
      });
    });
  }
}

@freezed
class SettingsAIEvent with _$SettingsAIEvent {
  const factory SettingsAIEvent.started() = _Started;
  const factory SettingsAIEvent.didLoadAISetting(
    UseAISettingPB settings,
  ) = _DidLoadWorkspaceSetting;

  const factory SettingsAIEvent.toggleAISearch() = _toggleAISearch;

  const factory SettingsAIEvent.selectModel(AIModelPB model) = _SelectAIModel;

  const factory SettingsAIEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;
}

@freezed
class SettingsAIState with _$SettingsAIState {
  const factory SettingsAIState({
    required UserProfilePB userProfile,
    UseAISettingPB? aiSettings,
    @Default(true) bool enableSearchIndexing,
  }) = _SettingsAIState;
}
