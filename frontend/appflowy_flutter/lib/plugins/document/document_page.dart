import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
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
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/document/presentation/sync_error_page.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EditorNotification.addListener(_onEditorNotification);
  }

  @override
  void dispose() {
    EditorNotification.removeListener(_onEditorNotification);
    WidgetsBinding.instance.removeObserver(this);
    documentBloc.close();
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
          buildWhen: _shouldRebuildDocument,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final editorState = state.editorState;
            this.editorState = editorState;
            final error = state.error;
            if (error != null || editorState == null) {
              Log.error(error);
              return Center(
                child: SyncErrorPage(
                  error: error,
                ),
              );
            }

            if (state.forceClose) {
              widget.onDeleted();
              return const SizedBox.shrink();
            }

            return BlocListener<ActionNavigationBloc, ActionNavigationState>(
              listenWhen: (_, curr) => curr.action != null,
              listener: _onNotificationAction,
              child: Consumer<EditorDropManagerState>(
                builder: (context, dropState, _) =>
                    _buildEditorPage(context, state, dropState),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorPage(
    BuildContext context,
    DocumentState state,
    EditorDropManagerState dropState,
  ) {
    final Widget child;
    if (PlatformExtension.isMobile) {
      child = BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
        builder: (context, styleState) {
          return AppFlowyEditorPage(
            editorState: state.editorState!,
            styleCustomizer: EditorStyleCustomizer(
              context: context,
              // the 44 is the width of the left action list
              padding: EditorStyleCustomizer.documentPadding,
            ),
            header: _buildCoverAndIcon(context, state),
            initialSelection: widget.initialSelection,
          );
        },
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
              data.dropTarget != null &&

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
          state.editorState!.selectionService.removeDropTarget();

          final data = state.editorState!.selectionService
              .getDropTargetRenderData(details.globalPosition);

          if (data != null) {
            if (data.cursorNode != null) {
              if (_excludeFromDropTarget.contains(data.cursorNode?.type)) {
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

              await editorState!.dropImages(
                data.dropTarget!,
                imageFiles,
                widget.view.id,
                isLocalMode,
              );
              await editorState!.dropFiles(
                data.dropTarget!,
                otherFiles,
                widget.view.id,
                isLocalMode,
              );
            }
          }
        },
        child: AppFlowyEditorPage(
          editorState: state.editorState!,
          styleCustomizer: EditorStyleCustomizer(
            context: context,
            // the 44 is the width of the left action list
            padding: EditorStyleCustomizer.documentPadding,
          ),
          header: _buildCoverAndIcon(context, state),
          initialSelection: widget.initialSelection,
        ),
      );
    }

    return Column(
      children: [
        if (state.isDeleted) _buildBanner(context),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () => context.read<DocumentBloc>().add(
            const DocumentEvent.restorePage(),
          ),
      onDelete: () => context
          .read<DocumentBloc>()
          .add(const DocumentEvent.deletePermanently()),
    );
  }

  Widget _buildCoverAndIcon(BuildContext context, DocumentState state) {
    final editorState = state.editorState;
    final userProfilePB = state.userProfilePB;
    if (editorState == null || userProfilePB == null) {
      return const SizedBox.shrink();
    }

    if (PlatformExtension.isMobile) {
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

  void _onEditorNotification(EditorNotificationType type) {
    final editorState = this.editorState;
    if (editorState == null) {
      return;
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

  void _onNotificationAction(
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

  bool _shouldRebuildDocument(DocumentState previous, DocumentState current) {
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
}
