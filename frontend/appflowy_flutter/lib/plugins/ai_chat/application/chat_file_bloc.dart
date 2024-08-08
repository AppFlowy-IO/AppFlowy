import 'dart:async';

import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_input_bloc.dart';

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
            files.add(ChatFile(filePath: filePath, fileName: fileName));
            emit(
              state.copyWith(
                uploadFiles: files,
              ),
            );

            emit(
              state.copyWith(
                uploadFileIndicator: UploadFileIndicator.uploading(fileName),
              ),
            );
            final payload = ChatFilePB(filePath: filePath, chatId: chatId);
            unawaited(
              AIEventChatWithFile(payload).send().then((result) {
                if (!isClosed) {
                  result.fold((_) {
                    add(
                      ChatFileEvent.updateUploadState(
                        UploadFileIndicator.finish(fileName),
                      ),
                    );
                  }, (err) {
                    add(
                      ChatFileEvent.updateUploadState(
                        UploadFileIndicator.error(err.msg),
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
          clear: () {
            emit(
              state.copyWith(
                uploadFiles: [],
              ),
            );
          },
          updateUploadState: (UploadFileIndicator indicator) {
            emit(state.copyWith(uploadFileIndicator: indicator));
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
  const factory ChatFileEvent.clear() = _ClearFile;
  const factory ChatFileEvent.updateUploadState(UploadFileIndicator indicator) =
      _UpdateUploadState;
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
    UploadFileIndicator? uploadFileIndicator,
    LocalAIChatPB? chatState,
    @Default([]) List<ChatFile> uploadFiles,
    @Default(AIType.appflowyAI()) AIType aiType,
  }) = _ChatFileState;
}

@freezed
class UploadFileIndicator with _$UploadFileIndicator {
  const factory UploadFileIndicator.finish(String fileName) = _Finish;
  const factory UploadFileIndicator.uploading(String fileName) = _Uploading;
  const factory UploadFileIndicator.error(String error) = _Error;
}

class ChatFile {
  ChatFile({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;
}
