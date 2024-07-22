import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'plugin_state_bloc.freezed.dart';

class PluginStateBloc extends Bloc<PluginStateEvent, PluginStateState> {
  PluginStateBloc()
      : listener = LocalLLMListener(),
        super(
          const PluginStateState(
            action: PluginStateAction.init(),
          ),
        ) {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(PluginStateEvent.updateState(pluginState));
        }
      },
    );

    on<PluginStateEvent>(_handleEvent);
  }

  final LocalLLMListener listener;

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
        final result = await ChatEventGetLocalAIPluginState().send();
        result.fold(
          (pluginState) {
            if (!isClosed) {
              add(PluginStateEvent.updateState(pluginState));
            }
          },
          (err) => Log.error(err.toString()),
        );
      },
      updateState: (LocalAIPluginStatePB pluginState) {
        switch (pluginState.state) {
          case RunningStatePB.Connecting:
            emit(
              const PluginStateState(action: PluginStateAction.loadingPlugin()),
            );
          case RunningStatePB.Running:
            emit(const PluginStateState(action: PluginStateAction.ready()));
            break;
          default:
            emit(
              state.copyWith(action: const PluginStateAction.restart()),
            );
            break;
        }
      },
      restartLocalAI: () {
        ChatEventRestartLocalAIChat().send();
      },
    );
  }
}

@freezed
class PluginStateEvent with _$PluginStateEvent {
  const factory PluginStateEvent.started() = _Started;
  const factory PluginStateEvent.updateState(LocalAIPluginStatePB pluginState) =
      _UpdatePluginState;
  const factory PluginStateEvent.restartLocalAI() = _RestartLocalAI;
}

@freezed
class PluginStateState with _$PluginStateState {
  const factory PluginStateState({required PluginStateAction action}) =
      _PluginStateState;
}

@freezed
class PluginStateAction with _$PluginStateAction {
  const factory PluginStateAction.init() = _Init;
  const factory PluginStateAction.loadingPlugin() = _LoadingPlugin;
  const factory PluginStateAction.ready() = _Ready;
  const factory PluginStateAction.restart() = _Restart;
}
