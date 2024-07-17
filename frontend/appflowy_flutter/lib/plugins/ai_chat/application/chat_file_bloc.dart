import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_file_bloc.freezed.dart';

class ChatFileBloc extends Bloc<ChatFileEvent, ChatFileState> {
  ChatFileBloc({
    required String chatId,
    dynamic message,
  })  : listener = LocalLLMListener(),
        super(ChatFileState.initial(message)) {
    listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(ChatFileEvent.updateLocalAIToggleState(pluginState));
        }
      },
    );

    on<ChatFileEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final result = await ChatEventGetLocalAIPluginState().send();
            result.fold(
              (toggleState) {
                if (!isClosed) {
                  add(
                    ChatFileEvent.updateLocalAIToggleState(toggleState),
                  );
                }
              },
              (err) {},
            );
          },
          newFile: (String filePath) {
            final payload = ChatFilePB(filePath: filePath, chatId: chatId);
            ChatEventChatWithFile(payload).send();
          },
          updateLocalAIToggleState: (LocalAIPluginStatePB pluginState) {
            emit(
              state.copyWith(
                supportChatWithFile:
                    pluginState.state == RunningStatePB.Running,
              ),
            );
          },
        );
      },
    );
  }

  final LocalLLMListener listener;

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }
}

@freezed
class ChatFileEvent with _$ChatFileEvent {
  const factory ChatFileEvent.initial() = Initial;
  const factory ChatFileEvent.newFile(String filePath) = _NewFile;
  const factory ChatFileEvent.updateLocalAIToggleState(
    LocalAIPluginStatePB pluginState,
  ) = _UpdateLocalAIToggleState;
}

@freezed
class ChatFileState with _$ChatFileState {
  const factory ChatFileState({
    required String text,
    @Default(false) bool supportChatWithFile,
  }) = _ChatFileState;

  factory ChatFileState.initial(dynamic text) {
    return ChatFileState(
      text: text is String ? text : "",
    );
  }
}
