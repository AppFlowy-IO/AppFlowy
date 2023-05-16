import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
              (_) {
                if (state.forceClose) {
                  widget.onDeleted();
                  return const SizedBox.shrink();
                } else if (documentBloc.editorState == null) {
                  return const SizedBox.shrink();
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
    );
    return Column(
      children: [
        if (state.isDeleted) _buildBanner(context),
        _buildCoverAndIcon(context),
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
}
