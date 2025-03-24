import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
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

  @override
  Future<void> close() async {
    selectedSourcesNotifier.dispose();
    await super.close();
  }

  Future<void> exit({
    bool withDiscard = true,
    bool withUnformat = true,
  }) async {
    if (withDiscard) {
      await _textRobot.discard();
    }
    _textRobot.reset();
    onRemoveNode?.call();
    records.clear();
    selectedSourcesNotifier.value = [documentId];
    emit(IdleAiWriterState());

    if (withUnformat) {
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
    }
    if (aiWriterNode != null) {
      await removeAiWriterNode(editorState, aiWriterNode!);
      aiWriterNode = null;
    }
  }

  void register(Node node) async {
    if (node.isAiWriterInitialized) {
      return;
    }
    if (aiWriterNode != null && node.id != aiWriterNode!.id) {
      await removeAiWriterNode(editorState, node);
      return;
    }

    aiWriterNode = node;
    onCreateNode?.call();

    await setAiWriterNodeIsInitialized(editorState, node);

    final command = node.aiWriterCommand;
    final (run, prompt) = await _addSelectionTextToRecords(command);

    if (!run) {
      await exit();
      return;
    }

    runCommand(command, prompt, null);
  }

  void runCommand(
    AiWriterCommand command,
    String prompt,
    PredefinedFormat? predefinedFormat,
  ) async {
    if (aiWriterNode == null) {
      return;
    }

    switch (command) {
      case AiWriterCommand.continueWriting:
        await _startContinueWriting(
          command,
          predefinedFormat,
        );
        break;
      case AiWriterCommand.fixSpellingAndGrammar:
      case AiWriterCommand.improveWriting:
      case AiWriterCommand.makeLonger:
      case AiWriterCommand.makeShorter:
        await _startSuggestingEdits(command, prompt, predefinedFormat);
        break;
      case AiWriterCommand.explain:
        await _startInforming(command, prompt, predefinedFormat);
        break;
      case AiWriterCommand.userQuestion when prompt.isNotEmpty:
        _startAskingQuestion(prompt, predefinedFormat);
        break;
      case AiWriterCommand.userQuestion:
        emit(
          ReadyAiWriterState(AiWriterCommand.userQuestion, isFirstRun: true),
        );
        break;
    }
  }

  void _retry({
    required PredefinedFormat? predefinedFormat,
  }) async {
    final lastQuestion =
        records.lastWhereOrNull((record) => record.role == AiRole.user);

    if (lastQuestion != null && state is RegisteredAiWriter) {
      await _textRobot.discard();
      _textRobot.reset();
      runCommand(
        (state as RegisteredAiWriter).command,
        lastQuestion.content,
        lastQuestion.format,
      );
    }
  }

  Future<void> stopStream() async {
    if (aiWriterNode == null) {
      return;
    }

    if (state is GeneratingAiWriterState) {
      final generatingState = state as GeneratingAiWriterState;

      await _textRobot.stop(
        attributes: ApplySuggestionFormatType.replace.attributes,
      );

      if (_textRobot.hasAnyResult) {
        records.add(AiWriterRecord.ai(content: _textRobot.markdownText));
      }

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

    if (action case SuggestionAction.rewrite || SuggestionAction.tryAgain) {
      _retry(predefinedFormat: predefinedFormat);
      return;
    }
    if (action case SuggestionAction.discard || SuggestionAction.close) {
      await exit();
      return;
    }

    final selection = aiWriterNode?.aiWriterSelection;
    if (selection == null) {
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
      await exit(withDiscard: false, withUnformat: false);
      return;
    }

    if (action case SuggestionAction.keep) {
      await _textRobot.persist();
    }

    if (action case SuggestionAction.insertBelow) {
      if (state is! ReadyAiWriterState) {
        return;
      }
      final command = (state as ReadyAiWriterState).command;
      final markdownText = (state as ReadyAiWriterState).markdownText;
      if (command == AiWriterCommand.explain && markdownText.isNotEmpty) {
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
        await _textRobot.persist(markdownText: markdownText);
      } else if (_textRobot.hasAnyResult) {
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

    await exit(withDiscard: false);
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

  Future<(bool, String)> _addSelectionTextToRecords(
    AiWriterCommand command,
  ) async {
    final node = aiWriterNode;
    if (node == null) {
      return (false, '');
    }
    final selection = node.aiWriterSelection?.normalized;
    if (selection == null) {
      return (false, '');
    }

    if (command == AiWriterCommand.continueWriting) {
      return (true, '');
    } else {
      if (selection.isCollapsed) {
        return (true, '');
      } else {
        final selectionText =
            await editorState.getMarkdownInSelection(selection);

        if (command == AiWriterCommand.userQuestion) {
          records.add(
            AiWriterRecord.user(content: selectionText, format: null),
          );
          return (true, '');
        } else {
          return (true, selectionText);
        }
      }
    }
  }

  Future<String> _getDocumentContentFromTopToPosition(Position position) async {
    final beginningToCursorSelection = Selection(
      start: Position(path: [0]),
      end: position,
    ).normalized;

    final documentText =
        (await editorState.getMarkdownInSelection(beginningToCursorSelection))
            .trim();

    final view = await ViewBackendService.getView(documentId).toNullable();
    final viewName = view?.name ?? '';

    return "$viewName\n$documentText".trim();
  }

  void _startAskingQuestion(
    String prompt,
    PredefinedFormat? format,
  ) async {
    if (aiWriterNode == null) {
      return;
    }
    final command = AiWriterCommand.userQuestion;

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
          AiWriterRecord.user(
            content: prompt,
            format: format,
          ),
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
    PredefinedFormat? predefinedFormat,
  ) async {
    final position = aiWriterNode?.aiWriterSelection?.start;
    if (position == null) {
      return;
    }
    final text = await _getDocumentContentFromTopToPosition(position);

    if (text.isEmpty) {
      final stateCopy = state;
      emit(DocumentContentEmptyAiWriterState(command, onConfirm: exit));
      emit(stateCopy);
      return;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: text,
      completionType: command.toCompletionType(),
      history: records,
      sourceIds: selectedSourcesNotifier.value,
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
        records.add(
          AiWriterRecord.user(
            content: text,
            format: predefinedFormat,
          ),
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
    String prompt,
    PredefinedFormat? predefinedFormat,
  ) async {
    final selection = aiWriterNode?.aiWriterSelection;
    if (selection == null) {
      return;
    }
    if (prompt.isEmpty) {
      prompt = records.removeAt(0).content;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: prompt,
      completionType: command.toCompletionType(),
      history: records,
      sourceIds: selectedSourcesNotifier.value,
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
        records.add(
          AiWriterRecord.user(
            content: prompt,
            format: predefinedFormat,
          ),
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
        GeneratingAiWriterState(command, taskId: stream.$1),
      );
    }
  }

  Future<void> _startInforming(
    AiWriterCommand command,
    String prompt,
    PredefinedFormat? predefinedFormat,
  ) async {
    final selection = aiWriterNode?.aiWriterSelection;
    if (selection == null) {
      return;
    }
    if (prompt.isEmpty) {
      prompt = records.removeAt(0).content;
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: prompt,
      completionType: command.toCompletionType(),
      history: records,
      sourceIds: selectedSourcesNotifier.value,
      onStart: () async {
        records.add(
          AiWriterRecord.user(
            content: prompt,
            format: predefinedFormat,
          ),
        );
      },
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
