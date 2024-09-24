import 'dart:async';

import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/ai_client.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/ai_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'smart_edit_bloc.freezed.dart';

class SmartEditBloc extends Bloc<SmartEditEvent, SmartEditState> {
  SmartEditBloc({
    required this.node,
    required this.editorState,
    required this.action,
  }) : super(
          SmartEditState.initial(action),
        ) {
    on<SmartEditEvent>((event, emit) async {
      await event.when(
        initial: () async {
          aiRepository = await getIt.getAsync<AIRepository>();
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
        update: (result, isLoading) async {
          emit(
            state.copyWith(
              result: result,
              loading: isLoading,
            ),
          );
        },
      );
    });
  }

  final Node node;
  final EditorState editorState;
  final SmartEditAction action;

  // used to wait for the aiRepository to be initialized
  final aiRepositoryCompleter = Completer();
  late final AIRepository aiRepository;

  bool isCanceled = false;

  Future<void> _requestCompletions({
    bool rewrite = false,
  }) async {
    await aiRepositoryCompleter.future;

    if (rewrite) {
      add(const SmartEditEvent.update('', true));
    }

    Log.info('[smart_edit] request completions');

    final content = node.attributes[SmartEditBlockKeys.content] as String;
    await aiRepository.streamCompletion(
      text: content,
      completionType: completionTypeFromInt(state.action),
      onStart: () async {
        if (isCanceled) {
          return;
        }
        Log.info('[smart_edit] start generating');
        add(const SmartEditEvent.update('', true));
      },
      onProcess: (text) async {
        if (isCanceled) {
          return;
        }
        // only display the log in debug mode
        if (kDebugMode) {
          Log.debug('[smart_edit] onProcess: $text');
        }
        final newResult = state.result + text;
        add(SmartEditEvent.update(newResult, false));
      },
      onEnd: () async {
        if (isCanceled) {
          return;
        }
        Log.info('[smart_edit] end generating');
        add(SmartEditEvent.update('${state.result}\n', false));
      },
      onError: (error) async {
        if (isCanceled) {
          return;
        }
        Log.info('[smart_edit] onError: $error');
        await _exit();
      },
    );
  }

  Future<void> _insertBelow() async {
    // check the selection is not empty
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    // return if the result is empty
    final result = state.result.trim();
    if (result.isEmpty) {
      return;
    }
    final insertedText = result.split('\n')
      ..removeWhere((element) => element.isEmpty);
    final transaction = editorState.transaction;
    // todo: keep the style of the current node
    transaction.insertNodes(
      selection.end.path.next,
      insertedText.map(
        (e) => paragraphNode(
          text: e,
        ),
      ),
    );
    final start = Position(path: selection.end.path.next);
    final end = Position(
      path: [selection.end.path.next.first + insertedText.length],
    );
    transaction.afterSelection = Selection(
      start: start,
      end: end,
    );
    await editorState.apply(transaction);
  }

  Future<void> _replace() async {
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
}

@freezed
class SmartEditEvent with _$SmartEditEvent {
  const factory SmartEditEvent.initial() = _Initial;
  const factory SmartEditEvent.started() = _Started;
  const factory SmartEditEvent.rewrite() = _Rewrite;
  const factory SmartEditEvent.replace() = _Replace;
  const factory SmartEditEvent.insertBelow() = _InsertBelow;
  const factory SmartEditEvent.cancel() = _Cancel;
  const factory SmartEditEvent.update(String result, bool isLoading) = _Update;
}

@freezed
class SmartEditState with _$SmartEditState {
  const factory SmartEditState({
    required bool loading,
    required String result,
    required SmartEditAction action,
  }) = _SmartEditState;

  factory SmartEditState.initial(SmartEditAction action) => SmartEditState(
        loading: true,
        action: action,
        result: '',
      );
}
