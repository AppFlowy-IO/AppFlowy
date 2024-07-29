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
      chatStateCallback: (aiState) {
        if (!isClosed) {
          add(ChatInputEvent.updateState(aiState));
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
        final result = await ChatEventGetLocalAIChatState().send();
        result.fold(
          (aiState) {
            if (!isClosed) {
              add(
                ChatInputEvent.updateState(aiState),
              );
            }
          },
          (err) {
            Log.error(err.toString());
          },
        );
      },
      updateState: (aiState) {
        if (aiState.enabled) {
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
  const factory ChatInputEvent.updateState(LocalAIChatPB aiState) =
      _UpdateAIState;
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
