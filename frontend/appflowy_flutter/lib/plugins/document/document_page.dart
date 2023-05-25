import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/export_page_widget.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/base64_string.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart'
    hide DocumentEvent;
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
    return BlocProvider.value(
      value: documentBloc,
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          return state.loadingState.when(
            loading: () => const SizedBox.shrink(),
            finish: (result) => result.fold(
              (error) => FlowyErrorPage(error.toString()),
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
    );
  }

  Widget _buildEditorPage(BuildContext context, DocumentState state) {
    final appflowyEditorPage = AppFlowyEditorPage(
      editorState: editorState!,
      header: _buildCoverAndIcon(context),
    );
    return Column(
      children: [
        if (state.isDeleted) _buildBanner(context),
        Expanded(
          child: appflowyEditorPage,
        ),
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
    return CoverImageNodeWidget(
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

    _showMessage('Export success to $path');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: FlowyText(message),
      ),
    );
  }
}
