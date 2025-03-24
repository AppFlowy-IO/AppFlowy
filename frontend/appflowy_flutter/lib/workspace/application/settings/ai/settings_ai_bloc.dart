import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ai_bloc.freezed.dart';
part 'settings_ai_bloc.g.dart';

class SettingsAIBloc extends Bloc<SettingsAIEvent, SettingsAIState> {
  SettingsAIBloc(
    this.userProfile,
    this.workspaceId,
    AFRolePB? currentWorkspaceMemberRole,
  )   : _userListener = UserListener(userProfile: userProfile),
        _userService = UserBackendService(userId: userProfile.id),
        super(
          SettingsAIState(
            selectedAIModel: userProfile.aiModel,
            userProfile: userProfile,
            currentWorkspaceMemberRole: currentWorkspaceMemberRole,
          ),
        ) {
    _dispatch();

    if (currentWorkspaceMemberRole == null) {
      _userService.getWorkspaceMember().then((result) {
        result.fold(
          (member) {
            if (!isClosed) {
              add(SettingsAIEvent.refreshMember(member));
            }
          },
          (err) {
            Log.error(err);
          },
        );
      });
    }
  }

  final UserListener _userListener;
  final UserProfilePB userProfile;
  final UserBackendService _userService;
  final String workspaceId;

  @override
  Future<void> close() async {
    await _userListener.stop();
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
                add(SettingsAIEvent.didLoadAISetting(settings));
              }
            },
          );
          _loadUserWorkspaceSetting();
          _loadModelList();
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
        selectModel: (String model) async {
          await _updateUserWorkspaceSetting(model: model);
        },
        didLoadAISetting: (UseAISettingPB settings) {
          emit(
            state.copyWith(
              aiSettings: settings,
              selectedAIModel: settings.aiModel,
              enableSearchIndexing: !settings.disableSearchIndexing,
            ),
          );
        },
        didLoadAvailableModels: (List<AvailableModelPB> models) {
          if (state.selectedAIModel.isEmpty) {
            final m = models.firstWhere((model) => model.isDefault);
            _updateUserWorkspaceSetting(model: m.name);
            emit(
              state.copyWith(
                availableModels: models,
                selectedAIModel: m.name,
              ),
            );
          } else {
            emit(
              state.copyWith(
                availableModels: models,
              ),
            );
          }
        },
        refreshMember: (member) {
          emit(state.copyWith(currentWorkspaceMemberRole: member.role));
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

  void _loadUserWorkspaceSetting() {
    final payload = UserWorkspaceIdPB(workspaceId: workspaceId);
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

  void _loadModelList() {
    AIEventGetServerAvailableModels().send().then((result) {
      result.fold((config) {
        if (!isClosed) {
          add(SettingsAIEvent.didLoadAvailableModels(config.models));
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
  const factory SettingsAIEvent.refreshMember(WorkspaceMemberPB member) =
      _RefreshMember;

  const factory SettingsAIEvent.selectModel(String model) = _SelectAIModel;

  const factory SettingsAIEvent.didReceiveUserProfile(
    UserProfilePB newUserProfile,
  ) = _DidReceiveUserProfile;

  const factory SettingsAIEvent.didLoadAvailableModels(
    List<AvailableModelPB> models,
  ) = _DidLoadAvailableModels;
}

@freezed
class SettingsAIState with _$SettingsAIState {
  const factory SettingsAIState({
    required UserProfilePB userProfile,
    UseAISettingPB? aiSettings,
    @Default("Default") String selectedAIModel,
    AFRolePB? currentWorkspaceMemberRole,
    @Default([]) List<AvailableModelPB> availableModels,
    @Default(true) bool enableSearchIndexing,
  }) = _SettingsAIState;
}

@JsonSerializable()
class ModelList {
  ModelList({
    required this.models,
  });

  factory ModelList.fromJson(Map<String, dynamic> json) =>
      _$ModelListFromJson(json);

  final List<String> models;

  Map<String, dynamic> toJson() => _$ModelListToJson(this);
}
