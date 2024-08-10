import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_input_bloc.dart';

part 'chat_file_bloc.freezed.dart';

class ChatFileBloc extends Bloc<ChatFileEvent, ChatFileState> {
  ChatFileBloc()
      : listener = LocalLLMListener(),
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
            final result = await AIEventGetLocalAIChatState().send();
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
            final files = List<ChatFile>.from(state.uploadFiles);
            final newFile = ChatFile.fromFilePath(filePath);
            if (newFile != null) {
              files.add(newFile);
              emit(
                state.copyWith(
                  uploadFiles: files,
                ),
              );
            }
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
          updatePluginState: (LocalAIPluginStatePB chatState) {
            final fileEnabled = state.chatState?.fileEnabled ?? false;
            final supportChatWithFile =
                fileEnabled && chatState.state == RunningStatePB.Running;

            final aiType = chatState.state == RunningStatePB.Running
                ? const AIType.localAI()
                : const AIType.appflowyAI();

            emit(
              state.copyWith(
                supportChatWithFile: supportChatWithFile,
                aiType: aiType,
              ),
            );
          },
          deleteFile: (file) {
            final files = List<ChatFile>.from(state.uploadFiles);
            files.remove(file);
            emit(
              state.copyWith(
                uploadFiles: files,
              ),
            );
          },
          clear: () {
            emit(
              state.copyWith(
                uploadFiles: [],
              ),
            );
          },
        );
      },
    );
  }

  ChatInputFileMetadata consumeMetaData() {
    final metadata = state.uploadFiles.fold(
      <String, ChatFile>{},
      (map, file) => map..putIfAbsent(file.filePath, () => file),
    );

    if (metadata.isNotEmpty) {
      add(const ChatFileEvent.clear());
    }

    return metadata;
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
  const factory ChatFileEvent.deleteFile(ChatFile file) = _DeleteFile;
  const factory ChatFileEvent.clear() = _ClearFile;
  const factory ChatFileEvent.updateChatState(LocalAIChatPB chatState) =
      _UpdateChatState;
  const factory ChatFileEvent.updatePluginState(
    LocalAIPluginStatePB chatState,
  ) = _UpdatePluginState;
}

@freezed
class ChatFileState with _$ChatFileState {
  const factory ChatFileState({
    @Default(false) bool supportChatWithFile,
    LocalAIChatPB? chatState,
    @Default([]) List<ChatFile> uploadFiles,
    @Default(AIType.appflowyAI()) AIType aiType,
  }) = _ChatFileState;
}
