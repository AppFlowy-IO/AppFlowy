import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
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
          return state.loadingState.map(
            loading: (_) => const SizedBox.shrink(),
            finish: (result) => result.successOrFail.fold(
              (_) {
                if (state.forceClose) {
                  widget.onDeleted();
                  return const SizedBox.shrink();
                } else if (documentBloc.editorState == null) {
                  return const SizedBox.shrink();
                } else {
                  return _buildEditorPage(context, state);
                }
              },
              (error) => FlowyErrorPage(error.toString()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditorPage(BuildContext context, DocumentState state) {
    const appflowyEditorPage = AppFlowyEditorPage();
    return !state.isDeleted
        ? appflowyEditorPage
        : Column(
            children: [
              _buildBanner(context),
              appflowyEditorPage,
            ],
          );
  }

  Widget _buildBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () =>
          context.read<DocumentBloc>().add(const DocumentEvent.restorePage()),
      onDelete: () => context
          .read<DocumentBloc>()
          .add(const DocumentEvent.deletePermanently()),
    );
  }
}
