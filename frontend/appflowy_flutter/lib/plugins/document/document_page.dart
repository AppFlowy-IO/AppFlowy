import 'dart:convert';
import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/document/presentation/export_page_widget.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/base64_string.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart'
    hide DocumentEvent;
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

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
  late final DocumentBloc documentBloc;
  EditorState? editorState;

  @override
  void initState() {
    super.initState();

    documentBloc = getIt<DocumentBloc>(param1: widget.view)
      ..add(const DocumentEvent.initial());

    // The appflowy editor use Intl as localization, set the default language as fallback.
    Intl.defaultLocale = 'en_US';
  }

  @override
  void dispose() {
    documentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<NotificationActionBloc>()),
        BlocProvider.value(value: documentBloc),
      ],
      child: BlocListener<NotificationActionBloc, NotificationActionState>(
        listener: _onNotificationAction,
        child: BlocBuilder<DocumentBloc, DocumentState>(
          builder: (context, state) {
            return state.loadingState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              finish: (result) => result.fold(
                (error) {
                  Log.error(error);
                  return FlowyErrorPage.message(
                    error.toString(),
                    howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
                  );
                },
                (data) {
                  if (state.forceClose) {
                    widget.onDeleted();
                    return const SizedBox.shrink();
                  } else if (documentBloc.editorState == null) {
                    return Center(
                      child: ExportPageWidget(
                        onTap: () async => await _exportPage(data),
                      ),
                    );
                  } else {
                    editorState = documentBloc.editorState!;
                    return _buildEditorPage(context, state);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorPage(BuildContext context, DocumentState state) {
    final appflowyEditorPage = AppFlowyEditorPage(
      editorState: editorState!,
      styleCustomizer: EditorStyleCustomizer(
        context: context,
        // the 44 is the width of the left action list
        padding: PlatformExtension.isMobile
            ? const EdgeInsets.only(left: 20, right: 20)
            : const EdgeInsets.only(left: 40, right: 40 + 44),
      ),
      header: _buildCoverAndIcon(context),
    );
    return Column(
      children: [
        if (state.isDeleted) _buildBanner(context),
        Expanded(child: appflowyEditorPage),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () => documentBloc.add(const DocumentEvent.restorePage()),
      onDelete: () => documentBloc.add(const DocumentEvent.deletePermanently()),
    );
  }

  Widget _buildCoverAndIcon(BuildContext context) {
    if (editorState == null) {
      return const Placeholder();
    }
    final page = editorState!.document.root;
    return DocumentHeaderNodeWidget(
      node: page,
      editorState: editorState!,
    );
  }

  Future<void> _exportPage(DocumentDataPB data) async {
    final picker = getIt<FilePickerService>();
    final dir = await picker.getDirectoryPath();
    if (dir == null) {
      return;
    }
    final path = p.join(dir, '${documentBloc.view.name}.json');
    const encoder = JsonEncoder.withIndent('  ');
    final json = encoder.convert(data.toProto3Json());
    await File(path).writeAsString(json.base64.base64);
    if (mounted) {
      showSnackBarMessage(context, 'Export success to $path');
    }
  }

  Future<void> _onNotificationAction(
    BuildContext context,
    NotificationActionState state,
  ) async {
    if (state.action != null && state.action!.type == ActionType.jumpToBlock) {
      final path = state.action?.arguments?[ActionArgumentKeys.nodePath.name];

      if (editorState != null && widget.view.id == state.action?.objectId) {
        editorState!.updateSelectionWithReason(
          Selection.collapsed(
            Position(path: [path]),
          ),
          reason: SelectionUpdateReason.transaction,
        );
      }
    }
  }
}
