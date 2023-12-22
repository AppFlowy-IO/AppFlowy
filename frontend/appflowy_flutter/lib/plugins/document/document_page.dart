import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum EditorNotificationType {
  undo,
  redo,
}

class EditorNotification extends Notification {
  const EditorNotification({
    required this.type,
  });

  EditorNotification.undo() : type = EditorNotificationType.undo;
  EditorNotification.redo() : type = EditorNotificationType.redo;

  final EditorNotificationType type;
}

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    super.key,
    required this.onDeleted,
    required this.view,
  });

  final VoidCallback onDeleted;
  final ViewPB view;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  @override
  void initState() {
    super.initState();

    // The appflowy editor use Intl as localization, set the default language as fallback.
    Intl.defaultLocale = 'en_US';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<NotificationActionBloc>()),
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

          return BlocListener<NotificationActionBloc, NotificationActionState>(
            listener: _onNotificationAction,
            child: _buildEditorPage(
              context,
              state,
            ),
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

  // Future<void> _exportPage(DocumentDataPB data) async {
  //   final picker = getIt<FilePickerService>();
  //   final dir = await picker.getDirectoryPath();
  //   if (dir == null) {
  //     return;
  //   }
  //   final path = p.join(dir, '${documentBloc.view.name}.json');
  //   const encoder = JsonEncoder.withIndent('  ');
  //   final json = encoder.convert(data.toProto3Json());
  //   await File(path).writeAsString(json.base64.base64);
  //   if (mounted) {
  //     showSnackBarMessage(context, 'Export success to $path');
  //   }
  // }

  Future<void> _onNotificationAction(
    BuildContext context,
    NotificationActionState state,
  ) async {
    if (state.action != null && state.action!.type == ActionType.jumpToBlock) {
      final path = state.action?.arguments?[ActionArgumentKeys.nodePath.name];

      final editorState = context.read<DocumentBloc>().state.editorState;
      if (editorState != null && widget.view.id == state.action?.objectId) {
        editorState.updateSelectionWithReason(
          Selection.collapsed(
            Position(path: [path]),
          ),
          reason: SelectionUpdateReason.transaction,
        );
      }
    }
  }
}

class DocumentSyncIndicator extends StatelessWidget {
  const DocumentSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentBloc, DocumentState>(
      builder: (context, state) {
        if (state.isSyncing) {
          return const SizedBox(height: 1, child: LinearProgressIndicator());
        } else {
          return const SizedBox(height: 1);
        }
      },
    );
  }
}
