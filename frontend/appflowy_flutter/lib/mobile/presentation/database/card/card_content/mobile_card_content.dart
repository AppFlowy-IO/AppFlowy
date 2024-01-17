import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/card/cells/card_cell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
    renderHook.addTextCellHook((cellData, cardData, context) {
      final text = cellData.isEmpty
          ? LocaleKeys.grid_row_titlePlaceholder.tr()
          : cellData;
      final color = cellData.isEmpty
          ? Theme.of(context).hintColor
          : Theme.of(context).colorScheme.onBackground;

      return Row(
        children: [
          if (!cellContext.rowMeta.isDocumentEmpty) ...[
            const FlowySvg(FlowySvgs.notes_s),
            const HSpace(4),
          ],
          Expanded(
            child: FlowyText.medium(
              text,
              color: color,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
