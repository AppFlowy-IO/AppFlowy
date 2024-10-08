import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
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
    return ChangeNotifierProvider(
      // Due to how DropTarget works, there is no way to differentiate if an overlay is
      // blocking the target visibly, so when we have an overlay with a drop target,
      // we should disable the drop target for the Editor, until it is closed.
      //
      // See FileBlockComponent for sample use.
      //
      // Relates to:
      // - https://github.com/MixinNetwork/flutter-plugins/issues/2
      // - https://github.com/MixinNetwork/flutter-plugins/issues/331
      //
      create: (_) => EditorDropManagerState(),
      child: MultiBlocProvider(
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
              child: Consumer<EditorDropManagerState>(
                builder: (context, dropState, _) =>
                    buildEditorPage(context, state, dropState),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildEditorPage(
    BuildContext context,
    DocumentState state,
    EditorDropManagerState dropState,
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
        isDropEnabled: dropState.isDropEnabled,
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

  List<Node> collectMatchingNodes(Node node, String type) {
    final List<Node> matchingNodes = [];
    if (node.type == type) {
      matchingNodes.add(node);
    }

    for (final child in node.children) {
      matchingNodes.addAll(collectMatchingNodes(child, type));
    }

    return matchingNodes;
  }

  void onEditorTransaction((TransactionTime, Transaction) event) {
    if (editorState == null || event.$1 == TransactionTime.before) {
      return;
    }

    final Map<String, List<Node>> addedNodes = {
      for (final handler in SharedEditorContext.transactionHandlers)
        handler.blockType: [],
    };
    final Map<String, List<Node>> removedNodes = {
      for (final handler in SharedEditorContext.transactionHandlers)
        handler.blockType: [],
    };

    final transactionHandlerTypes = SharedEditorContext.transactionHandlers
        .map((h) => h.blockType)
        .toList();

    // Collect all matching nodes in a performant way for each handler type.
    for (final op in event.$2.operations) {
      if (op is InsertOperation) {
        for (final n in op.nodes) {
          for (final handlerType in transactionHandlerTypes) {
            if (n.type == handlerType) {
              addedNodes[handlerType]!
                  .addAll(collectMatchingNodes(n, handlerType));
            }
          }
        }
      } else if (op is DeleteOperation) {
        for (final n in op.nodes) {
          for (final handlerType in transactionHandlerTypes) {
            if (n.type == handlerType) {
              removedNodes[handlerType]!
                  .addAll(collectMatchingNodes(n, handlerType));
            }
          }
        }
      }
    }

    if (removedNodes.isEmpty && addedNodes.isEmpty) {
      return;
    }

    for (final handler in SharedEditorContext.transactionHandlers) {
      final added = addedNodes[handler.blockType] ?? [];
      final removed = removedNodes[handler.blockType] ?? [];

      if (added.isEmpty && removed.isEmpty) {
        continue;
      }

      handler.onTransaction(
        context,
        editorState!,
        added,
        removed,
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
