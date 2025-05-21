import 'package:appflowy/plugins/ai_chat/application/ai_model_switch_listener.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ai_bloc.freezed.dart';

const String aiModelsGlobalActiveModel = "global_active_model";

class SettingsAIBloc extends Bloc<SettingsAIEvent, SettingsAIState> {
  SettingsAIBloc(
    this.userProfile,
    this.workspaceId,
  )   : _userListener = UserListener(userProfile: userProfile),
        _aiModelSwitchListener =
            AIModelSwitchListener(objectId: aiModelsGlobalActiveModel),
        super(
          SettingsAIState(
            userProfile: userProfile,
          ),
        ) {
    _aiModelSwitchListener.start(
      onUpdateSelectedModel: (model) {
        if (!isClosed) {
          _loadModelList();
        }
      },
    );
    _dispatch();
  }

  final UserListener _userListener;
  final UserProfilePB userProfile;
  final String workspaceId;
  final AIModelSwitchListener _aiModelSwitchListener;

  @override
  Future<void> close() async {
    await _userListener.stop();
    await _aiModelSwitchListener.stop();
    return super.close();
  }

  void _dispatch() {
    on<SettingsAIEvent>((event, emit) async {
      await event.when(
        started: () {
          _userListener.start(
            onProfileUpdated: _onProfileUpdated,
            onUserWorkspaceSettingUpdated: (settings) {
              if (!isClosed) {
                add(SettingsAIEvent.didLoadWorkspaceSetting(settings));
              }
            },
          );
          _loadModelList();
          _loadUserWorkspaceSetting();
        },
        didReceiveUserProfile: (userProfile) {
          emit(state.copyWith(userProfile: userProfile));
        },
        toggleAISearch: () {
          emit(
            state.copyWith(enableSearchIndexing: !state.enableSearchIndexing),
          );
          _updateUserWorkspaceSetting(
            disableSearchIndexing:
                !(state.aiSettings?.disableSearchIndexing ?? false),
          );
        },
        selectModel: (AIModelPB model) async {
          await AIEventUpdateSelectedModel(
            UpdateSelectedModelPB(
              source: aiModelsGlobalActiveModel,
              selectedModel: model,
            ),
          ).send();
        },
        didLoadWorkspaceSetting: (WorkspaceSettingsPB settings) {
          emit(
            state.copyWith(
              aiSettings: settings,
              enableSearchIndexing: !settings.disableSearchIndexing,
            ),
          );
        },
        didLoadAvailableModels: (ModelSelectionPB models) {
          emit(
            state.copyWith(
              availableModels: models,
            ),
          );
        },
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> _updateUserWorkspaceSetting({
    bool? disableSearchIndexing,
    String? model,
  }) async {
    final payload = UpdateUserWorkspaceSettingPB(
      workspaceId: workspaceId,
    );
    if (disableSearchIndexing != null) {
      payload.disableSearchIndexing = disableSearchIndexing;
    }
    if (model != null) {
      payload.aiModel = model;
    }
    final result = await UserEventUpdateWorkspaceSetting(payload).send();
    result.fold(
      (ok) => Log.info('Update workspace setting success'),
      (err) => Log.error('Update workspace setting failed: $err'),
    );
    return result;
  }

  void _onProfileUpdated(
    FlowyResult<UserProfilePB, FlowyError> userProfileOrFailed,
  ) =>
      userProfileOrFailed.fold(
        (profile) => add(SettingsAIEvent.didReceiveUserProfile(profile)),
        (err) => Log.error(err),
      );

  void _loadModelList() {
    final payload = ModelSourcePB(source: aiModelsGlobalActiveModel);
    AIEventGetSettingModelSelection(payload).send().then((result) {
      result.fold((models) {
        if (!isClosed) {
          add(SettingsAIEvent.didLoadAvailableModels(models));
        }
      }, (err) {
        Log.error(err);
      });
    });
  }

  void _loadUserWorkspaceSetting() {
    final payload = UserWorkspaceIdPB(workspaceId: workspaceId);
    UserEventGetWorkspaceSetting(payload).send().then((result) {
      result.fold((settings) {
        if (!isClosed) {
          add(SettingsAIEvent.didLoadWorkspaceSetting(settings));
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
  const factory SettingsAIEvent.didLoadWorkspaceSetting(
    WorkspaceSettingsPB settings,
  ) = _DidLoadWorkspaceSetting;

  const factory SettingsAIEvent.toggleAISearch() = _toggleAISearch;

  const factory SettingsAIEvent.selectModel(AIModelPB model) = _SelectAIModel;

  const factory SettingsAIEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;

  const factory SettingsAIEvent.didLoadAvailableModels(
    ModelSelectionPB models,
  ) = _DidLoadAvailableModels;
}

@freezed
class SettingsAIState with _$SettingsAIState {
  const factory SettingsAIState({
    required UserProfilePB userProfile,
    WorkspaceSettingsPB? aiSettings,
    ModelSelectionPB? availableModels,
    @Default(true) bool enableSearchIndexing,
  }) = _SettingsAIState;
}
