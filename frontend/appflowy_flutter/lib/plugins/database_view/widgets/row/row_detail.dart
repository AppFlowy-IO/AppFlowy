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
import 'row_action.dart';
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
        create: (context) {
          return RowDetailBloc(dataController: widget.rowController)
            ..add(const RowDetailEvent.initial());
        },
        child: ListView(
          controller: scrollController,
          children: [
            _rowBanner(),
            IntrinsicHeight(child: _responsiveRowInfo()),
            const Divider(height: 1.0),
            const VSpace(10),
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

  Widget _rowBanner() {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final paddingOffset = getHorizontalPadding(context);
        return Padding(
          padding: EdgeInsets.only(
            left: paddingOffset,
            right: paddingOffset,
            top: 20,
          ),
          child: RowBanner(
            rowMeta: widget.rowController.rowMeta,
            viewId: widget.rowController.viewId,
            cellBuilder: (fieldId) {
              final fieldInfo = state.cells
                  .firstWhereOrNull(
                    (e) => e.fieldInfo.field.id == fieldId,
                  )
                  ?.fieldInfo;

              if (fieldInfo != null) {
                final style = GridTextCellStyle(
                  placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
                  textStyle: Theme.of(context).textTheme.titleLarge,
                  showEmoji: false,
                  autofocus: true,
                );
                final cellContext = DatabaseCellContext(
                  viewId: widget.rowController.viewId,
                  rowMeta: widget.rowController.rowMeta,
                  fieldInfo: fieldInfo,
                );
                return widget.cellBuilder.build(cellContext, style: style);
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
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
    final paddingOffset = getHorizontalPadding(context);
    if (MediaQuery.of(context).size.width > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.fromLTRB(paddingOffset, 0, 20, 20),
              child: rowDataColumn,
            ),
          ),
          const VerticalDivider(width: 1.0),
          Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, paddingOffset, 0),
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
            padding: EdgeInsets.fromLTRB(paddingOffset, 0, 20, 20),
            child: rowDataColumn,
          ),
          const Divider(height: 1.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingOffset),
            child: rowOptionColumn,
          )
        ],
      );
    }
  }
}

double getHorizontalPadding(BuildContext context) {
  if (MediaQuery.of(context).size.width > 800) {
    return 50;
  } else {
    return 20;
  }
}
