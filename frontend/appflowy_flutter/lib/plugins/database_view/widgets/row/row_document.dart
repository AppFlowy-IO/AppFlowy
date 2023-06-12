import 'package:appflowy/plugins/database_view/grid/application/row/row_document_bloc.dart';
import 'package:appflowy/plugins/document/document_page.dart';
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
            error: (error) => Center(
              child: Text(error.toString()),
            ),
            finish: () {
              return DocumentPage(
                view: state.viewPB!,
                onDeleted: () {},
              );
            },
          );
        },
      ),
    );
  }
}
