import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'chat_input_bloc.freezed.dart';

class ChatInputStateBloc
    extends Bloc<ChatInputStateEvent, ChatInputStateState> {
  ChatInputStateBloc()
      : listener = LocalLLMListener(),
        super(const ChatInputStateState(aiType: _AppFlowyAI())) {
    _dispatch();
    _startListening();
    _init();
  }

  final LocalLLMListener listener;

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<ChatInputStateEvent>((event, emit) {
      event.when(
        didUpdatePluginState: (pluginState) {
          if (pluginState.state == RunningStatePB.Running) {
            emit(const ChatInputStateState(aiType: _LocalAI()));
          } else {
            emit(const ChatInputStateState(aiType: _AppFlowyAI()));
          }
        },
      );
    });
  }

  void _startListening() {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(ChatInputStateEvent.didUpdatePluginState(pluginState));
        }
      },
    );
  }

  void _init() {
    AIEventGetLocalAIPluginState().send().fold(
      (pluginState) {
        if (!isClosed) {
          add(ChatInputStateEvent.didUpdatePluginState(pluginState));
        }
      },
      Log.error,
    );
  }
}

@freezed
class ChatInputStateEvent with _$ChatInputStateEvent {
  const factory ChatInputStateEvent.didUpdatePluginState(
    LocalAIPluginStatePB pluginState,
  ) = _UpdatePluginState;
}

@freezed
class ChatInputStateState with _$ChatInputStateState {
  const factory ChatInputStateState({required AIType aiType}) = _ChatInputState;
}

@freezed
class AIType with _$AIType {
  const factory AIType.appflowyAI() = _AppFlowyAI;
  const factory AIType.localAI() = _LocalAI;
}

extension AITypeX on AIType {
  bool isLocalAI() => this is _LocalAI;
}
