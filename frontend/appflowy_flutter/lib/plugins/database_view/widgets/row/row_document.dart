import 'package:appflowy/plugins/database_view/grid/application/row/row_document_bloc.dart';
import 'package:appflowy/plugins/document/document_page.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDocument extends StatelessWidget {
  final String viewId;
  final String rowId;
  const RowDocument({
    required this.viewId,
    required this.rowId,
    super.key,
  });

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
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (error) {
              return FlowyErrorPage(
                error.toString(),
              );
            },
            finish: () {
              return BlocProvider(
                create: (context) => DocumentAppearanceCubit(),
                child: BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
                  builder: (_, appearState) {
                    return DocumentPage(
                      view: state.viewPB!,
                      onDeleted: () {},
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
