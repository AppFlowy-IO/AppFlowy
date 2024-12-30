import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/mobile_board_card_cell_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';

class MobileCardContent extends StatelessWidget {
  const MobileCardContent({
    super.key,
    required this.rowMeta,
    required this.cellBuilder,
    required this.cells,
    required this.styleConfiguration,
    required this.userProfile,
  });

  final RowMetaPB rowMeta;
  final CardCellBuilder cellBuilder;
  final List<CellMeta> cells;
  final RowCardStyleConfiguration styleConfiguration;
  final UserProfilePB? userProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rowMeta.cover.data.isNotEmpty) ...[
          CardCover(cover: rowMeta.cover, userProfile: userProfile),
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
