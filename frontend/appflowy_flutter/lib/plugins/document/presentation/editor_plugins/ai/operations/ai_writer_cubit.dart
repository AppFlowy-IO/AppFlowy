import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../base/markdown_text_robot.dart';
import 'ai_writer_block_operations.dart';
import 'ai_writer_entities.dart';
import 'ai_writer_node_extension.dart';

class AiWriterCubit extends Cubit<AiWriterState> {
  AiWriterCubit({
    required this.documentId,
    required this.editorState,
    required this.getAiWriterNode,
    required this.initialCommand,
    AppFlowyAIService? aiService,
  })  : _aiService = aiService ?? AppFlowyAIService(),
        _textRobot = MarkdownTextRobot(editorState: editorState),
        selectedSourcesNotifier = ValueNotifier([documentId]),
        super(
          ReadyAiWriterState(
            initialCommand,
            isInitial: true,
          ),
        );

  final String documentId;
  final EditorState editorState;
  final Node Function() getAiWriterNode;
  final AiWriterCommand initialCommand;
  final AppFlowyAIService _aiService;
  final MarkdownTextRobot _textRobot;

  final ValueNotifier<List<String>> selectedSourcesNotifier;
  (String, PredefinedFormat?)? _previousPrompt;

  @override
  Future<void> close() async {
    selectedSourcesNotifier.dispose();
    await super.close();
  }

  void init() => runCommand(initialCommand);

