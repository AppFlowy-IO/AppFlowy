import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';
import 'row_banner.dart';
import 'row_property.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final FieldController fieldController;
  final RowController rowController;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    super.key,
    required this.fieldController,
    required this.rowController,
    required this.cellBuilder,
  });

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  static String identifier() {
    return (RowDetailPage).toString();
  }
}

class _RowDetailPageState extends State<RowDetailPage> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                RowDetailBloc(rowController: widget.rowController)
                  ..add(const RowDetailEvent.initial()),
          ),
          BlocProvider.value(
            value: getIt<ReminderBloc>(),
          ),
        ],
        child: ListView(
          controller: scrollController,
          children: [
            RowBanner(
              rowController: widget.rowController,
              cellBuilder: widget.cellBuilder,
            ),
            const VSpace(16),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 60),
              child: RowPropertyList(
                cellBuilder: widget.cellBuilder,
                viewId: widget.rowController.viewId,
                fieldController: widget.fieldController,
              ),
            ),
            const VSpace(20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: Divider(height: 1.0),
            ),
            const VSpace(20),
            RowDocument(
              viewId: widget.rowController.viewId,
              rowId: widget.rowController.rowId,
              scrollController: scrollController,
            ),
          ],
        ),
      ),
    );
  }
}
