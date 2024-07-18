import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_ai_bloc.freezed.dart';

class LocalAISettingBloc
    extends Bloc<LocalAISettingEvent, LocalAISettingState> {
  LocalAISettingBloc()
      : listener = LocalLLMListener(),
        super(const LocalAISettingState()) {
    listener.start(
      stateCallback: (newState) {
        if (!isClosed) {
          add(LocalAISettingEvent.updateLLMRunningState(newState.state));
        }
      },
    );

    on<LocalAISettingEvent>(_handleEvent);
  }

  final LocalLLMListener listener;

  /// Handles incoming events and dispatches them to the appropriate handler.
  Future<void> _handleEvent(
    LocalAISettingEvent event,
    Emitter<LocalAISettingState> emit,
  ) async {
    await event.when(
      started: _handleStarted,
      didLoadModelInfo: (FlowyResult<LLMModelInfoPB, FlowyError> result) {
        result.fold(
          (modelInfo) {
            _fetchCurremtLLMState();
            emit(
              state.copyWith(
                modelInfo: modelInfo,
                models: modelInfo.models,
                selectedLLMModel: modelInfo.selectedModel,
                fetchModelInfoState: const LoadingState.finish(),
              ),
            );
          },
          (err) {
            emit(
              state.copyWith(
                fetchModelInfoState: LoadingState.finish(error: err),
              ),
            );
          },
        );
      },
      selectLLMConfig: (LLMModelPB llmModel) async {
        final result = await ChatEventUpdateLocalLLM(llmModel).send();
        result.fold(
          (llmResource) {
            // If all resources are downloaded, show reload plugin
            if (llmResource.pendingResources.isNotEmpty) {
              emit(
                state.copyWith(
                  selectedLLMModel: llmModel,
                  localAIInfo: LocalAIProgress.showDownload(
                    llmResource,
                    llmModel,
                  ),
                  selectLLMState: const LoadingState.finish(),
                ),
              );
            } else {
              emit(
                state.copyWith(
                  selectedLLMModel: llmModel,
                  selectLLMState: const LoadingState.finish(),
                  localAIInfo: const LocalAIProgress.checkPluginState(),
                ),
              );
            }
          },
          (err) {
            emit(
              state.copyWith(
                selectLLMState: LoadingState.finish(error: err),
              ),
            );
          },
        );
      },
      refreshLLMState: (LocalModelResourcePB llmResource) {
        if (state.selectedLLMModel == null) {
          Log.error(
            'Unexpected null selected config. It should be set already',
          );
          return;
        }

        // reload plugin if all resources are downloaded
        if (llmResource.pendingResources.isEmpty) {
          emit(
            state.copyWith(
              localAIInfo: const LocalAIProgress.checkPluginState(),
            ),
          );
        } else {
          if (state.selectedLLMModel != null) {
            // Go to download page if the selected model is downloading
            if (llmResource.isDownloading) {
              emit(
                state.copyWith(
                  localAIInfo:
                      LocalAIProgress.startDownloading(state.selectedLLMModel!),
                  selectLLMState: const LoadingState.finish(),
                ),
              );
              return;
            } else {
              emit(
                state.copyWith(
                  localAIInfo: LocalAIProgress.showDownload(
                    llmResource,
                    state.selectedLLMModel!,
                  ),
                  selectLLMState: const LoadingState.finish(),
                ),
              );
            }
          }
        }
      },
      startDownloadModel: (LLMModelPB llmModel) {
        emit(
          state.copyWith(
            localAIInfo: LocalAIProgress.startDownloading(llmModel),
            selectLLMState: const LoadingState.finish(),
          ),
        );
      },
      cancelDownload: () async {
        final _ = await ChatEventCancelDownloadLLMResource().send();
        _fetchCurremtLLMState();
      },
      finishDownload: () async {
        emit(
          state.copyWith(localAIInfo: const LocalAIProgress.finishDownload()),
        );
      },
      updateLLMRunningState: (RunningStatePB newRunningState) {
        if (newRunningState == RunningStatePB.Stopped) {
          emit(
            state.copyWith(
              runningState: newRunningState,
              localAIInfo: const LocalAIProgress.checkPluginState(),
            ),
          );
        } else {
          emit(state.copyWith(runningState: newRunningState));
        }
      },
    );
  }

  void _fetchCurremtLLMState() async {
    final result = await ChatEventGetLocalLLMState().send();
    result.fold(
      (llmResource) {
        if (!isClosed) {
          add(LocalAISettingEvent.refreshLLMState(llmResource));
        }
      },
      (err) {
        Log.error(err);
      },
    );
  }

  /// Handles the event to fetch local AI settings when the application starts.
  Future<void> _handleStarted() async {
    final result = await ChatEventRefreshLocalAIModelInfo().send();
    if (!isClosed) {
      add(LocalAISettingEvent.didLoadModelInfo(result));
    }
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class LocalAISettingEvent with _$LocalAISettingEvent {
  const factory LocalAISettingEvent.started() = _Started;
  const factory LocalAISettingEvent.didLoadModelInfo(
    FlowyResult<LLMModelInfoPB, FlowyError> result,
  ) = _ModelInfo;
  const factory LocalAISettingEvent.selectLLMConfig(LLMModelPB config) =
      _SelectLLMConfig;

  const factory LocalAISettingEvent.refreshLLMState(
    LocalModelResourcePB llmResource,
  ) = _RefreshLLMResource;
  const factory LocalAISettingEvent.startDownloadModel(LLMModelPB llmModel) =
      _StartDownloadModel;

  const factory LocalAISettingEvent.cancelDownload() = _CancelDownload;
  const factory LocalAISettingEvent.finishDownload() = _FinishDownload;
  const factory LocalAISettingEvent.updateLLMRunningState(
    RunningStatePB newRunningState,
  ) = _RunningState;
}

@freezed
class LocalAISettingState with _$LocalAISettingState {
  const factory LocalAISettingState({
    LLMModelInfoPB? modelInfo,
    LLMModelPB? selectedLLMModel,
    LocalAIProgress? localAIInfo,
    @Default(LoadingState.loading()) LoadingState fetchModelInfoState,
    @Default(LoadingState.loading()) LoadingState selectLLMState,
    @Default([]) List<LLMModelPB> models,
    @Default(RunningStatePB.Connecting) RunningStatePB runningState,
  }) = _LocalAISettingState;
}

@freezed
class LocalAIProgress with _$LocalAIProgress {
  // when user select a new model, it will call requestDownload
  const factory LocalAIProgress.requestDownloadInfo(
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) = _RequestDownload;

  // when user comes back to the setting page, it will auto detect current llm state
  const factory LocalAIProgress.showDownload(
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) = _DownloadNeeded;

  // when start downloading the model
  const factory LocalAIProgress.startDownloading(LLMModelPB llmModel) =
      _Downloading;
  const factory LocalAIProgress.finishDownload() = _Finish;
  const factory LocalAIProgress.checkPluginState() = _PluginState;
}
