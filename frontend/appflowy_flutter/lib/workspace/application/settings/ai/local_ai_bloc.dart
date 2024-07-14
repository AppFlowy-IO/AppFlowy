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

class LocalAIConfigBloc extends Bloc<LocalAIConfigEvent, LocalAIConfigState> {
  LocalAIConfigBloc()
      : listener = LocalLLMListener(),
        super(const LocalAIConfigState()) {
    listener.start(
      stateCallback: (newState) {
        if (!isClosed) {
          Log.debug('Local LLM State: new state: $newState');
          add(LocalAIConfigEvent.updatellmRunningState(newState));
        }
      },
    );

    on<LocalAIConfigEvent>(_handleEvent);
  }

  final LocalLLMListener listener;

  /// Handles incoming events and dispatches them to the appropriate handler.
  Future<void> _handleEvent(
    LocalAIConfigEvent event,
    Emitter<LocalAIConfigState> emit,
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
                loadingState: const LoadingState.finish(),
              ),
            );
          },
          (err) {
            emit(state.copyWith(loadingState: LoadingState.finish(error: err)));
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
                  localAIInfo: LocalAIInfo.requestDownload(
                    llmResource,
                    llmModel,
                  ),
                  llmModelLoadingState: const LoadingState.finish(),
                ),
              );
            } else {
              emit(
                state.copyWith(
                  selectedLLMModel: llmModel,
                  llmModelLoadingState: const LoadingState.finish(),
                  localAIInfo: const LocalAIInfo.pluginState(),
                ),
              );
            }
          },
          (err) {
            emit(
              state.copyWith(
                llmModelLoadingState: LoadingState.finish(error: err),
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
              localAIInfo: const LocalAIInfo.pluginState(),
            ),
          );
        } else {
          if (state.selectedLLMModel != null) {
            // Go to download page if the selected model is downloading
            if (llmResource.isDownloading) {
              emit(
                state.copyWith(
                  localAIInfo: LocalAIInfo.downloading(state.selectedLLMModel!),
                  llmModelLoadingState: const LoadingState.finish(),
                ),
              );
              return;
            } else {
              emit(
                state.copyWith(
                  localAIInfo: LocalAIInfo.downloadNeeded(
                    llmResource,
                    state.selectedLLMModel!,
                  ),
                  llmModelLoadingState: const LoadingState.finish(),
                ),
              );
            }
          }
        }
      },
      startDownloadModel: (LLMModelPB llmModel) {
        emit(
          state.copyWith(
            localAIInfo: LocalAIInfo.downloading(llmModel),
            llmModelLoadingState: const LoadingState.finish(),
          ),
        );
      },
      cancelDownload: () async {
        final _ = await ChatEventCancelDownloadLLMResource().send();
        _fetchCurremtLLMState();
      },
      finishDownload: () async {
        emit(
          state.copyWith(localAIInfo: const LocalAIInfo.finishDownload()),
        );
      },
      updatellmRunningState: (RunningStatePB newRunningState) {
        emit(state.copyWith(runningState: newRunningState));
      },
    );
  }

  void _fetchCurremtLLMState() async {
    final result = await ChatEventGetLocalLLMState().send();
    result.fold(
      (llmResource) {
        if (!isClosed) {
          add(LocalAIConfigEvent.refreshLLMState(llmResource));
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
      add(LocalAIConfigEvent.didLoadModelInfo(result));
    }
  }
}

@freezed
class LocalAIConfigEvent with _$LocalAIConfigEvent {
  const factory LocalAIConfigEvent.started() = _Started;
  const factory LocalAIConfigEvent.didLoadModelInfo(
    FlowyResult<LLMModelInfoPB, FlowyError> result,
  ) = _ModelInfo;
  const factory LocalAIConfigEvent.selectLLMConfig(LLMModelPB config) =
      _SelectLLMConfig;

  const factory LocalAIConfigEvent.refreshLLMState(
    LocalModelResourcePB llmResource,
  ) = _RefreshLLMResource;
  const factory LocalAIConfigEvent.startDownloadModel(LLMModelPB llmModel) =
      _StartDownloadModel;

  const factory LocalAIConfigEvent.cancelDownload() = _CancelDownload;
  const factory LocalAIConfigEvent.finishDownload() = _FinishDownload;
  const factory LocalAIConfigEvent.updatellmRunningState(
    RunningStatePB newRunningState,
  ) = _RunningState;
}

@freezed
class LocalAIConfigState with _$LocalAIConfigState {
  const factory LocalAIConfigState({
    LLMModelInfoPB? modelInfo,
    LLMModelPB? selectedLLMModel,
    LocalAIInfo? localAIInfo,
    @Default(LoadingState.loading()) LoadingState llmModelLoadingState,
    @Default([]) List<LLMModelPB> models,
    @Default(LoadingState.loading()) LoadingState loadingState,
    @Default(RunningStatePB.Connecting) RunningStatePB runningState,
  }) = _LocalAIConfigState;
}

@freezed
class LocalAIInfo with _$LocalAIInfo {
  // when user select a new model, it will call requestDownload
  const factory LocalAIInfo.requestDownload(
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) = _RequestDownload;

  // when user comes back to the setting page, it will auto detect current llm state
  const factory LocalAIInfo.downloadNeeded(
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) = _DownloadNeeded;

  // when start downloading the model
  const factory LocalAIInfo.downloading(LLMModelPB llmModel) = _Downloading;
  const factory LocalAIInfo.finishDownload() = _Finish;
  const factory LocalAIInfo.pluginState() = _PluginState;
}
