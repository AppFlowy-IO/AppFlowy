import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/row/related_row_detail_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/row_banner.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// This widget is largely copied from `plugins/document/document_page.dart` intentionally instead of opting for an abstraction. We can make an abstraction after the view refactor is done and there's more clarity in that department.

class DatabaseDocumentPage extends StatefulWidget {
  const DatabaseDocumentPage({
    super.key,
    required this.view,
    required this.databaseId,
    required this.rowId,
    required this.documentId,
    this.initialSelection,
  });

  final ViewPB view;
  final String databaseId;
  final String rowId;
  final String documentId;
  final Selection? initialSelection;

  @override
  State<DatabaseDocumentPage> createState() => _DatabaseDocumentPageState();
}

class _DatabaseDocumentPageState extends State<DatabaseDocumentPage> {
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
        BlocProvider.value(
          value: getIt<ActionNavigationBloc>(),
        ),
        BlocProvider(
          create: (_) => DocumentBloc(
            databaseViewId: widget.databaseId,
            rowId: widget.rowId,
            documentId: widget.documentId,
          )..add(const DocumentEvent.initial()),
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
            return Center(
              child: AppFlowyErrorPage(
                error: error,
              ),
            );
          }

          if (state.forceClose) {
            return const SizedBox.shrink();
          }

          return BlocListener<ActionNavigationBloc, ActionNavigationState>(
            listener: _onNotificationAction,
            listenWhen: (_, curr) => curr.action != null,
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
        padding: EditorStyleCustomizer.documentPadding,
      ),
      header: _buildDatabaseDataContent(context, state.editorState!),
      initialSelection: widget.initialSelection,
      useViewInfoBloc: false,
    );

    return Column(
      children: [
        if (state.isDeleted) _buildBanner(context),
        Expanded(child: appflowyEditorPage),
      ],
    );
  }

  Widget _buildDatabaseDataContent(
    BuildContext context,
    EditorState editorState,
  ) {
    return BlocProvider(
      create: (context) => RelatedRowDetailPageBloc(
        databaseId: widget.databaseId,
        initialRowId: widget.rowId,
      ),
      child: BlocBuilder<RelatedRowDetailPageBloc, RelatedRowDetailPageState>(
        builder: (context, state) {
          return state.when(
            loading: () => const SizedBox.shrink(),
            ready: (databaseController, rowController) {
              final padding = EditorStyleCustomizer.documentPadding;
              return BlocProvider(
                create: (context) => RowDetailBloc(
                  fieldController: databaseController.fieldController,
                  rowController: rowController,
                ),
                child: Column(
                  children: [
                    RowBanner(
                      databaseController: databaseController,
                      rowController: rowController,
                      cellBuilder: EditableCellBuilder(
                        databaseController: databaseController,
                      ),
                      userProfile:
                          context.read<RelatedRowDetailPageBloc>().userProfile,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 24,
                        left: padding.left,
                        right: padding.right,
                      ),
                      child: RowPropertyList(
                        viewId: databaseController.viewId,
                        fieldController: databaseController.fieldController,
                        cellBuilder: EditableCellBuilder(
                          databaseController: databaseController,
                        ),
                      ),
                    ),
                    const TypeOptionSeparator(spacing: 24.0),
                  ],
                ),
              );
            },
          );
        },
      ),
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
      if (editorState != null && widget.documentId == state.action?.objectId) {
        editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: [path])),
        );
      }
    }
  }
}
