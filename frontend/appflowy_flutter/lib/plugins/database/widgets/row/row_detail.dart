import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/row_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cell/editable_cell_builder.dart';

import 'row_banner.dart';
import 'row_property.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  const RowDetailPage({
    super.key,
    required this.rowController,
    required this.databaseController,
  });

  final RowController rowController;
  final DatabaseController databaseController;

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();
}

class _RowDetailPageState extends State<RowDetailPage> {
  final scrollController = ScrollController();
  late final cellBuilder = EditableCellBuilder(
    databaseController: widget.databaseController,
  );

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
            create: (context) => RowDetailBloc(
              fieldController: widget.databaseController.fieldController,
              rowController: widget.rowController,
            ),
          ),
          BlocProvider.value(value: getIt<ReminderBloc>()),
        ],
        child: ListView(
          controller: scrollController,
          children: [
            RowBanner(
              fieldController: widget.databaseController.fieldController,
              rowController: widget.rowController,
              cellBuilder: cellBuilder,
            ),
            const VSpace(16),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 60),
              child: RowPropertyList(
                cellBuilder: cellBuilder,
                viewId: widget.databaseController.viewId,
                fieldController: widget.databaseController.fieldController,
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
            ),
          ],
        ),
      ),
    );
  }
}
