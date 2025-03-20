import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '../../base/markdown_text_robot.dart';
import 'ai_writer_block_operations.dart';
import 'ai_writer_entities.dart';
import 'ai_writer_node_extension.dart';

class AiWriterCubit extends Cubit<AiWriterState> {
  AiWriterCubit({
    required this.documentId,
    required this.editorState,
    this.onCreateNode,
    this.onRemoveNode,
    this.onAppendToDocument,
    AppFlowyAIService? aiService,
  })  : _aiService = aiService ?? AppFlowyAIService(),
        _textRobot = MarkdownTextRobot(editorState: editorState),
        selectedSourcesNotifier = ValueNotifier([documentId]),
        super(IdleAiWriterState());

  final String documentId;
  final EditorState editorState;
  final AppFlowyAIService _aiService;
  final MarkdownTextRobot _textRobot;
  final void Function()? onCreateNode;
  final void Function()? onRemoveNode;
  final void Function()? onAppendToDocument;

  Node? aiWriterNode;

  final List<AiWriterRecord> records = [];
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  (String, PredefinedFormat?)? _previousPrompt;
  bool acceptReplacesOriginal = false;

  @override
  Future<void> close() async {
    selectedSourcesNotifier.dispose();
    await super.close();
  }

  void register(Node node) async {
    aiWriterNode = node;
    onCreateNode?.call();

    await setAiWriterNodeIsInitialized(editorState, node);

    final command = node.aiWriterCommand;
    if (command == AiWriterCommand.userQuestion) {
      emit(ReadyAiWriterState(AiWriterCommand.userQuestion, isFirstRun: true));
    } else {
      runCommand(command, isFirstRun: true);
    }
  }

  Future<void> exit() async {
    await _textRobot.discard();
    _textRobot.reset();
    onRemoveNode?.call();
    emit(IdleAiWriterState());

    if (aiWriterNode != null) {
      final selection = aiWriterNode!.aiWriterSelection;
      if (selection == null) {
        return;
      }
      final transaction = editorState.transaction;
      formatSelection(
        editorState,
        selection,
        transaction,
        ApplySuggestionFormatType.clear,
      );
      await editorState.apply(
        transaction,
        options: const ApplyOptions(
          inMemoryUpdate: true,
          recordUndo: false,
        ),
        withUpdateSelection: false,
      );
      await removeAiWriterNode(editorState, aiWriterNode!);
      aiWriterNode = null;
    }
  }

  void runCommand(
    AiWriterCommand command, {
    required bool isFirstRun,
    PredefinedFormat? predefinedFormat,
    bool isRetry = false,
  }) async {
    switch (command) {
      case AiWriterCommand.continueWriting:
        await _startContinueWriting(
          command,
          predefinedFormat,
          isImmediateRun: isFirstRun,
        );
        break;
      case AiWriterCommand.fixSpellingAndGrammar:
      case AiWriterCommand.improveWriting:
      case AiWriterCommand.makeLonger:
      case AiWriterCommand.makeShorter:
        await _startSuggestingEdits(command, predefinedFormat);
        break;
      case AiWriterCommand.explain:
        await _startInforming(command, predefinedFormat);
        break;
      case AiWriterCommand.userQuestion:
        if (isRetry && _previousPrompt != null) {
          submit(_previousPrompt!.$1, _previousPrompt!.$2);
        }
        break;
    }
  }

  Future<void> stopStream() async {
    if (state is GeneratingAiWriterState) {
      final generatingState = state as GeneratingAiWriterState;

      await _textRobot.stop(
        attributes: ApplySuggestionFormatType.replace.attributes,
      );

      await AIEventStopCompleteText(
        CompleteTextTaskPB(
          taskId: generatingState.taskId,
        ),
      ).send();

      emit(
        ReadyAiWriterState(
          generatingState.command,
          isFirstRun: false,
          markdownText: generatingState.markdownText,
        ),
      );
    }
  }

  void runResponseAction(
    SuggestionAction action, [
    PredefinedFormat? predefinedFormat,
  ]) async {
    if (aiWriterNode == null) {
      return;
    }

    if (state is! RegisteredAiWriter) {
      return;
    }

    final command = (state as RegisteredAiWriter).command;

    if (action case SuggestionAction.rewrite || SuggestionAction.tryAgain) {
      await _textRobot.discard();
      _textRobot.reset();
      runCommand(
        command,
        predefinedFormat: predefinedFormat,
        isRetry: true,
        isFirstRun: false,
      );
      return;
    }

    final selection = aiWriterNode!.aiWriterSelection;
    if (selection == null) {
      return;
    }

    if (action case SuggestionAction.discard || SuggestionAction.close) {
      await exit();
      return;
    }

    if (action case SuggestionAction.accept) {
      await _textRobot.persist();
      final nodes = editorState.getNodesInSelection(selection);
      final transaction = editorState.transaction..deleteNodes(nodes);
      await editorState.apply(
        transaction,
        options: const ApplyOptions(recordUndo: false),
        withUpdateSelection: false,
      );
    }

    if (action case SuggestionAction.keep) {
      await _textRobot.persist();
    }

    if (action case SuggestionAction.insertBelow) {
      if (state case final ReadyAiWriterState readyState
          when readyState.markdownText.isNotEmpty) {
        final transaction = editorState.transaction;
        final position = ensurePreviousNodeIsEmptyParagraph(
          editorState,
          aiWriterNode!,
          transaction,
        );
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
          withUpdateSelection: false,
        );
        _textRobot.start(position: position);
        await _textRobot.persist(markdownText: readyState.markdownText);
      } else {
        await _textRobot.persist();
      }

      final transaction = editorState.transaction;
      formatSelection(
        editorState,
        selection,
        transaction,
        ApplySuggestionFormatType.clear,
      );
      await editorState.apply(
        transaction,
        options: const ApplyOptions(recordUndo: false),
        withUpdateSelection: false,
      );
    }

