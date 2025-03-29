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
    await event.when(
      didReceiveAiState: (aiState) {
        emit(
          ReadyLocalAiPluginState(
            isEnabled: aiState.enabled,
            runningState: aiState.state,
            lackOfResource:
                aiState.hasLackOfResource() ? aiState.lackOfResource : null,
          ),
        );
      },
      didReceiveLackOfResources: (resources) {
        if (state case final ReadyLocalAiPluginState readyState) {
          emit(
            ReadyLocalAiPluginState(
              isEnabled: readyState.isEnabled,
              runningState: readyState.runningState,
              lackOfResource: resources,
            ),
          );
        }
      },
      toggle: () async {
        emit(LoadingLocalAiPluginState());
        await AIEventToggleLocalAI().send().fold(
          (aiState) {
            add(LocalAiPluginEvent.didReceiveAiState(aiState));
          },
          Log.error,
        );
      },
      restart: () async {
        emit(LoadingLocalAiPluginState());
        await AIEventRestartLocalAI().send();
      },
    );
  }

  void _startListening() {
    listener.start(
      stateCallback: (pluginState) {
        add(LocalAiPluginEvent.didReceiveAiState(pluginState));
      },
      resourceCallback: (data) {
        add(LocalAiPluginEvent.didReceiveLackOfResources(data));
      },
    );
  }

  void _getLocalAiState() {
    AIEventGetLocalAIState().send().fold(
      (aiState) {
        add(LocalAiPluginEvent.didReceiveAiState(aiState));
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

sealed class LocalAiPluginState {
  const LocalAiPluginState();
}

class ReadyLocalAiPluginState extends LocalAiPluginState {
  const ReadyLocalAiPluginState({
    required this.isEnabled,
    required this.runningState,
    required this.lackOfResource,
  });

  final bool isEnabled;
  final RunningStatePB runningState;
  final LackOfAIResourcePB? lackOfResource;
}

class LoadingLocalAiPluginState extends LocalAiPluginState {
  const LoadingLocalAiPluginState();
}
