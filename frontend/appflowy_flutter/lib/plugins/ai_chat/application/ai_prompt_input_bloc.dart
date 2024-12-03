import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_prompt_input_bloc.freezed.dart';

class AIPromptInputBloc extends Bloc<AIPromptInputEvent, AIPromptInputState> {
  AIPromptInputBloc()
      : _listener = LocalLLMListener(),
        super(AIPromptInputState.initial()) {
    _dispatch();
    _startListening();
    _init();
  }

  ChatInputFileMetadata consumeMetadata() {
    final metadata = {
      for (final file in state.uploadFiles) file.filePath: file,
    };

    if (metadata.isNotEmpty) {
      add(const AIPromptInputEvent.clear());
    }

    return metadata;
  }

  final LocalLLMListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<AIPromptInputEvent>(
      (event, emit) {
        event.when(
          newFile: (String filePath, String fileName) {
            final files = [...state.uploadFiles];

            final newFile = ChatFile.fromFilePath(filePath);
            if (newFile != null) {
              files.add(newFile);
              emit(state.copyWith(uploadFiles: files));
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
                ? AIType.localAI
                : AIType.appflowyAI;

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

  void _startListening() {
    _listener.start(
      stateCallback: (pluginState) {
        if (!isClosed) {
          add(AIPromptInputEvent.updatePluginState(pluginState));
        }
      },
      chatStateCallback: (chatState) {
        if (!isClosed) {
          add(AIPromptInputEvent.updateChatState(chatState));
        }
      },
    );
  }

  void _init() {
    AIEventGetLocalAIChatState().send().fold(
      (chatState) {
        if (!isClosed) {
          add(AIPromptInputEvent.updateChatState(chatState));
        }
      },
      Log.error,
    );
  }
}

@freezed
class AIPromptInputEvent with _$AIPromptInputEvent {
  const factory AIPromptInputEvent.newFile(String filePath, String fileName) =
      _NewFile;
  const factory AIPromptInputEvent.deleteFile(ChatFile file) = _DeleteFile;
  const factory AIPromptInputEvent.clear() = _ClearFile;
  const factory AIPromptInputEvent.updateChatState(
    LocalAIChatPB chatState,
  ) = _UpdateChatState;
  const factory AIPromptInputEvent.updatePluginState(
    LocalAIPluginStatePB chatState,
  ) = _UpdatePluginState;
}

@freezed
class AIPromptInputState with _$AIPromptInputState {
  const factory AIPromptInputState({
    required bool supportChatWithFile,
    LocalAIChatPB? chatState,
    required List<ChatFile> uploadFiles,
    required AIType aiType,
  }) = _AIPromptInputState;

  factory AIPromptInputState.initial() => const AIPromptInputState(
        supportChatWithFile: false,
        uploadFiles: [],
        aiType: AIType.appflowyAI,
      );
}

enum AIType {
  appflowyAI,
  localAI;

  bool get isLocalAI => this == localAI;
}
