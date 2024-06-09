import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/mobile_board_card_cell_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';

class MobileCardContent extends StatelessWidget {
  const MobileCardContent({
    super.key,
    required this.rowMeta,
    required this.cellBuilder,
    required this.cells,
    required this.styleConfiguration,
  });

  final RowMetaPB rowMeta;
  final CardCellBuilder cellBuilder;
  final List<CellMeta> cells;
  final RowCardStyleConfiguration styleConfiguration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: styleConfiguration.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: cells.map(
          (cellMeta) {
            return cellBuilder.build(
              cellContext: cellMeta.cellContext(),
              styleMap: mobileBoardCardCellStyleMap(context),
              hasNotes: !rowMeta.isDocumentEmpty,
            );
          },
        ).toList(),
      ),
    );
  }
}
