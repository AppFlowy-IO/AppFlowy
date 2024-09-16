import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/mobile_board_card_cell_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rowMeta.cover.url.isNotEmpty) ...[
          CardCover(
            cover: rowMeta.cover,
            userProfile: context.read<BoardBloc>().userProfile,
          ),
        ],
        Padding(
          padding: styleConfiguration.cardPadding,
          child: Column(
            children: [
              ...cells.map(
                (cellMeta) => cellBuilder.build(
                  cellContext: cellMeta.cellContext(),
                  styleMap: mobileBoardCardCellStyleMap(context),
                  hasNotes: !rowMeta.isDocumentEmpty,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
