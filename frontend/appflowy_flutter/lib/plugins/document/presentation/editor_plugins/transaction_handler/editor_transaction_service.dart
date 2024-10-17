import 'dart:async';

import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/child_page_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _transactionHandlers = <EditorTransactionHandler>[
  if (FeatureFlag.inlineSubPageMention.isOn) ...[
    SubPageTransactionHandler(),
    ChildPageTransactionHandler(),
  ],
];

/// Handles delegating transactions to appropriate handlers.
///
/// Such as the [ChildPageTransactionHandler] for inline child pages.
///
class EditorTransactionService extends StatefulWidget {
  const EditorTransactionService({
    super.key,
    required this.viewId,
    required this.editorState,
    required this.child,
  });

  final String viewId;
  final EditorState editorState;
  final Widget child;

  @override
  State<EditorTransactionService> createState() =>
      _EditorTransactionServiceState();
}

class _EditorTransactionServiceState extends State<EditorTransactionService> {
  StreamSubscription<(TransactionTime, Transaction)>? transactionSubscription;

  bool isUndoRedo = false;
  bool isPaste = false;
  bool isDraggingNode = false;

  @override
  void initState() {
    super.initState();
    transactionSubscription =
        widget.editorState.transactionStream.listen(onEditorTransaction);
    EditorNotification.addListener(onEditorNotification);
  }

  @override
  void dispose() {
    EditorNotification.removeListener(onEditorNotification);
    transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void onEditorNotification(EditorNotificationType type) {
    if ([EditorNotificationType.undo, EditorNotificationType.redo]
        .contains(type)) {
      isUndoRedo = true;
    } else if (type == EditorNotificationType.paste) {
      isPaste = true;
    } else if (type == EditorNotificationType.dragStart) {
      isDraggingNode = true;
    } else if (type == EditorNotificationType.dragEnd) {
      isDraggingNode = false;
    }

    if (type == EditorNotificationType.undo) {
      undoCommand.execute(widget.editorState);
    } else if (type == EditorNotificationType.redo) {
      redoCommand.execute(widget.editorState);
    } else if (type == EditorNotificationType.exitEditing &&
        widget.editorState.selection != null) {
      widget.editorState.selection = null;
    }
  }

  /// Collects all nodes of a certain type, including those that are nested.
  ///
  List<Node> collectMatchingNodes(
    Node node,
    String type, [
    List<String> additionalTypes = const [],
  ]) {
    final List<Node> matchingNodes = [];
    if (node.type == type || additionalTypes.contains(node.type)) {
      matchingNodes.add(node);
    }

    for (final child in node.children) {
      matchingNodes.addAll(collectMatchingNodes(child, type, additionalTypes));
    }

    return matchingNodes;
  }

  void onEditorTransaction((TransactionTime, Transaction) event) {
    if (event.$1 == TransactionTime.before) {
      return;
    }

    final Map<String, dynamic> added = {
      for (final handler in _transactionHandlers)
        handler.type: handler.isParagraphSubType ? <MentionBlockData>[] : [],
    };
    final Map<String, dynamic> removed = {
      for (final handler in _transactionHandlers)
        handler.type: handler.isParagraphSubType ? <MentionBlockData>[] : [],
    };

    for (final op in event.$2.operations) {
      if (op is InsertOperation) {
        for (final n in op.nodes) {
          for (final handler in _transactionHandlers) {
            if (handler.isParagraphSubType) {
              added[handler.type]!
                  .addAll(extractMentionsForType(n, handler.type));
            } else {
              added[handler.type]!
                  .addAll(collectMatchingNodes(n, handler.type));
            }
          }
        }
      } else if (op is DeleteOperation) {
        for (final n in op.nodes) {
          for (final handler in _transactionHandlers) {
            if (handler.isParagraphSubType) {
              removed[handler.type]!.addAll(
                extractMentionsForType(
                  n,
                  handler.type,
                  false,
                ),
              );
            } else {
              removed[handler.type]!
                  .addAll(collectMatchingNodes(n, handler.type));
            }
          }
        }
      } else if (op is UpdateOperation) {
        final node = widget.editorState.getNodeAtPath(op.path);
        if (node == null) {
          continue;
        }

        if (op.attributes['delta'] is! List ||
            op.oldAttributes['delta'] is! List) {
          continue;
        }

        final deltaBefore = Delta.fromJson(op.oldAttributes['delta']);
        final deltaAfter = Delta.fromJson(op.attributes['delta']);

        final (add, del) = diffDeltas(deltaBefore, deltaAfter);

        for (final handler in _transactionHandlers) {
          if (!handler.isParagraphSubType) {
            continue;
          }

          if (add.isNotEmpty) {
            added[handler.type]!.addAll(
              add.where((ti) => ti.attributes?[handler.type] != null).map((ti) {
                final index = deltaAfter.toList().indexOf(ti);
                return (
                  node,
                  ti.attributes![handler.type] as Map<String, dynamic>,
                  index,
                );
              }).toList(),
            );
          }

          if (del.isNotEmpty) {
            removed[handler.type]!.addAll(
              del.where((ti) => ti.attributes?[handler.type] != null).map((ti) {
                return (
                  node,
                  ti.attributes![handler.type] as Map<String, dynamic>,
                  -1,
                );
              }).toList(),
            );
          }
        }
      }
    }

    for (final handler in _transactionHandlers) {
      final additions = added[handler.type] ?? [];
      final removals = removed[handler.type] ?? [];

      if (additions.isEmpty && removals.isEmpty) {
        continue;
      }

      handler.onTransaction(
        context,
        widget.editorState,
        additions,
        removals,
        isCut: context.read<ClipboardState>().isCut,
        isUndoRedo: isUndoRedo,
        isPaste: isPaste,
        isDraggingNode: isDraggingNode,
        parentViewId: widget.viewId,
      );
    }

    isUndoRedo = false;
    isPaste = false;
  }

  List<MentionBlockData> extractMentionsForType(
    Node node,
    String mentionType, [
    bool includeIndex = true,
  ]) {
    final changes = <MentionBlockData>[];

    final nodesWithDelta = collectMatchingNodes(
      node,
      ParagraphBlockKeys.type,
      nodeTypesContainingMentions,
    );

    for (final paragraphNode in nodesWithDelta) {
      final deltas = paragraphNode.attributes['delta'];
      if (deltas == null || deltas is! List || deltas.isEmpty) {
        continue;
      }

      for (final (index, delta) in deltas.indexed) {
        if (delta['attributes'] != null &&
            delta['attributes'][mentionType] != null) {
          changes.add(
            (
              paragraphNode,
              delta['attributes'][mentionType],
              includeIndex ? index : -1,
            ),
          );
        }
      }
    }

    return changes;
  }

  (Iterable<TextInsert>, Iterable<TextInsert>) diffDeltas(
    Delta before,
    Delta after,
  ) {
    final diff = before.diff(after);
    final inverted = diff.invert(before);
    final del = inverted.whereType<TextInsert>();
    final add = diff.whereType<TextInsert>();

    return (add, del);
  }
}
