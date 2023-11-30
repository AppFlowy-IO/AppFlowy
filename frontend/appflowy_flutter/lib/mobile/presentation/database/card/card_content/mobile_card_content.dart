import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCardContent<CustomCardData> extends StatelessWidget {
  const MobileCardContent({
    super.key,
    required this.cellBuilder,
    required this.cells,
    required this.cardData,
    required this.styleConfiguration,
    this.renderHook,
  });

  final CardCellBuilder<CustomCardData> cellBuilder;

  final List<DatabaseCellContext> cells;
  final RowCardRenderHook<CustomCardData>? renderHook;
  final CustomCardData? cardData;
  final RowCardStyleConfiguration styleConfiguration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: styleConfiguration.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _makeCells(context, cells),
      ),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<DatabaseCellContext> cells,
  ) {
    final List<Widget> children = [];

    cells.asMap().forEach((int index, DatabaseCellContext cellContext) {
      Widget child;
      if (index == 0) {
        // The title cell UI is different with a normal text cell.
        // Use render hook to customize its UI
        child = _buildTitleCell(cellContext);
      } else {
        child = Padding(
          key: cellContext.key(),
          padding: styleConfiguration.cellPadding,
          child: cellBuilder.buildCell(
            cellContext: cellContext,
            cardData: cardData,
            renderHook: renderHook,
            hasNotes: !cellContext.rowMeta.isDocumentEmpty,
          ),
        );
      }

      children.add(child);
    });
    return children;
  }

  Widget _buildTitleCell(
    DatabaseCellContext cellContext,
  ) {
    final renderHook = RowCardRenderHook<String>();
    renderHook.addTextCellHook((cellData, cardData, __) {
      return BlocBuilder<TextCellBloc, TextCellState>(
        builder: (context, state) {
          final cardDataIsEmpty = cardData == null;
          final text = cardDataIsEmpty
              ? LocaleKeys.grid_row_titlePlaceholder.tr()
              : cellData;

          final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cardDataIsEmpty
                    ? Theme.of(context).hintColor
                    : Theme.of(context).colorScheme.onBackground,
                fontSize: 20,
              );

          return Row(
            children: [
              if (!cellContext.rowMeta.isDocumentEmpty) ...[
                const FlowySvg(FlowySvgs.notes_s),
                const HSpace(4),
              ],
              Expanded(
                child: Text(
                  text,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      );
    });

    return Padding(
      key: cellContext.key(),
      padding: styleConfiguration.cellPadding,
      child: CardCellBuilder<String>(cellBuilder.cellCache).buildCell(
        cellContext: cellContext,
        renderHook: renderHook,
        hasNotes: !cellContext.rowMeta.isDocumentEmpty,
      ),
    );
  }
}
