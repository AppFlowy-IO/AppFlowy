import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    super.key,
    required this.view,
    required this.onDeleted,
    this.initialSelection,
  });

  final ViewPB view;
  final VoidCallback onDeleted;
  final Selection? initialSelection;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  EditorState? editorState;

  @override
  void initState() {
    super.initState();
    EditorNotification.addListener(_onEditorNotification);
  }

  @override
  void dispose() {
    EditorNotification.removeListener(_onEditorNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ActionNavigationBloc>()),
        BlocProvider(
          create: (_) => DocumentBloc(view: widget.view)
            ..add(const DocumentEvent.initial()),
        ),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final editorState = state.editorState;
          this.editorState = editorState;
          final error = state.error;
          if (error != null || editorState == null) {
            Log.error(error);
            return FlowyErrorPage.message(
              error.toString(),
              howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
            );
          }

          if (state.forceClose) {
            widget.onDeleted();
            return const SizedBox.shrink();
          }

          return BlocListener<ActionNavigationBloc, ActionNavigationState>(
            listenWhen: (_, curr) => curr.action != null,
            listener: _onNotificationAction,
            child: _buildEditorPage(context, state),
          );
        },
      ),
    );
  }

  Widget _buildEditorPage(BuildContext context, DocumentState state) {
    final appflowyEditorPage = AppFlowyEditorPage(
      editorState: state.editorState!,
      styleCustomizer: EditorStyleCustomizer(
        context: context,
        // the 44 is the width of the left action list
        padding: EditorStyleCustomizer.documentPadding,
      ),
      header: _buildCoverAndIcon(context, state.editorState!),
      initialSelection: widget.initialSelection,
    );

    return Column(
      children: [
        // Only show the indicator in integration test mode
        // if (FlowyRunner.currentMode.isIntegrationTest)
        //   const DocumentSyncIndicator(),

        if (state.isDeleted) _buildBanner(context),
        Expanded(child: appflowyEditorPage),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () => context.read<DocumentBloc>().add(
            const DocumentEvent.restorePage(),
          ),
      onDelete: () => context.read<DocumentBloc>().add(
            const DocumentEvent.deletePermanently(),
          ),
    );
  }

  Widget _buildCoverAndIcon(BuildContext context, EditorState editorState) {
    final page = editorState.document.root;
    return DocumentHeaderNodeWidget(
      node: page,
      editorState: editorState,
      view: widget.view,
      onIconChanged: (icon) async {
        await ViewBackendService.updateViewIcon(
          viewId: widget.view.id,
          viewIcon: icon,
        );
      },
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
    } else if (type == EditorNotificationType.exitEditing) {
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
}
