import 'dart:async';

import 'package:appflowy/ai/service/ai_model_state_notifier.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'ai_entities.dart';

part 'ai_prompt_input_bloc.freezed.dart';

class AIPromptInputBloc extends Bloc<AIPromptInputEvent, AIPromptInputState> {
  AIPromptInputBloc({
    required String objectId,
    required PredefinedFormat? predefinedFormat,
  })  : aiModelStateNotifier = AIModelStateNotifier(objectId: objectId),
        super(AIPromptInputState.initial(predefinedFormat)) {
    _dispatch();
    _startListening();
    _init();
  }

  final AIModelStateNotifier aiModelStateNotifier;

  @override
  Future<void> close() async {
    await aiModelStateNotifier.dispose();
    return super.close();
  }

  void _dispatch() {
    on<AIPromptInputEvent>(
      (event, emit) {
        event.when(
          updateAIState: (aiType, editable, hintText) {
            emit(
              state.copyWith(
                aiType: aiType,
                editable: editable,
                hintText: hintText,
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
    aiModelStateNotifier.addListener(
      onStateChanged: (aiType, editable, hintText) {
        add(AIPromptInputEvent.updateAIState(aiType, editable, hintText));
      },
    );
  }

  void _init() {
    final (aiType, hintText, isEditable) = aiModelStateNotifier.getState();
    add(AIPromptInputEvent.updateAIState(aiType, isEditable, hintText));
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
  const factory AIPromptInputEvent.updateAIState(
    AiType aiType,
    bool editable,
    String hintText,
  ) = _UpdateAIState;

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
    required List<ChatFile> attachedFiles,
    required List<ViewPB> mentionedPages,
    required bool editable,
    required String hintText,
  }) = _AIPromptInputState;

  factory AIPromptInputState.initial(PredefinedFormat? format) =>
      AIPromptInputState(
        aiType: AiType.cloud,
        supportChatWithFile: false,
        showPredefinedFormats: format != null,
        predefinedFormat: format,
        attachedFiles: [],
        mentionedPages: [],
        editable: true,
        hintText: '',
      );
}
