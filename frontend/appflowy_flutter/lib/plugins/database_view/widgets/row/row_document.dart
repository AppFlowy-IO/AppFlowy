import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_document_bloc.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDocument extends StatelessWidget {
  const RowDocument({
    super.key,
    required this.viewId,
    required this.rowId,
    required this.scrollController,
  });

  final String viewId;
  final String rowId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowDocumentBloc>(
      create: (context) => RowDocumentBloc(
        viewId: viewId,
        rowId: rowId,
      )..add(
          const RowDocumentEvent.initial(),
        ),
      child: BlocBuilder<RowDocumentBloc, RowDocumentState>(
        builder: (context, state) {
          return state.loadingState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (error) => FlowyErrorPage.message(
              error.toString(),
              howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
            ),
            finish: () => RowEditor(
              viewPB: state.viewPB!,
              scrollController: scrollController,
            ),
          );
        },
      ),
    );
  }
}

class RowEditor extends StatefulWidget {
  const RowEditor({
    super.key,
    required this.viewPB,
    required this.scrollController,
  });

  final ViewPB viewPB;
  final ScrollController scrollController;

  @override
  State<RowEditor> createState() => _RowEditorState();
}

class _RowEditorState extends State<RowEditor> {
  late final DocumentBloc documentBloc;

  @override
  void initState() {
    super.initState();
    documentBloc = DocumentBloc(view: widget.viewPB)
      ..add(const DocumentEvent.initial());
  }

  @override
  dispose() {
    documentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: documentBloc),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          return state.loadingState.when(
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            finish: (result) {
              return result.fold(
                (error) => FlowyErrorPage.message(
                  error.toString(),
                  howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
                ),
                (_) {
                  final editorState = documentBloc.editorState;
                  if (editorState == null) {
                    return const SizedBox.shrink();
                  }
                  return IntrinsicHeight(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 300),
                      child: AppFlowyEditorPage(
                        shrinkWrap: true,
                        autoFocus: false,
                        editorState: editorState,
                        scrollController: widget.scrollController,
                        styleCustomizer: EditorStyleCustomizer(
                          context: context,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
