import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'chat_input_bloc.freezed.dart';

class ChatInputBloc extends Bloc<ChatInputEvent, ChatInputState> {
  ChatInputBloc()
      : listener = LocalLLMListener(),
        super(const ChatInputState(aiType: _AppFlowyAI())) {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(ChatInputEvent.updatePluginState(pluginState));
        }
      },
    );

    on<ChatInputEvent>(_handleEvent);
  }

  final LocalLLMListener listener;

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Future<void> _handleEvent(
    ChatInputEvent event,
    Emitter<ChatInputState> emit,
  ) async {
    await event.when(
      started: () async {
        final result = await AIEventGetLocalAIPluginState().send();
        result.fold(
          (pluginState) {
            if (!isClosed) {
              add(
                ChatInputEvent.updatePluginState(pluginState),
              );
            }
          },
          (err) {
            Log.error(err.toString());
          },
        );
      },
      updatePluginState: (pluginState) {
        if (pluginState.state == RunningStatePB.Running) {
          emit(const ChatInputState(aiType: _LocalAI()));
        } else {
          emit(const ChatInputState(aiType: _AppFlowyAI()));
        }
      },
    );
  }
}

@freezed
class ChatInputEvent with _$ChatInputEvent {
  const factory ChatInputEvent.started() = _Started;
  const factory ChatInputEvent.updatePluginState(
    LocalAIPluginStatePB pluginState,
  ) = _UpdatePluginState;
}

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({required AIType aiType}) = _ChatInputState;
}

@freezed
class AIType with _$AIType {
  const factory AIType.appflowyAI() = _AppFlowyAI;
  const factory AIType.localAI() = _LocalAI;
}
