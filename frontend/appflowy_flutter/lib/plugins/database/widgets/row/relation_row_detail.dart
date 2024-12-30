import 'package:appflowy/plugins/database/application/row/related_row_detail_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'row_detail.dart';

class RelatedRowDetailPage extends StatelessWidget {
  const RelatedRowDetailPage({
    super.key,
    required this.databaseId,
    required this.rowId,
  });

  final String databaseId;
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RelatedRowDetailPageBloc(
        databaseId: databaseId,
        initialRowId: rowId,
      ),
      child: BlocBuilder<RelatedRowDetailPageBloc, RelatedRowDetailPageState>(
        builder: (context, state) {
          return state.when(
            loading: () => const SizedBox.shrink(),
            ready: (databaseController, rowController) {
              return RowDetailPage(
                databaseController: databaseController,
                rowController: rowController,
                allowOpenAsFullPage: false,
              );
            },
          );
        },
      ),
    );
  }
}
