import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_file_bloc.freezed.dart';

class ChatFileBloc extends Bloc<ChatFileEvent, ChatFileState> {
  ChatFileBloc({
    required String chatId,
  })  : listener = LocalLLMListener(),
        super(const ChatFileState()) {
    listener.start(
      chatStateCallback: (chatState) {
        if (!isClosed) {
          add(ChatFileEvent.updateChatState(chatState));
        }
      },
    );

    on<ChatFileEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final result = await ChatEventGetLocalAIChatState().send();
            result.fold(
              (chatState) {
                if (!isClosed) {
                  add(
                    ChatFileEvent.updateChatState(chatState),
                  );
                }
              },
              (err) {
                Log.error(err.toString());
              },
            );
          },
          newFile: (String filePath) {
            final payload = ChatFilePB(filePath: filePath, chatId: chatId);
            ChatEventChatWithFile(payload).send();
          },
          updateChatState: (LocalAIChatPB chatState) {
            // Only user enable chat with file and the plugin is already running
            final supportChatWithFile = chatState.fileEnabled &&
                chatState.pluginState.state == RunningStatePB.Running;
            emit(
              state.copyWith(supportChatWithFile: supportChatWithFile),
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
  const factory ChatFileEvent.updateChatState(LocalAIChatPB chatState) =
      _UpdateChatState;
}

@freezed
class ChatFileState with _$ChatFileState {
  const factory ChatFileState({
    @Default(false) bool supportChatWithFile,
  }) = _ChatFileState;
}

@freezed
class LocalAIChatFileIndicator with _$LocalAIChatFileIndicator {
  const factory LocalAIChatFileIndicator.ready(bool isEnabled) = _Ready;
  const factory LocalAIChatFileIndicator.loading() = _Loading;
}
