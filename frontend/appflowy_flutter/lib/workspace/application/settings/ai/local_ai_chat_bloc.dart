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

part 'local_ai_chat_bloc.freezed.dart';

class LocalAIChatSettingBloc
    extends Bloc<LocalAIChatSettingEvent, LocalAIChatSettingState> {
  LocalAIChatSettingBloc()
      : listener = LocalLLMListener(),
        super(const LocalAIChatSettingState()) {
    listener.start(
      stateCallback: (newState) {
        if (!isClosed) {
          add(LocalAIChatSettingEvent.updatePluginState(newState));
        }
      },
    );

    on<LocalAIChatSettingEvent>(_handleEvent);
  }

  final LocalLLMListener listener;

  /// Handles incoming events and dispatches them to the appropriate handler.
  Future<void> _handleEvent(
    LocalAIChatSettingEvent event,
    Emitter<LocalAIChatSettingState> emit,
  ) async {
    await event.when(
      refreshAISetting: _handleStarted,
      didLoadModelInfo: (FlowyResult<LLMModelInfoPB, FlowyError> result) {
        result.fold(
          (modelInfo) {
            _fetchCurremtLLMState();
            emit(
              state.copyWith(
                modelInfo: modelInfo,
                models: modelInfo.models,
                selectedLLMModel: modelInfo.selectedModel,
                aiModelProgress: const AIModelProgress.finish(),
              ),
            );
          },
          (err) {
            emit(
              state.copyWith(
                aiModelProgress: AIModelProgress.finish(error: err),
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
                  progressIndicator: LocalAIProgress.showDownload(
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
                  progressIndicator: const LocalAIProgress.checkPluginState(),
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
              progressIndicator: const LocalAIProgress.checkPluginState(),
            ),
          );
        } else {
          if (state.selectedLLMModel != null) {
            // Go to download page if the selected model is downloading
            if (llmResource.isDownloading) {
              emit(
                state.copyWith(
                  progressIndicator:
                      LocalAIProgress.startDownloading(state.selectedLLMModel!),
                  selectLLMState: const LoadingState.finish(),
                ),
              );
              return;
            } else {
              emit(
                state.copyWith(
                  progressIndicator: LocalAIProgress.showDownload(
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
            progressIndicator: LocalAIProgress.startDownloading(llmModel),
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
          state.copyWith(
            progressIndicator: const LocalAIProgress.finishDownload(),
          ),
        );
      },
      updatePluginState: (LocalAIPluginStatePB pluginState) {
        if (pluginState.offlineAiReady) {
          ChatEventRefreshLocalAIModelInfo().send().then((result) {
            if (!isClosed) {
              add(LocalAIChatSettingEvent.didLoadModelInfo(result));
            }
          });

          if (pluginState.state == RunningStatePB.Stopped) {
            emit(
              state.copyWith(
                runningState: pluginState.state,
                progressIndicator: const LocalAIProgress.checkPluginState(),
              ),
            );
          } else {
            emit(
              state.copyWith(
                runningState: pluginState.state,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              progressIndicator: const LocalAIProgress.startOfflineAIApp(),
            ),
          );
        }
      },
    );
  }

  void _fetchCurremtLLMState() async {
    final result = await ChatEventGetLocalLLMState().send();
    result.fold(
      (llmResource) {
        if (!isClosed) {
          add(LocalAIChatSettingEvent.refreshLLMState(llmResource));
        }
      },
      (err) {
        Log.error(err);
      },
    );
  }

  /// Handles the event to fetch local AI settings when the application starts.
  Future<void> _handleStarted() async {
    final result = await ChatEventGetLocalAIPluginState().send();
    result.fold(
      (pluginState) async {
        if (!isClosed) {
          add(LocalAIChatSettingEvent.updatePluginState(pluginState));
          if (pluginState.offlineAiReady) {
            final result = await ChatEventRefreshLocalAIModelInfo().send();
            if (!isClosed) {
              add(LocalAIChatSettingEvent.didLoadModelInfo(result));
            }
          }
        }
      },
      (err) => Log.error(err.toString()),
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class LocalAIChatSettingEvent with _$LocalAIChatSettingEvent {
  const factory LocalAIChatSettingEvent.refreshAISetting() = _RefreshAISetting;
  const factory LocalAIChatSettingEvent.didLoadModelInfo(
    FlowyResult<LLMModelInfoPB, FlowyError> result,
  ) = _ModelInfo;
  const factory LocalAIChatSettingEvent.selectLLMConfig(LLMModelPB config) =
      _SelectLLMConfig;

  const factory LocalAIChatSettingEvent.refreshLLMState(
    LocalModelResourcePB llmResource,
  ) = _RefreshLLMResource;
  const factory LocalAIChatSettingEvent.startDownloadModel(
    LLMModelPB llmModel,
  ) = _StartDownloadModel;

  const factory LocalAIChatSettingEvent.cancelDownload() = _CancelDownload;
  const factory LocalAIChatSettingEvent.finishDownload() = _FinishDownload;
  const factory LocalAIChatSettingEvent.updatePluginState(
    LocalAIPluginStatePB pluginState,
  ) = _PluginState;
}

@freezed
class LocalAIChatSettingState with _$LocalAIChatSettingState {
  const factory LocalAIChatSettingState({
    LLMModelInfoPB? modelInfo,
    LLMModelPB? selectedLLMModel,
    LocalAIProgress? progressIndicator,
    @Default(AIModelProgress.init()) AIModelProgress aiModelProgress,
    @Default(LoadingState.loading()) LoadingState selectLLMState,
    @Default([]) List<LLMModelPB> models,
    @Default(RunningStatePB.Connecting) RunningStatePB runningState,
  }) = _LocalAIChatSettingState;
}

@freezed
class LocalAIProgress with _$LocalAIProgress {
  // when user comes back to the setting page, it will auto detect current llm state
  const factory LocalAIProgress.showDownload(
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) = _DownloadNeeded;

  // when start downloading the model
  const factory LocalAIProgress.startDownloading(LLMModelPB llmModel) =
      _Downloading;
  const factory LocalAIProgress.finishDownload() = _Finish;
  const factory LocalAIProgress.checkPluginState() = _CheckPluginState;
  const factory LocalAIProgress.startOfflineAIApp() = _StartOfflineAIApp;
}

@freezed
class AIModelProgress with _$AIModelProgress {
  const factory AIModelProgress.init() = _AIModelProgressInit;
  const factory AIModelProgress.loading() = _AIModelDownloading;
  const factory AIModelProgress.finish({FlowyError? error}) = _AIModelFinish;
}
