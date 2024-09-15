import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/mobile_board_card_cell_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
    final attachmentCount = rowMeta.attachmentCount.toInt();

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
                (cellMeta) {
                  return cellBuilder.build(
                    cellContext: cellMeta.cellContext(),
                    styleMap: mobileBoardCardCellStyleMap(context),
                    hasNotes: !rowMeta.isDocumentEmpty,
                  );
                },
              ),
              if (attachmentCount > 0) ...[
                const VSpace(4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      const FlowySvg(
                        FlowySvgs.media_s,
                        size: Size.square(12),
                      ),
                      const HSpace(6),
                      Flexible(
                        child: FlowyText.regular(
                          LocaleKeys.grid_media_attachmentsHint
                              .tr(args: ['$attachmentCount']),
                          fontSize: 12,
                          color:
                              AFThemeExtension.of(context).secondaryTextColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
