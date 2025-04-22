import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'local_llm_listener.dart';

part 'local_ai_bloc.freezed.dart';

class LocalAiPluginBloc extends Bloc<LocalAiPluginEvent, LocalAiPluginState> {
  LocalAiPluginBloc() : super(const LoadingLocalAiPluginState()) {
    on<LocalAiPluginEvent>(_handleEvent);
    _startListening();
    _getLocalAiState();
  }

  final listener = LocalAIStateListener();

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Future<void> _handleEvent(
    LocalAiPluginEvent event,
    Emitter<LocalAiPluginState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    await event.when(
      didReceiveAiState: (aiState) {
        emit(
          LocalAiPluginState.ready(
            isEnabled: aiState.enabled,
            version: aiState.pluginVersion,
            runningState: aiState.state,
            lackOfResource:
                aiState.hasLackOfResource() ? aiState.lackOfResource : null,
          ),
        );
      },
      didReceiveLackOfResources: (resources) {
        state.maybeMap(
          ready: (readyState) {
            emit(readyState.copyWith(lackOfResource: resources));
          },
          orElse: () {},
        );
      },
      toggle: () async {
        emit(LocalAiPluginState.loading());
        await AIEventToggleLocalAI().send().fold(
          (aiState) {
            if (!isClosed) {
              add(LocalAiPluginEvent.didReceiveAiState(aiState));
            }
          },
          Log.error,
        );
      },
      restart: () async {
        emit(LocalAiPluginState.loading());
        await AIEventRestartLocalAI().send();
      },
    );
  }

  void _startListening() {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(LocalAiPluginEvent.didReceiveAiState(pluginState));
        }
      },
      resourceCallback: (data) {
        if (!isClosed) {
          add(LocalAiPluginEvent.didReceiveLackOfResources(data));
        }
      },
    );
  }

  void _getLocalAiState() {
    AIEventGetLocalAIState().send().fold(
      (aiState) {
        if (!isClosed) {
          add(LocalAiPluginEvent.didReceiveAiState(aiState));
        }
      },
      Log.error,
    );
  }
}

@freezed
class LocalAiPluginEvent with _$LocalAiPluginEvent {
  const factory LocalAiPluginEvent.didReceiveAiState(LocalAIPB aiState) =
      _DidReceiveAiState;
  const factory LocalAiPluginEvent.didReceiveLackOfResources(
    LackOfAIResourcePB resources,
  ) = _DidReceiveLackOfResources;
  const factory LocalAiPluginEvent.toggle() = _Toggle;
  const factory LocalAiPluginEvent.restart() = _Restart;
}

@freezed
class LocalAiPluginState with _$LocalAiPluginState {
  const LocalAiPluginState._();

  const factory LocalAiPluginState.ready({
    required bool isEnabled,
    required String version,
    required RunningStatePB runningState,
    required LackOfAIResourcePB? lackOfResource,
  }) = ReadyLocalAiPluginState;

  const factory LocalAiPluginState.loading() = LoadingLocalAiPluginState;

  bool get isEnabled {
    return maybeWhen(
      ready: (isEnabled, _, __, ___) => isEnabled,
      orElse: () => false,
    );
  }

  bool get showIndicator {
    return maybeWhen(
      ready: (isEnabled, _, runningState, lackOfResource) =>
          runningState != RunningStatePB.Running || lackOfResource != null,
      orElse: () => false,
    );
  }
}
