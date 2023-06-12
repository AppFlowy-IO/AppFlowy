import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_document.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';
import 'row_action.dart';
import 'row_property.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final RowController rowController;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    required this.rowController,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  static String identifier() {
    return (RowDetailPage).toString();
  }
}

class _RowDetailPageState extends State<RowDetailPage> {
  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: BlocProvider(
        create: (context) {
          return RowDetailBloc(dataController: widget.rowController)
            ..add(const RowDetailEvent.initial());
        },
        child: ListView(
          children: [
            // using ListView here for future expansion:
            // - header and cover image
            // - lower rich text area
            IntrinsicHeight(child: _responsiveRowInfo()),
            const Divider(height: 1.0),

// TODO(lucas): expand the document
            SizedBox(
              height: 200,
              child: RowDocument(
                viewId: widget.rowController.viewId,
                rowId: widget.rowController.rowId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRowInfo() {
    final rowDataColumn = RowPropertyList(
      cellBuilder: widget.cellBuilder,
      viewId: widget.rowController.viewId,
    );
    final rowOptionColumn = RowActionList(
      viewId: widget.rowController.viewId,
      rowController: widget.rowController,
    );
    if (MediaQuery.of(context).size.width > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(50, 50, 20, 20),
              child: rowDataColumn,
            ),
          ),
          const VerticalDivider(width: 1.0),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: rowOptionColumn,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: rowDataColumn,
          ),
          const Divider(height: 1.0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: rowOptionColumn,
          )
        ],
      );
    }
  }
}
