import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_document_bloc.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDocument extends StatelessWidget {
  const RowDocument({
    super.key,
    required this.viewId,
    required this.rowId,
  });

  final String viewId;
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowDocumentBloc>(
      create: (context) => RowDocumentBloc(viewId: viewId, rowId: rowId)
        ..add(const RowDocumentEvent.initial()),
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
              onIsEmptyChanged: (isEmpty) => context
                  .read<RowDocumentBloc>()
                  .add(RowDocumentEvent.updateIsEmpty(isEmpty)),
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
    this.onIsEmptyChanged,
  });

  final ViewPB viewPB;
  final void Function(bool)? onIsEmptyChanged;

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
  void dispose() {
    documentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: documentBloc),
      ],
      child: BlocListener<DocumentBloc, DocumentState>(
        listenWhen: (previous, current) =>
            previous.isDocumentEmpty != current.isDocumentEmpty,
        listener: (context, state) {
          if (state.isDocumentEmpty != null) {
            widget.onIsEmptyChanged?.call(state.isDocumentEmpty!);
          }
        },
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

            return IntrinsicHeight(
              child: Container(
                constraints: const BoxConstraints(minHeight: 300),
                child: BlocProvider<ViewInfoBloc>(
                  create: (context) => ViewInfoBloc(view: widget.viewPB),
                  child: AppFlowyEditorPage(
                    shrinkWrap: true,
                    autoFocus: false,
                    editorState: editorState,
                    styleCustomizer: EditorStyleCustomizer(
                      context: context,
                      padding: const EdgeInsets.only(left: 16, right: 54),
                    ),
                    showParagraphPlaceholder: (editorState, node) =>
                        editorState.document.isEmpty,
                    placeholderText: (node) =>
                        LocaleKeys.cardDetails_notesPlaceholder.tr(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
