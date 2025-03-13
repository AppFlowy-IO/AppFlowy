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
import 'package:flutter/services.dart';

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
            isFirstRun: true,
          ),
        ) {
    HardwareKeyboard.instance.addHandler(_cancelShortcutHandler);
    editorState.service.keyboardService?.disableShortcuts();
  }

  final String documentId;
  final EditorState editorState;
  final Node Function() getAiWriterNode;
  final AiWriterCommand initialCommand;
  final AppFlowyAIService _aiService;
  final MarkdownTextRobot _textRobot;

  final List<AiWriterRecord> records = [];
  final ValueNotifier<List<String>> selectedSourcesNotifier;
  (String, PredefinedFormat?)? _previousPrompt;
  bool acceptReplacesOriginal = false;

  @override
  Future<void> close() async {
    selectedSourcesNotifier.dispose();
    HardwareKeyboard.instance.removeHandler(_cancelShortcutHandler);
    editorState.service.keyboardService?.enableShortcuts();
    await super.close();
  }

  void init() {
    runCommand(initialCommand, null, isImmediateRun: true);
  }

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
        records.add(
          AiWriterRecord.user(content: prompt),
        );
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
        emit(ReadyAiWriterState(command, isFirstRun: false));
        records.add(
          AiWriterRecord.ai(content: _textRobot.markdownText),
        );
      },
      onError: (error) async {
        emit(ErrorAiWriterState(state.command, error: error));
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

  void runCommand(
    AiWriterCommand command,
    PredefinedFormat? predefinedFormat, {
    bool isImmediateRun = false,
    bool isRetry = false,
  }) async {
    switch (command) {
      case AiWriterCommand.continueWriting:
        await _startContinueWriting(
          command,
          predefinedFormat,
          isImmediateRun: isImmediateRun,
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

  void stopStream() async {
    if (state is! GeneratingAiWriterState) {
      return;
    }
    await _textRobot.stop(
      attributes: ApplySuggestionFormatType.replace.attributes,
    );
    final generatingState = state as GeneratingAiWriterState;
    await AIEventStopCompleteText(
      CompleteTextTaskPB(
        taskId: generatingState.taskId,
      ),
    ).send();
    emit(
      ReadyAiWriterState(
        state.command,
        isFirstRun: false,
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

  void runResponseAction(
    SuggestionAction action, [
    PredefinedFormat? predefinedFormat,
  ]) async {
    if (action case SuggestionAction.rewrite || SuggestionAction.tryAgain) {
      await _textRobot.discard();
      _textRobot.reset();
      runCommand(state.command, predefinedFormat, isRetry: true);
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
        options: const ApplyOptions(recordUndo: false),
      );
    }

    if (action case SuggestionAction.accept || SuggestionAction.keep) {
      await _textRobot.persist();

      if (acceptReplacesOriginal) {
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
        isFirstRun: final isInitial,
        markdownText: final markdownText,
      ) =>
        !isInitial && (markdownText.isNotEmpty || _textRobot.hasAnyResult),
      GeneratingAiWriterState() => true,
      _ => false,
    };
  }

  Future<void> _startContinueWriting(
    AiWriterCommand command,
    PredefinedFormat? predefinedFormat, {
    required bool isImmediateRun,
  }) async {
    final node = getAiWriterNode();

    final cursorPosition = getAiWriterNode().aiWriterSelection?.start;
    if (cursorPosition == null) {
      return;
    }
    final selection = Selection(
      start: Position(path: [0]),
      end: cursorPosition,
    ).normalized;

    String text = await editorState.getMarkdownInSelection(selection);
    if (text.isEmpty) {
      if (state is! ReadyAiWriterState) {
        return;
      }
      final view = await ViewBackendService.getView(documentId).toNullable();
      if (view == null ||
          view.name.isEmpty ||
          view.name == LocaleKeys.menuAppHeader_defaultNewPageName.tr()) {
        final readyState = state as ReadyAiWriterState;
        emit(
          FailedContinueWritingAiWriterState(
            command,
            onConfirm: () {
              if (isImmediateRun) {
                removeAiWriterNode(editorState, node);
              }
            },
          ),
        );
        emit(readyState);
        return;
      } else {
        text += view.name;
      }
    }

    final stream = await _aiService.streamCompletion(
      objectId: documentId,
      text: text,
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
        if (state case GeneratingAiWriterState _) {
          await _textRobot.stop(
            attributes: ApplySuggestionFormatType.replace.attributes,
          );
          emit(ReadyAiWriterState(command, isFirstRun: false));
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
    final node = getAiWriterNode();
    final selection = node.aiWriterSelection;
    if (selection == null) {
      return;
    }

    acceptReplacesOriginal = true;

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
              isFirstRun: false,
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

  bool _cancelShortcutHandler(KeyEvent event) {
    if (event is! KeyUpEvent) {
      return false;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        if (state case GeneratingAiWriterState _) {
          stopStream();
        } else if (hasUnusedResponse()) {
          final saveState = state;
          emit(
            FailedContinueWritingAiWriterState(
              state.command,
              onConfirm: () {
                stopStream();
                exit();
              },
            ),
          );
          emit(saveState);
        } else {
          stopStream();
          exit();
        }
        return true;
      case LogicalKeyboardKey.keyC
          when HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlLeft):
        if (state case GeneratingAiWriterState _) {
          stopStream();
        }
        return true;
      default:
        break;
    }

    return false;
  }
}

sealed class AiWriterState {
  const AiWriterState(this.command);

  final AiWriterCommand command;
}

class ReadyAiWriterState extends AiWriterState {
  const ReadyAiWriterState(
    super.command, {
    required this.isFirstRun,
    this.markdownText = '',
  });

  final bool isFirstRun;
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

class FailedContinueWritingAiWriterState extends AiWriterState {
  const FailedContinueWritingAiWriterState(
    super.command, {
    required this.onConfirm,
  });

  final void Function() onConfirm;
}

class DiscardResponseAiWriterState extends AiWriterState {
  const DiscardResponseAiWriterState(
    super.command, {
    required this.onDiscard,
  });

  final void Function() onDiscard;
}
