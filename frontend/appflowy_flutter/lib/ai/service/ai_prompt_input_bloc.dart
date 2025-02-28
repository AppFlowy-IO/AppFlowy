import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/workspace/application/settings/ai/local_llm_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'ai_entities.dart';

part 'ai_prompt_input_bloc.freezed.dart';

class AIPromptInputBloc extends Bloc<AIPromptInputEvent, AIPromptInputState> {
  AIPromptInputBloc({
    required PredefinedFormat? predefinedFormat,
  })  : _listener = LocalLLMListener(),
        super(AIPromptInputState.initial(predefinedFormat)) {
    _dispatch();
    _startListening();
    _init();
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
          updateChatState: (LocalAIChatPB chatState) {
            // Only user enable chat with file and the plugin is already running
            final supportChatWithFile = chatState.fileEnabled &&
                chatState.pluginState.state == RunningStatePB.Running;

            final aiType = chatState.pluginState.state == RunningStatePB.Running
                ? AIType.localAI
                : AIType.appflowyAI;
            emit(
              state.copyWith(
                aiType: aiType,
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
          toggleShowPredefinedFormat: () {
            emit(
              state.copyWith(
                showPredefinedFormats: !state.showPredefinedFormats,
              ),
            );
          },
          updatePredefinedFormat: (format) {
            emit(state.copyWith(predefinedFormat: format));
          },
          attachFile: (filePath, fileName) {
            final newFile = ChatFile.fromFilePath(filePath);
            if (newFile != null) {
              emit(
                state.copyWith(
                  attachedFiles: [...state.attachedFiles, newFile],
                ),
              );
            }
          },
          removeFile: (file) {
            final files = [...state.attachedFiles];
            files.remove(file);
            emit(
              state.copyWith(
                attachedFiles: files,
              ),
            );
          },
          updateMentionedViews: (views) {
            emit(
              state.copyWith(
                mentionedPages: views,
              ),
            );
          },
          clearMetadata: () {
            emit(
              state.copyWith(
                attachedFiles: [],
                mentionedPages: [],
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

  Map<String, dynamic> consumeMetadata() {
    final metadata = {
      for (final file in state.attachedFiles) file.filePath: file,
      for (final page in state.mentionedPages) page.id: page,
    };

    if (metadata.isNotEmpty && !isClosed) {
      add(const AIPromptInputEvent.clearMetadata());
    }

    return metadata;
  }
}

@freezed
class AIPromptInputEvent with _$AIPromptInputEvent {
  const factory AIPromptInputEvent.updateChatState(
    LocalAIChatPB chatState,
  ) = _UpdateChatState;
  const factory AIPromptInputEvent.updatePluginState(
    LocalAIPluginStatePB chatState,
  ) = _UpdatePluginState;
  const factory AIPromptInputEvent.toggleShowPredefinedFormat() =
      _ToggleShowPredefinedFormat;
  const factory AIPromptInputEvent.updatePredefinedFormat(
    PredefinedFormat format,
  ) = _UpdatePredefinedFormat;
  const factory AIPromptInputEvent.attachFile(
    String filePath,
    String fileName,
  ) = _AttachFile;
  const factory AIPromptInputEvent.removeFile(ChatFile file) = _RemoveFile;
  const factory AIPromptInputEvent.updateMentionedViews(List<ViewPB> views) =
      _UpdateMentionedViews;
  const factory AIPromptInputEvent.clearMetadata() = _ClearMetadata;
}

@freezed
class AIPromptInputState with _$AIPromptInputState {
  const factory AIPromptInputState({
    required AIType aiType,
    required bool supportChatWithFile,
    required bool showPredefinedFormats,
    required PredefinedFormat? predefinedFormat,
    required LocalAIChatPB? chatState,
    required List<ChatFile> attachedFiles,
    required List<ViewPB> mentionedPages,
  }) = _AIPromptInputState;

  factory AIPromptInputState.initial(PredefinedFormat? format) =>
      AIPromptInputState(
        aiType: AIType.appflowyAI,
        supportChatWithFile: false,
        showPredefinedFormats: format != null,
        predefinedFormat: format,
        chatState: null,
        attachedFiles: [],
        mentionedPages: [],
      );
}

enum AIType {
  appflowyAI,
  localAI;

  bool get isLocalAI => this == localAI;
}
