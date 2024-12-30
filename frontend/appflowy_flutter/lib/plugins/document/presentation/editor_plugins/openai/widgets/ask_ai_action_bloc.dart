import 'dart:async';

import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ask_ai_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/user/application/ai_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ask_ai_action_bloc.freezed.dart';

enum AskAIReplacementType {
  markdown,
  plainText,
}

const _defaultReplacementType = AskAIReplacementType.markdown;

class AskAIActionBloc extends Bloc<AskAIEvent, AskAIState> {
  AskAIActionBloc({
    required this.node,
    required this.editorState,
    required this.action,
    this.enableLogging = true,
  }) : super(
          AskAIState.initial(action),
        ) {
    on<AskAIEvent>((event, emit) async {
      await event.when(
        initial: (aiRepositoryProvider) async {
          aiRepository = await aiRepositoryProvider;
          aiRepositoryCompleter.complete();
        },
        started: () async {
          await _requestCompletions();
        },
        rewrite: () async {
          await _requestCompletions(rewrite: true);
        },
        replace: () async {
          await _replace();
          await _exit();
        },
        insertBelow: () async {
          await _insertBelow();
          await _exit();
        },
        cancel: () async {
          isCanceled = true;
          await _exit();
        },
        update: (result, isLoading, aiError) {
          emit(
            state.copyWith(
              result: result,
              loading: isLoading,
              requestError: aiError,
            ),
          );
        },
      );
    });
  }

  final Node node;
  final EditorState editorState;
  final AskAIAction action;
  final bool enableLogging;
  // used to wait for the aiRepository to be initialized
  final aiRepositoryCompleter = Completer();
  late final AIRepository aiRepository;

  bool isCanceled = false;

  Future<void> _requestCompletions({
    bool rewrite = false,
  }) async {
    await aiRepositoryCompleter.future;

    if (rewrite) {
      add(const AskAIEvent.update('', true, null));
    }

    if (enableLogging) {
      Log.info('[smart_edit] request completions');
    }

    final content = node.attributes[AskAIBlockKeys.content] as String;
    await aiRepository.streamCompletion(
      text: content,
      completionType: completionTypeFromInt(state.action),
      onStart: () async {
        if (isCanceled) {
          return;
        }
        if (enableLogging) {
          Log.info('[smart_edit] start generating');
        }
        add(const AskAIEvent.update('', true, null));
      },
      onProcess: (text) async {
        if (isCanceled) {
          return;
        }
        // only display the log in debug mode
        if (enableLogging) {
          Log.debug('[smart_edit] onProcess: $text');
        }
        final newResult = state.result + text;
        add(AskAIEvent.update(newResult, false, null));
      },
      onEnd: () async {
        if (isCanceled) {
          return;
        }
        if (enableLogging) {
          Log.info('[smart_edit] end generating');
        }
        add(AskAIEvent.update('${state.result}\n', false, null));
      },
      onError: (error) async {
        if (isCanceled) {
          return;
        }
        if (enableLogging) {
          Log.info('[smart_edit] onError: $error');
        }
        add(AskAIEvent.update('', false, error));
        await _exit();
        await _clearSelection();
      },
    );
  }

  Future<void> _insertBelow() async {
    // check the selection is not empty
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    final nodes = customMarkdownToDocument(state.result)
        .root
        .children
        .map((e) => e.deepCopy())
        .toList();
    final insertedPath = selection.end.path.next;
    final transaction = editorState.transaction;
    transaction.insertNodes(
      insertedPath,
      nodes,
    );
    final lastDeltaLength = nodes.lastOrNull?.delta?.length ?? 0;
    transaction.afterSelection = Selection(
      start: Position(path: insertedPath),
      end: Position(
        path: insertedPath.nextNPath(nodes.length - 1),
        offset: lastDeltaLength,
      ),
    );
    await editorState.apply(transaction);
  }

  Future<void> _replace() async {
    switch (_defaultReplacementType) {
      case AskAIReplacementType.markdown:
        await _replaceWithMarkdown();
      case AskAIReplacementType.plainText:
        await _replaceWithPlainText();
    }
  }

  Future<void> _replaceWithMarkdown() async {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }

    final nodes = customMarkdownToDocument(state.result)
        .root
        .children
        .map((e) => e.deepCopy())
        .toList();
    if (nodes.isEmpty) {
      return;
    }

    final nodesInSelection = editorState.getNodesInSelection(selection);
    final transaction = editorState.transaction;
    transaction.insertNodes(
      selection.start.path,
      nodes,
    );
    transaction.deleteNodes(nodesInSelection);
    transaction.afterSelection = Selection(
      start: selection.start,
      end: Position(
        path: selection.start.path.nextNPath(nodes.length - 1),
        offset: nodes.lastOrNull?.delta?.length ?? 0,
      ),
    );
    await editorState.apply(transaction);
  }

  Future<void> _replaceWithPlainText() async {
    final result = state.result.trim();
    if (result.isEmpty) {
      return;
    }

    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    final nodes = editorState.getNodesInSelection(selection);
    if (nodes.isEmpty || !nodes.every((element) => element.delta != null)) {
      return;
    }

    final replaceTexts = result.split('\n')
      ..removeWhere((element) => element.isEmpty);
    final transaction = editorState.transaction;
    transaction.replaceTexts(
      nodes,
      selection,
      replaceTexts,
    );
    await editorState.apply(transaction);

    int endOffset = replaceTexts.last.length;
    if (replaceTexts.length == 1) {
      endOffset += selection.start.offset;
    }
    final end = Position(
      path: [selection.start.path.first + replaceTexts.length - 1],
      offset: endOffset,
    );
    editorState.selection = Selection(
      start: selection.start,
      end: end,
    );
  }

  Future<void> _exit() async {
    final transaction = editorState.transaction..deleteNode(node);
    await editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordUndo: false,
      ),
    );
  }

  Future<void> _clearSelection() async {
    final selection = editorState.selection;
    if (selection == null) {
      return;
    }
    editorState.selection = null;
  }
}

@freezed
class AskAIEvent with _$AskAIEvent {
  const factory AskAIEvent.initial(
    Future<AIRepository> aiRepositoryProvider,
  ) = _Initial;
  const factory AskAIEvent.started() = _Started;
  const factory AskAIEvent.rewrite() = _Rewrite;
  const factory AskAIEvent.replace() = _Replace;
  const factory AskAIEvent.insertBelow() = _InsertBelow;
  const factory AskAIEvent.cancel() = _Cancel;
  const factory AskAIEvent.update(
    String result,
    bool isLoading,
    AIError? error,
  ) = _Update;
}

@freezed
class AskAIState with _$AskAIState {
  const factory AskAIState({
    required bool loading,
    required String result,
    required AskAIAction action,
    @Default(null) AIError? requestError,
  }) = _AskAIState;

  factory AskAIState.initial(AskAIAction action) => AskAIState(
        loading: true,
        action: action,
        result: '',
      );
}
