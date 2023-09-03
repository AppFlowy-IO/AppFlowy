import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_document.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_builder.dart';
import 'cells/text_cell/text_cell.dart';
import 'row_banner.dart';
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
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: BlocProvider(
        create: (context) => RowDetailBloc(rowController: widget.rowController)
          ..add(const RowDetailEvent.initial()),
        child: ListView(
          controller: scrollController,
          children: [
            RowBanner2(
              rowController: widget.rowController,
              cellBuilder: widget.cellBuilder,
            ),
            const VSpace(16),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 60),
              child: RowPropertyList(
                cellBuilder: widget.cellBuilder,
                viewId: widget.rowController.viewId,
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

class RowBanner2 extends StatelessWidget {
  final RowController rowController;
  final GridCellBuilder cellBuilder;
  const RowBanner2({
    super.key,
    required this.rowController,
    required this.cellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        return RowBanner(
          rowController: rowController,
          cellBuilder: (fieldId) {
            final fieldInfo = state.cells
                .firstWhereOrNull(
                  (e) => e.fieldInfo.field.id == fieldId,
                )
                ?.fieldInfo;

            if (fieldInfo == null) {
              return const SizedBox.shrink();
            }

            final style = GridTextCellStyle(
              placeholder: LocaleKeys.grid_row_titlePlaceholder.tr(),
              textStyle: Theme.of(context).textTheme.titleLarge,
              showEmoji: false,
              autofocus: true,
              cellPadding: EdgeInsets.zero,
            );
            final cellContext = DatabaseCellContext(
              viewId: rowController.viewId,
              rowMeta: rowController.rowMeta,
              fieldInfo: fieldInfo,
            );
            return cellBuilder.build(cellContext, style: style);
          },
        );
      },
    );
  }
}
