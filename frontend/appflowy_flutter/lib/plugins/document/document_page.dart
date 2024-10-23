import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    super.key,
    required this.view,
    required this.onDeleted,
    this.initialSelection,
    this.initialBlockId,
    this.fixedTitle,
  });

  final ViewPB view;
  final VoidCallback onDeleted;
  final Selection? initialSelection;
  final String? initialBlockId;
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
  }

  @override
  void dispose() {
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
    final editorState = state.editorState;
    if (editorState == null) {
      return const SizedBox.shrink();
    }

    final width = context.read<DocumentAppearanceCubit>().state.width;

    final Widget child;
    if (UniversalPlatform.isMobile) {
      child = BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
        builder: (context, styleState) => AppFlowyEditorPage(
          editorState: editorState,
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
        editorState: editorState,
        isLocalMode: context.read<DocumentBloc>().isLocalMode,
        child: AppFlowyEditorPage(
          editorState: editorState,
          // if the view's name is empty, focus on the title
          autoFocus: widget.view.name.isEmpty ? false : null,
          styleCustomizer: EditorStyleCustomizer(
            context: context,
            width: width,
            padding: EditorStyleCustomizer.documentPadding,
          ),
          header: buildCoverAndIcon(context, state),
          initialSelection: _calculateInitialSelection(editorState),
        ),
      );
    }

    return Provider(
      create: (_) => SharedEditorContext(),
      child: EditorTransactionService(
        viewId: widget.view.id,
        editorState: state.editorState!,
        child: Column(
          children: [
            if (state.isDeleted) buildBanner(context),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget buildBanner(BuildContext context) {
    return DocumentBanner(
      viewName: widget.view.nameOrDefault,
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

  void onNotificationAction(
    BuildContext context,
    ActionNavigationState state,
  ) {
    final action = state.action;
    if (action == null ||
        action.type != ActionType.jumpToBlock ||
        action.objectId != widget.view.id) {
      return;
    }

    final editorState = context.read<DocumentBloc>().state.editorState;
    if (editorState == null) {
      return;
    }

    final Path? path = _getPathFromAction(action, editorState);
    if (path != null) {
      debugPrint('jump to block: $path');
      editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: path)),
      );
    }
  }

  Path? _getPathFromAction(NavigationAction action, EditorState editorState) {
    Path? path = action.arguments?[ActionArgumentKeys.nodePath];
    if (path == null || path.isEmpty) {
      final blockId = action.arguments?[ActionArgumentKeys.blockId];
      if (blockId != null) {
        path = _findNodePathByBlockId(editorState, blockId);
      }
    }
    return path;
  }

  Path? _findNodePathByBlockId(EditorState editorState, String blockId) {
    final document = editorState.document;
    final startNode = document.root.children.firstOrNull;
    if (startNode == null) {
      return null;
    }

    final nodeIterator = NodeIterator(document: document, startNode: startNode);
    while (nodeIterator.moveNext()) {
      final node = nodeIterator.current;
      if (node.id == blockId) {
        return node.path;
      }
    }

    return null;
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

  Selection? _calculateInitialSelection(EditorState editorState) {
    if (widget.initialSelection != null) {
      return widget.initialSelection;
    }

    if (widget.initialBlockId != null) {
      final path = _findNodePathByBlockId(editorState, widget.initialBlockId!);
      if (path != null) {
        editorState.selectionType = SelectionType.block;
        return Selection.collapsed(
          Position(
            path: path,
          ),
        );
      }
    }

    return null;
  }
}
