import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
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
          add(ChatInputEvent.updateState(pluginState));
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
        final result = await ChatEventGetLocalAIPluginState().send();
        result.fold(
          (pluginState) {
            if (!isClosed) {
              add(ChatInputEvent.updateState(pluginState));
            }
          },
          (err) => Log.error(err.toString()),
        );
      },
      updateState: (LocalAIPluginStatePB aiPluginState) {
        emit(const ChatInputState(aiType: _AppFlowyAI()));
      },
    );
  }
}

@freezed
class ChatInputEvent with _$ChatInputEvent {
  const factory ChatInputEvent.started() = _Started;
  const factory ChatInputEvent.updateState(LocalAIPluginStatePB aiPluginState) =
      _UpdatePluginState;
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
