import 'dart:async';

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
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(ChatFileEvent.updatePluginState(pluginState));
        }
      },
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
          newFile: (String filePath, String fileName) async {
            emit(
              state.copyWith(
                indexFileIndicator: IndexFileIndicator.indexing(fileName),
              ),
            );
            final payload = ChatFilePB(filePath: filePath, chatId: chatId);
            unawaited(
              ChatEventChatWithFile(payload).send().then((result) {
                if (!isClosed) {
                  result.fold((_) {
                    add(
                      ChatFileEvent.updateIndexFile(
                        IndexFileIndicator.finish(fileName),
                      ),
                    );
                  }, (err) {
                    add(
                      ChatFileEvent.updateIndexFile(
                        IndexFileIndicator.error(err.msg),
                      ),
                    );
                  });
                }
              }),
            );
          },
          updateChatState: (LocalAIChatPB chatState) {
            // Only user enable chat with file and the plugin is already running
            final supportChatWithFile = chatState.fileEnabled &&
                chatState.pluginState.state == RunningStatePB.Running;
            emit(
              state.copyWith(
                supportChatWithFile: supportChatWithFile,
                chatState: chatState,
              ),
            );
          },
          updateIndexFile: (IndexFileIndicator indicator) {
            emit(
              state.copyWith(indexFileIndicator: indicator),
            );
          },
          updatePluginState: (LocalAIPluginStatePB chatState) {
            final fileEnabled = state.chatState?.fileEnabled ?? false;
            final supportChatWithFile =
                fileEnabled && chatState.state == RunningStatePB.Running;
            emit(state.copyWith(supportChatWithFile: supportChatWithFile));
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
  const factory ChatFileEvent.newFile(String filePath, String fileName) =
      _NewFile;
  const factory ChatFileEvent.updateChatState(LocalAIChatPB chatState) =
      _UpdateChatState;
  const factory ChatFileEvent.updatePluginState(
    LocalAIPluginStatePB chatState,
  ) = _UpdatePluginState;
  const factory ChatFileEvent.updateIndexFile(IndexFileIndicator indicator) =
      _UpdateIndexFile;
}

@freezed
class ChatFileState with _$ChatFileState {
  const factory ChatFileState({
    @Default(false) bool supportChatWithFile,
    IndexFileIndicator? indexFileIndicator,
    LocalAIChatPB? chatState,
  }) = _ChatFileState;
}

@freezed
class IndexFileIndicator with _$IndexFileIndicator {
  const factory IndexFileIndicator.finish(String fileName) = _Finish;
  const factory IndexFileIndicator.indexing(String fileName) = _Indexing;
  const factory IndexFileIndicator.error(String error) = _Error;
}
