import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_file.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/shared/patterns/file_type_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

const _excludeFromDropTarget = [
  ImageBlockKeys.type,
  CustomImageBlockKeys.type,
  MultiImageBlockKeys.type,
  FileBlockKeys.type,
];

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

  bool wasUndoRedo = false;

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
      child = DropTarget(
        enable: dropState.isDropEnabled,
        onDragExited: (_) =>
            state.editorState!.selectionService.removeDropTarget(),
        onDragUpdated: (details) {
          final data = state.editorState!.selectionService
              .getDropTargetRenderData(details.globalPosition);

          if (data != null &&
              data.dropPath != null &&

              // We implement custom Drop logic for image blocks, this is
              // how we can exclude them from the Drop Target
              !_excludeFromDropTarget.contains(data.cursorNode?.type)) {
            // Render the drop target
            state.editorState!.selectionService
                .renderDropTargetForOffset(details.globalPosition);
          } else {
            state.editorState!.selectionService.removeDropTarget();
          }
        },
        onDragDone: (details) async {
          final editorState = state.editorState;
          if (editorState == null) {
            return;
          }

          editorState.selectionService.removeDropTarget();

          final data = editorState.selectionService
              .getDropTargetRenderData(details.globalPosition);

          if (data != null) {
            final cursorNode = data.cursorNode;
            final dropPath = data.dropPath;

            if (cursorNode != null && dropPath != null) {
              if (_excludeFromDropTarget.contains(cursorNode.type)) {
                return;
              }

              final node = editorState.getNodeAtPath(dropPath);

              if (node == null) {
                return;
              }

              final isLocalMode = context.read<DocumentBloc>().isLocalMode;
              final List<XFile> imageFiles = [];
              final List<XFile> otherFiles = [];

              for (final file in details.files) {
                final fileName = file.name.toLowerCase();
                if (file.mimeType?.startsWith('image/') ??
                    false || imgExtensionRegex.hasMatch(fileName)) {
                  imageFiles.add(file);
                } else {
                  otherFiles.add(file);
                }
              }

              await editorState.dropImages(
                node,
                imageFiles,
                widget.view.id,
                isLocalMode,
              );

              await editorState.dropFiles(
                node,
                otherFiles,
                widget.view.id,
                isLocalMode,
              );
            }
          }
        },
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
      onRestore: () => context.read<DocumentBloc>().add(
            const DocumentEvent.restorePage(),
          ),
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
    if (type == EditorNotificationType.undo) {
      wasUndoRedo = true;
      final beforeUndo = collectMatchingNodes(editorState.document.root);
      undoCommand.execute(editorState);
      final afterUndo = collectMatchingNodes(editorState.document.root);

      handleSubPageChanges(beforeUndo, afterUndo);
    } else if (type == EditorNotificationType.redo) {
      wasUndoRedo = true;
      final beforeRedo = collectMatchingNodes(editorState.document.root);
      redoCommand.execute(editorState);
      final afterRedo = collectMatchingNodes(editorState.document.root);

      handleSubPageChanges(beforeRedo, afterRedo);
    } else if (type == EditorNotificationType.exitEditing &&
        editorState.selection != null) {
      editorState.selection = null;
    }

    wasUndoRedo = false;
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

  List<Node> collectMatchingNodes(Node node) {
    final List<Node> matchingNodes = [];
    if (node.type == SubPageBlockKeys.type) {
      matchingNodes.add(node);
    }

    for (final child in node.children) {
      matchingNodes.addAll(collectMatchingNodes(child));
    }

    return matchingNodes;
  }

  void handleSubPageChanges(List<Node> before, List<Node> after) {
    final additions = after.where((e) => !before.contains(e)).toList();
    final removals = before.where((e) => !after.contains(e)).toList();

    // Removals goes to trash
    for (final node in removals) {
      if (node.type == SubPageBlockKeys.type) {
        handleSubPageDeletion(context, node);
      }
    }

    // Additions are moved to this view
    for (final node in additions) {
      handleSubPageAddition(context, node);
    }
  }

  Future<void> handleSubPageAddition(BuildContext context, Node node) async {
    if (editorState == null || node.type != SubPageBlockKeys.type) {
      return;
    }

    // We update the wasCut attribute to true to signify the view was moved.
    // In this particular case it shares behavior with cut, as it moves the view from Trash
    // to the current view.
    final transaction = editorState!.transaction
      ..deleteNode(node)
      ..insertNode(
        node.path.next,
        node.copyWith(
          attributes: {
            ...node.attributes,
            SubPageBlockKeys.wasCut: true,
          },
        ),
      );
    await editorState!.apply(transaction, withUpdateSelection: false);
  }

  Future<void> handleSubPageDeletion(BuildContext context, Node node) async {
    if (editorState == null || node.type != SubPageBlockKeys.type) {
      return;
    }

    final view = node.attributes[SubPageBlockKeys.viewId];
    if (view == null) {
      return;
    }

    // We move the view to Trash
    final result = await ViewBackendService.deleteView(viewId: view);
    result.fold(
      (_) {},
      (error) {
        Log.error(error);
        if (context.mounted) {
          showSnapBar(context, 'Failed to move page to trash');
        }
      },
    );
  }

  void onEditorTransaction((TransactionTime, Transaction) event) {
    if (wasUndoRedo) {
      return;
    }

    final List<Node> added = [];
    final List<Node> removed = [];
    for (final op in event.$2.operations) {
      if (op is InsertOperation) {
        for (final n in op.nodes) {
          added.addAll(collectMatchingNodes(n));
        }
      } else if (op is DeleteOperation) {
        for (final n in op.nodes) {
          removed.addAll(collectMatchingNodes(n));
        }
      }
    }

    if (removed.isEmpty && added.isEmpty) {
      return;
    }

    // Removals goes to trash
    for (final node in removed) {
      if (node.type == SubPageBlockKeys.type) {
        handleSubPageDeletion(context, node);
      }
    }

    // Additions are moved to this view
    for (final node in added) {
      handleSubPageAddition(context, node);
    }
  }
}