    await removeAiWriterNode(editorState, aiWriterNode!);
    aiWriterNode = null;
    emit(IdleAiWriterState());
  }

  bool hasUnusedResponse() {
    return switch (state) {
      ReadyAiWriterState(
        isFirstRun: final isInitial,
        markdownText: final markdownText,
      ) =>
        !isInitial && (markdownText.isNotEmpty || _textRobot.hasAnyResult),
      GeneratingAiWriterState() => true,
      _ => false,
    };
  }

  void submit(
    String prompt,
    PredefinedFormat? format,
  ) async {
    if (aiWriterNode == null) {
      return;
    }
    final command = AiWriterCommand.userQuestion;
    _previousPrompt = (prompt, format);

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: prompt,
      format: format,
      history: records,
      sourceIds: selectedSourcesNotifier.value,
      completionType: command.toCompletionType(),
      onStart: () async {
        final transaction = editorState.transaction;
        final position = ensurePreviousNodeIsEmptyParagraph(
          editorState,
          aiWriterNode!,
          transaction,
        );
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
          withUpdateSelection: false,
        );
        _textRobot.start(position: position);
        records.add(
          AiWriterRecord.user(content: prompt),
        );
      },
      processMessage: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          updateSelection: false,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
        onAppendToDocument?.call();
      },
      processAssistMessage: (text) async {
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            GeneratingAiWriterState(
              command,
              taskId: generatingState.taskId,
              markdownText: generatingState.markdownText + text,
            ),
          );
        }
      },
      onEnd: () async {
        if (state case final GeneratingAiWriterState generatingState) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(
            ReadyAiWriterState(
              command,
              isFirstRun: false,
              markdownText: generatingState.markdownText,
            ),
          );
          records.add(
            AiWriterRecord.ai(content: _textRobot.markdownText),
          );
        }
      },
      onError: (error) async {
        emit(ErrorAiWriterState(command, error: error));
        records.add(
          AiWriterRecord.ai(content: _textRobot.markdownText),
        );
      },
    );

    if (stream != null) {
      emit(
        GeneratingAiWriterState(
          command,
          taskId: stream.$1,
        ),
      );
    }
  }

  Future<void> _startContinueWriting(
    AiWriterCommand command,
    PredefinedFormat? predefinedFormat, {
    required bool isImmediateRun,
  }) async {
    if (aiWriterNode == null) {
      return;
    }
    final cursorPosition = aiWriterNode?.aiWriterSelection?.start;
    if (cursorPosition == null) {
      return;
    }
    final selection = Selection(
      start: Position(path: [0]),
      end: cursorPosition,
    ).normalized;

    String text = (await editorState.getMarkdownInSelection(selection)).trim();
    if (text.isEmpty) {
      final view = await ViewBackendService.getView(documentId).toNullable();
      if (view == null ||
          view.name.isEmpty ||
          view.name == LocaleKeys.menuAppHeader_defaultNewPageName.tr()) {
        final stateCopy = state;
        emit(
          DocumentContentEmptyAiWriterState(
            command,
            onConfirm: () {
              if (isImmediateRun) {
                removeAiWriterNode(editorState, aiWriterNode!);
              }
            },
          ),
        );
        emit(stateCopy);
        return;
      } else {
        text = view.name;
      }
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: text,
      completionType: command.toCompletionType(),
      history: records,
      onStart: () async {
        final transaction = editorState.transaction;
        final position = ensurePreviousNodeIsEmptyParagraph(
          editorState,
          aiWriterNode!,
          transaction,
        );
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
          withUpdateSelection: false,
        );
        _textRobot.start(position: position);
      },
      processMessage: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          updateSelection: false,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
        onAppendToDocument?.call();
      },
      processAssistMessage: (text) async {
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            GeneratingAiWriterState(
              command,
              taskId: generatingState.taskId,
              markdownText: generatingState.markdownText + text,
            ),
          );
        }
      },
      onEnd: () async {
        if (state case final GeneratingAiWriterState generatingState) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(
            ReadyAiWriterState(
              command,
              isFirstRun: false,
              markdownText: generatingState.markdownText,
            ),
          );
        }
        records.add(
          AiWriterRecord.ai(content: _textRobot.markdownText),
        );
      },
      onError: (error) async {
        emit(ErrorAiWriterState(command, error: error));
        records.add(
          AiWriterRecord.ai(content: _textRobot.markdownText),
        );
      },
    );
    if (stream != null) {
      emit(
        GeneratingAiWriterState(command, taskId: stream.$1),
      );
    }
  }

  Future<void> _startSuggestingEdits(
    AiWriterCommand command,
    PredefinedFormat? predefinedFormat,
  ) async {
    if (aiWriterNode == null) {
      return;
    }
    final selection = aiWriterNode?.aiWriterSelection;
    if (selection == null) {
      return;
    }

    acceptReplacesOriginal = true;

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: await editorState.getMarkdownInSelection(selection),
      completionType: command.toCompletionType(),
      history: records,
      onStart: () async {
        final transaction = editorState.transaction;
        formatSelection(
          editorState,
          selection,
          transaction,
          ApplySuggestionFormatType.original,
        );
        final position = ensurePreviousNodeIsEmptyParagraph(
          editorState,
          aiWriterNode!,
          transaction,
        );
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
          withUpdateSelection: false,
        );
        _textRobot.start(position: position);
      },
      processMessage: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          updateSelection: false,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
        onAppendToDocument?.call();
      },
      processAssistMessage: (text) async {
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            GeneratingAiWriterState(
              command,
              taskId: generatingState.taskId,
              markdownText: generatingState.markdownText + text,
            ),
          );
        }
      },
      onEnd: () async {
        if (state case final GeneratingAiWriterState generatingState) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(
            ReadyAiWriterState(
              command,
              isFirstRun: false,
              markdownText: generatingState.markdownText,
            ),
          );
          records.add(
            AiWriterRecord.ai(content: _textRobot.markdownText),
          );
        }
      },
      onError: (error) async {
        emit(ErrorAiWriterState(command, error: error));
        records.add(
          AiWriterRecord.ai(content: _textRobot.markdownText),
        );
      },
    );
    if (stream != null) {
      emit(
        GeneratingAiWriterState(command, taskId: stream.$1),
      );
    }
  }

  Future<void> _startInforming(
    AiWriterCommand command,
    PredefinedFormat? predefinedFormat,
  ) async {
    if (aiWriterNode == null) {
      return;
    }
    final selection = aiWriterNode?.aiWriterSelection;
    if (selection == null) {
      return;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: await editorState.getMarkdownInSelection(selection),
      completionType: command.toCompletionType(),
      history: records,
      onStart: () async {},
      processMessage: (text) async {
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            GeneratingAiWriterState(
              command,
              taskId: generatingState.taskId,
              markdownText: generatingState.markdownText + text,
            ),
          );
        }
      },
      processAssistMessage: (_) async {},
      onEnd: () async {
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            ReadyAiWriterState(
              command,
              isFirstRun: false,
              markdownText: generatingState.markdownText,
            ),
          );
          records.add(
            AiWriterRecord.ai(content: generatingState.markdownText),
          );
        }
      },
      onError: (error) async {
        if (state case final GeneratingAiWriterState generatingState) {
          records.add(
            AiWriterRecord.ai(content: generatingState.markdownText),
          );
        }
        emit(ErrorAiWriterState(command, error: error));
      },
    );
    if (stream != null) {
      emit(
        GeneratingAiWriterState(command, taskId: stream.$1),
      );
    }
  }
}