  void submit(
    String prompt,
    PredefinedFormat? format,
  ) async {
    final command = AiWriterCommand.userQuestion;
    final node = getAiWriterNode();
    _previousPrompt = (prompt, format);

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: prompt,
      format: format,
      sourceIds: selectedSourcesNotifier.value,
      completionType: command.toCompletionType(),
      onStart: () async {
        final transaction = editorState.transaction;
        final position =
            ensurePreviousNodeIsEmptyParagraph(editorState, node, transaction);
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
        );
        _textRobot.start(position: position);
      },
      onProcess: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
      },
      onEnd: () async {
        await _textRobot.stop(
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
        emit(ReadyAiWriterState(command, isInitial: false));
      },
      onError: (error) async {
        emit(ErrorAiWriterState(state.command, error: error));
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

  void runCommand(
    AiWriterCommand command, {
    bool isRetry = false,
  }) async {
    switch (command) {
      case AiWriterCommand.continueWriting:
        await _startContinueWriting(command);
        break;
      case AiWriterCommand.fixSpellingAndGrammar:
      case AiWriterCommand.improveWriting:
      case AiWriterCommand.makeLonger:
      case AiWriterCommand.makeShorter:
        await _startSuggestingEdits(command);
        break;
      case AiWriterCommand.explain:
        await _startInforming(command);
        break;
      case AiWriterCommand.userQuestion:
        if (isRetry && _previousPrompt != null) {
          submit(_previousPrompt!.$1, _previousPrompt!.$2);
        }
        break;
    }
  }

  void stopStream() async {
    if (state is! GeneratingAiWriterState) {
      return;
    }
    final generatingState = state as GeneratingAiWriterState;
    await AIEventStopCompleteText(
      CompleteTextTaskPB(
        taskId: generatingState.taskId,
      ),
    ).send();
    emit(
      ReadyAiWriterState(
        state.command,
        isInitial: false,
        markdownText: generatingState.markdownText,
      ),
    );
  }

  void exit() async {
    await _textRobot.discard();
    final selection = getAiWriterNode().aiWriterSelection;
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
    await removeAiWriterNode(editorState, getAiWriterNode());
  }

  void runResponseAction(SuggestionAction action) async {
    if (action case SuggestionAction.rewrite || SuggestionAction.tryAgain) {
      await _textRobot.discard();
      _textRobot.reset();
      runCommand(state.command, isRetry: true);
      return;
    }

    final selection = getAiWriterNode().aiWriterSelection;
    if (selection == null) {
      return;
    }

    if (action case SuggestionAction.discard || SuggestionAction.close) {
      await _textRobot.discard();

      final transaction = editorState.transaction;
      formatSelection(
        editorState,
        selection,
        transaction,
        ApplySuggestionFormatType.clear,
      );
      await editorState.apply(
        transaction,
        options: const ApplyOptions(inMemoryUpdate: true, recordUndo: false),
      );
    }

    if (action case SuggestionAction.accept || SuggestionAction.keep) {
      await _textRobot.persist();

      if (state.command.acceptWillReplace) {
        final nodes = editorState.getNodesInSelection(selection);
        final transaction = editorState.transaction..deleteNodes(nodes);
        await editorState.apply(
          transaction,
          options: const ApplyOptions(recordUndo: false),
          withUpdateSelection: false,
        );
      }
    }

    if (action case SuggestionAction.insertBelow) {
      if (state case final ReadyAiWriterState readyState
          when readyState.markdownText.isNotEmpty) {
        final transaction = editorState.transaction;
        final position = ensurePreviousNodeIsEmptyParagraph(
          editorState,
          getAiWriterNode(),
          transaction,
        );
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
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

    await removeAiWriterNode(editorState, getAiWriterNode());
  }

  bool hasUnusedResponse() {
    return switch (state) {
      ReadyAiWriterState(
        isInitial: final isInitial,
        markdownText: final markdownText,
      ) =>
        !isInitial && (markdownText.isNotEmpty || _textRobot.hasAnyResult),
      GeneratingAiWriterState() => true,
      _ => false,
    };
  }

  Future<void> _startContinueWriting(
    AiWriterCommand command,
  ) async {
    final node = getAiWriterNode();

    final cursorPosition = getAiWriterNode().aiWriterSelection?.start;
    if (cursorPosition == null) {
      return;
    }
    final selection = Selection(
      start: Position(path: [0]),
      end: cursorPosition,
    ).normalized;

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: await editorState.getMarkdownInSelection(selection),
      completionType: command.toCompletionType(),
      onStart: () async {
        final transaction = editorState.transaction;
        final position =
            ensurePreviousNodeIsEmptyParagraph(editorState, node, transaction);
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
        );
        _textRobot.start(position: position);
      },
      onProcess: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
      },
      onEnd: () async {
        editorState.service.keyboardService?.enable();
        if (state case GeneratingAiWriterState _) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(ReadyAiWriterState(command, isInitial: false));
        }
      },
      onError: (error) async {
        editorState.service.keyboardService?.enable();
        emit(ErrorAiWriterState(command, error: error));
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
  ) async {
    final node = getAiWriterNode();
    final selection = node.aiWriterSelection;
    if (selection == null) {
      return;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: await editorState.getMarkdownInSelection(selection),
      completionType: command.toCompletionType(),
      onStart: () async {
        final transaction = editorState.transaction;
        formatSelection(
          editorState,
          selection,
          transaction,
          ApplySuggestionFormatType.original,
        );
        final position =
            ensurePreviousNodeIsEmptyParagraph(editorState, node, transaction);
        transaction.afterSelection = null;
        await editorState.apply(
          transaction,
          options: ApplyOptions(
            inMemoryUpdate: true,
            recordUndo: false,
          ),
        );
        _textRobot.start(position: position);
      },
      onProcess: (text) async {
        await _textRobot.appendMarkdownText(
          text,
          attributes: ApplySuggestionFormatType.replace.attributes,
        );
      },
      onEnd: () async {
        if (state is GeneratingAiWriterState) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(
            ReadyAiWriterState(
              command,
              isInitial: false,
            ),
          );
        }
      },
      onError: (error) async {
        editorState.service.keyboardService?.enable();
        emit(ErrorAiWriterState(command, error: error));
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
  ) async {
    final node = getAiWriterNode();
    final selection = node.aiWriterSelection;
    if (selection == null) {
      return;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: await editorState.getMarkdownInSelection(selection),
      completionType: command.toCompletionType(),
      onStart: () async {},
      onProcess: (text) async {
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
        editorState.service.keyboardService?.enable();
        if (state case final GeneratingAiWriterState generatingState) {
          emit(
            ReadyAiWriterState(
              command,
              isInitial: false,
              markdownText: generatingState.markdownText,
            ),
          );
        }
      },
      onError: (error) async {
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

sealed class AiWriterState {
  const AiWriterState(this.command);

  final AiWriterCommand command;
}

class ReadyAiWriterState extends AiWriterState {
  const ReadyAiWriterState(
    super.command, {
    required this.isInitial,
    this.markdownText = '',
  });

  final bool isInitial;
  final String markdownText;
}

class GeneratingAiWriterState extends AiWriterState {
  const GeneratingAiWriterState(
    super.command, {
    required this.taskId,
    this.progress = '',
    this.markdownText = '',
  });

  final String taskId;
  final String progress;
  final String markdownText;
}

class ErrorAiWriterState extends AiWriterState {
  const ErrorAiWriterState(
    super.command, {
    required this.error,
  });

  final AIError error;
}
