import 'dart:async';

import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/child_page_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    super.key,
    required this.view,
    required this.onDeleted,
    this.initialSelection,
    this.fixedTitle,
  });

  final ViewPB view;
  final VoidCallback onDeleted;
  final Selection? initialSelection;
  final String? fixedTitle;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage>
    with WidgetsBindingObserver {
  EditorState? editorState;
  late final documentBloc = DocumentBloc(documentId: widget.view.id)
    ..add(const DocumentEvent.initial());

  StreamSubscription<(TransactionTime, Transaction)>? transactionSubscription;

  bool isUndoRedo = false;
  bool isPaste = false;
  bool isDraggingNode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EditorNotification.addListener(onEditorNotification);
  }

  @override
  void dispose() {
    EditorNotification.removeListener(onEditorNotification);
    WidgetsBinding.instance.removeObserver(this);
    documentBloc.close();
    transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      documentBloc.add(const DocumentEvent.clearAwarenessStates());
    } else if (state == AppLifecycleState.resumed) {
      documentBloc.add(const DocumentEvent.syncAwarenessStates());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ActionNavigationBloc>()),
        BlocProvider.value(value: documentBloc),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        buildWhen: shouldRebuildDocument,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final editorState = state.editorState;
          this.editorState = editorState;
          final error = state.error;
          if (error != null || editorState == null) {
            Log.error(error);
            return Center(child: AppFlowyErrorPage(error: error));
          }

          if (state.forceClose) {
            widget.onDeleted();
            return const SizedBox.shrink();
          }

          editorState.transactionStream.listen(onEditorTransaction);

          return BlocListener<ActionNavigationBloc, ActionNavigationState>(
            listenWhen: (_, curr) => curr.action != null,
            listener: onNotificationAction,
            child: buildEditorPage(context, state),
          );
        },
      ),
    );
  }

  Widget buildEditorPage(
    BuildContext context,
    DocumentState state,
  ) {
    final width = context.read<DocumentAppearanceCubit>().state.width;

    final Widget child;
    if (UniversalPlatform.isMobile) {
      child = BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
        builder: (context, styleState) => AppFlowyEditorPage(
          editorState: state.editorState!,
          // if the view's name is empty, focus on the title
          autoFocus: widget.view.name.isEmpty ? false : null,
          styleCustomizer: EditorStyleCustomizer(
            context: context,
            width: width,
            padding: EditorStyleCustomizer.documentPadding,
          ),
          header: buildCoverAndIcon(context, state),
          initialSelection: widget.initialSelection,
        ),
      );
    } else {
      child = EditorDropHandler(
        viewId: widget.view.id,
        editorState: state.editorState!,
        isLocalMode: context.read<DocumentBloc>().isLocalMode,
        child: AppFlowyEditorPage(
          editorState: state.editorState!,
          // if the view's name is empty, focus on the title
          autoFocus: widget.view.name.isEmpty ? false : null,
          styleCustomizer: EditorStyleCustomizer(
            context: context,
            width: width,
            padding: EditorStyleCustomizer.documentPadding,
          ),
          header: buildCoverAndIcon(context, state),
          initialSelection: widget.initialSelection,
        ),
      );
    }

    return Provider(
      create: (_) => SharedEditorContext(),
      child: Column(
        children: [
          if (state.isDeleted) buildBanner(context),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget buildBanner(BuildContext context) {
    return DocumentBanner(
      viewName: widget.view.name,
      onRestore: () =>
          context.read<DocumentBloc>().add(const DocumentEvent.restorePage()),
      onDelete: () => context
          .read<DocumentBloc>()
          .add(const DocumentEvent.deletePermanently()),
    );
  }

  Widget buildCoverAndIcon(BuildContext context, DocumentState state) {
    final editorState = state.editorState;
    final userProfilePB = state.userProfilePB;
    if (editorState == null || userProfilePB == null) {
      return const SizedBox.shrink();
    }

    if (UniversalPlatform.isMobile) {
      return DocumentImmersiveCover(
        fixedTitle: widget.fixedTitle,
        view: widget.view,
        userProfilePB: userProfilePB,
      );
    }

    final page = editorState.document.root;
    return DocumentCoverWidget(
      node: page,
      editorState: editorState,
      view: widget.view,
      onIconChanged: (icon) async => ViewBackendService.updateViewIcon(
        viewId: widget.view.id,
        viewIcon: icon,
      ),
    );
  }

  void onEditorNotification(EditorNotificationType type) {
    final editorState = this.editorState;
    if (editorState == null) {
      return;
    }

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
      undoCommand.execute(editorState);
    } else if (type == EditorNotificationType.redo) {
      redoCommand.execute(editorState);
    } else if (type == EditorNotificationType.exitEditing &&
        editorState.selection != null) {
      editorState.selection = null;
    }
  }

  void onNotificationAction(
    BuildContext context,
    ActionNavigationState state,
  ) {
    if (state.action != null && state.action!.type == ActionType.jumpToBlock) {
      final path = state.action?.arguments?[ActionArgumentKeys.nodePath];

      final editorState = context.read<DocumentBloc>().state.editorState;
      if (editorState != null && widget.view.id == state.action?.objectId) {
        editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: [path])),
        );
      }
    }
  }

  bool shouldRebuildDocument(DocumentState previous, DocumentState current) {
    // only rebuild the document page when the below fields are changed
    // this is to prevent unnecessary rebuilds
    //
    // If you confirm the newly added fields should be rebuilt, please update
    // this function.
    if (previous.editorState != current.editorState) {
      return true;
    }

    if (previous.forceClose != current.forceClose ||
        previous.isDeleted != current.isDeleted) {
      return true;
    }

    if (previous.userProfilePB != current.userProfilePB) {
      return true;
    }

    if (previous.isLoading != current.isLoading ||
        previous.error != current.error) {
      return true;
    }

    return false;
  }

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

  // TODO(Mathias): Move logic to a separate class/Widget to keep the document page clean
  void onEditorTransaction((TransactionTime, Transaction) event) {
    if (editorState == null || event.$1 == TransactionTime.after) {
      return;
    }

    final transactionHandlers = SharedEditorContext.transactionHandlers;
    final Map<String, dynamic> added = {
      for (final handler in transactionHandlers)
        handler.type: handler.isParagraphSubType ? <MentionBlockData>[] : [],
    };
    final Map<String, dynamic> removed = {
      for (final handler in transactionHandlers)
        handler.type: handler.isParagraphSubType ? <MentionBlockData>[] : [],
    };

    for (final op in event.$2.operations) {
      if (op is InsertOperation) {
        for (final n in op.nodes) {
          for (final handler in transactionHandlers) {
            if (handler.isParagraphSubType) {
              final nodesWithDelta = collectMatchingNodes(
                n,
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
                      delta['attributes'][handler.type] != null) {
                    added[handler.type]!.add(
                      (paragraphNode, delta['attributes'][handler.type], index),
                    );
                  }
                }
              }
            } else {
              added[handler.type]!
                  .addAll(collectMatchingNodes(n, handler.type));
            }
          }
        }
      } else if (op is DeleteOperation) {
        for (final n in op.nodes) {
          for (final handler in transactionHandlers) {
            if (handler.isParagraphSubType) {
              final nodesWithDelta = collectMatchingNodes(
                n,
                ParagraphBlockKeys.type,
                nodeTypesContainingMentions,
              );
              for (final paragraphNode in nodesWithDelta) {
                final List deltas = paragraphNode.attributes['delta'];
                for (final (index, delta) in deltas.indexed) {
                  if (delta['attributes'] != null &&
                      delta['attributes'][handler.type] != null) {
                    removed[handler.type]!.add(
                      (paragraphNode, delta['attributes'][handler.type], index),
                    );
                  }
                }
              }
            } else {
              removed[handler.type]!
                  .addAll(collectMatchingNodes(n, handler.type));
            }
          }
        }
      } else if (op is UpdateOperation) {
        final node = editorState!.getNodeAtPath(op.path);
        if (node == null) {
          continue;
        }

        if (op.attributes['delta'] is! List ||
            op.oldAttributes['delta'] is! List) {
          continue;
        }

        final deltaBefore = Delta.fromJson(op.oldAttributes['delta']);
        final deltaAfter = Delta.fromJson(op.attributes['delta']);

        final diff = deltaBefore.diff(deltaAfter);
        final inverted = diff.invert(deltaBefore);
        final del = inverted.whereType<TextInsert>();
        final add = diff.whereType<TextInsert>();

        for (final handler in transactionHandlers) {
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

    if (removed.isEmpty && added.isEmpty) {
      return;
    }

    for (final handler in transactionHandlers) {
      final a = added[handler.type] ?? [];
      final r = removed[handler.type] ?? [];

      if (a.isEmpty && r.isEmpty) {
        continue;
      }

      handler.onTransaction(
        context,
        editorState!,
        a,
        r,
        isCut: context.read<ClipboardState>().isCut,
        isUndoRedo: isUndoRedo,
        isPaste: isPaste,
        isDraggingNode: isDraggingNode,
        parentViewId: widget.view.id,
      );

      isUndoRedo = false;
      isPaste = false;
    }
  }
}