mixin RegisteredAiWriter {
  AiWriterCommand get command;
}

sealed class AiWriterState {
  const AiWriterState();
}

class IdleAiWriterState extends AiWriterState {
  const IdleAiWriterState();
}

class ReadyAiWriterState extends AiWriterState with RegisteredAiWriter {
  const ReadyAiWriterState(
    this.command, {
    required this.isFirstRun,
    this.markdownText = '',
  });

  @override
  final AiWriterCommand command;

  final bool isFirstRun;
  final String markdownText;
}

class GeneratingAiWriterState extends AiWriterState with RegisteredAiWriter {
  const GeneratingAiWriterState(
    this.command, {
    required this.taskId,
    this.progress = '',
    this.markdownText = '',
  });

  @override
  final AiWriterCommand command;

  final String taskId;
  final String progress;
  final String markdownText;
}

class ErrorAiWriterState extends AiWriterState with RegisteredAiWriter {
  const ErrorAiWriterState(
    this.command, {
    required this.error,
  });

  @override
  final AiWriterCommand command;

  final AIError error;
}

class DocumentContentEmptyAiWriterState extends AiWriterState
    with RegisteredAiWriter {
  const DocumentContentEmptyAiWriterState(
    this.command, {
    required this.onConfirm,
  });

  @override
  final AiWriterCommand command;

  final void Function() onConfirm;
}
