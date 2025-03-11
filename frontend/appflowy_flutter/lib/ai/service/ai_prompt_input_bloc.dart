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
          updateAIState: (localAIState) {
            AiType aiType = localAIState.enabled ? AiType.local : AiType.cloud;
            bool supportChatWithFile =
                aiType.isLocal && localAIState.state == RunningStatePB.Running;

            if (localAIState.hasLackOfResource()) {
              aiType = AiType.cloud;
              supportChatWithFile = false;
            }

            final showPredefinedFormats =
                aiType.isCloud && state.showPredefinedFormats;
            emit(
              state.copyWith(
                aiType: aiType,
                supportChatWithFile: supportChatWithFile,
                localAIState: localAIState,
                showPredefinedFormats: showPredefinedFormats,
              ),
            );
          },
          toggleShowPredefinedFormat: () {
            final showPredefinedFormats = !state.showPredefinedFormats;
            final predefinedFormat =
                showPredefinedFormats && state.predefinedFormat == null
                    ? PredefinedFormat(
                        imageFormat: ImageFormat.text,
                        textFormat: TextFormat.paragraph,
                      )
                    : null;
            emit(
              state.copyWith(
                showPredefinedFormats: showPredefinedFormats,
                predefinedFormat: predefinedFormat,
              ),
            );
          },
          updatePredefinedFormat: (format) {
            if (!state.showPredefinedFormats) {
              return;
            }
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
          add(AIPromptInputEvent.updateAIState(pluginState));
        }
      },
    );
  }

  void _init() {
    AIEventGetLocalAIState().send().fold(
      (localAIState) {
        if (!isClosed) {
          add(AIPromptInputEvent.updateAIState(localAIState));
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
  const factory AIPromptInputEvent.updateAIState(LocalAIPB localAIState) =
      _UpdateAIState;
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
    required AiType aiType,
    required bool supportChatWithFile,
    required bool showPredefinedFormats,
    required PredefinedFormat? predefinedFormat,
    required LocalAIPB? localAIState,
    required List<ChatFile> attachedFiles,
    required List<ViewPB> mentionedPages,
  }) = _AIPromptInputState;

  factory AIPromptInputState.initial(PredefinedFormat? format) =>
      AIPromptInputState(
        aiType: AiType.cloud,
        supportChatWithFile: false,
        showPredefinedFormats: format != null,
        predefinedFormat: format,
        localAIState: null,
        attachedFiles: [],
        mentionedPages: [],
      );
}

enum AiType {
  cloud,
  local;

  bool get isCloud => this == cloud;
  bool get isLocal => this == local;
}
