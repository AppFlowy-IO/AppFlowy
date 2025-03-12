import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_state_bloc.freezed.dart';

class PluginStateBloc extends Bloc<PluginStateEvent, PluginStateState> {
  PluginStateBloc()
      : listener = LocalAIStateListener(),
        super(
          const PluginStateState(
            action: PluginStateAction.unknown(),
          ),
        ) {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(PluginStateEvent.updateLocalAIState(pluginState));
        }
      },
      resourceCallback: (data) {
        if (!isClosed) {
          add(PluginStateEvent.resourceStateChange(data));
        }
      },
    );

    on<PluginStateEvent>(_handleEvent);
  }

  final LocalAIStateListener listener;

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Future<void> _handleEvent(
    PluginStateEvent event,
    Emitter<PluginStateState> emit,
  ) async {
    await event.when(
      started: () async {
        final result = await AIEventGetLocalAIState().send();
        result.fold(
          (pluginState) {
            if (!isClosed) {
              add(PluginStateEvent.updateLocalAIState(pluginState));
            }
          },
          (err) => Log.error(err.toString()),
        );
      },
      updateLocalAIState: (LocalAIPB aiState) {
        // if the offline ai is not started, ask user to start it
        if (aiState.hasLackOfResource()) {
          emit(
            PluginStateState(
              action: PluginStateAction.lackOfResource(aiState.lackOfResource),
            ),
          );
          return;
        }

        // Chech state of the plugin
        switch (aiState.state) {
          case RunningStatePB.ReadyToRun:
            emit(
              const PluginStateState(
                action: PluginStateAction.readToRun(),
              ),
            );

          case RunningStatePB.Connecting:
            emit(
              const PluginStateState(
                action: PluginStateAction.initializingPlugin(),
              ),
            );
          case RunningStatePB.Connected:
            emit(
              const PluginStateState(
                action: PluginStateAction.initializingPlugin(),
              ),
            );
            break;
          case RunningStatePB.Running:
            emit(const PluginStateState(action: PluginStateAction.running()));
            break;
          case RunningStatePB.Stopped:
            emit(
              state.copyWith(action: const PluginStateAction.restartPlugin()),
            );
          default:
            break;
        }
      },
      restartLocalAI: () async {
        emit(
          const PluginStateState(action: PluginStateAction.restartPlugin()),
        );
        unawaited(AIEventRestartLocalAI().send());
      },
      resourceStateChange: (data) {
        emit(
          PluginStateState(
            action: PluginStateAction.lackOfResource(data.resourceDesc),
          ),
        );
      },
    );
  }
}

@freezed
class PluginStateEvent with _$PluginStateEvent {
  const factory PluginStateEvent.started() = _Started;
  const factory PluginStateEvent.updateLocalAIState(LocalAIPB aiState) =
      _UpdateLocalAIState;
  const factory PluginStateEvent.restartLocalAI() = _RestartLocalAI;
  const factory PluginStateEvent.resourceStateChange(LackOfAIResourcePB data) =
      _ResourceStateChange;
}

@freezed
class PluginStateState with _$PluginStateState {
  const factory PluginStateState({
    required PluginStateAction action,
  }) = _PluginStateState;
}

@freezed
class PluginStateAction with _$PluginStateAction {
  const factory PluginStateAction.unknown() = _Unknown;
  const factory PluginStateAction.readToRun() = _ReadyToRun;
  const factory PluginStateAction.initializingPlugin() = _InitializingPlugin;
  const factory PluginStateAction.running() = _PluginRunning;
  const factory PluginStateAction.restartPlugin() = _RestartPlugin;
  const factory PluginStateAction.lackOfResource(String desc) = _LackOfResource;
}
