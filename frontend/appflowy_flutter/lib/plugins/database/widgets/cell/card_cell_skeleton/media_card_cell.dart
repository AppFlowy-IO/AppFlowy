import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/card_cell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaCardCellStyle extends CardCellStyle {
  const MediaCardCellStyle({
    required super.padding,
    required this.textStyle,
  });

  final TextStyle textStyle;
}

class MediaCardCell extends CardCell<MediaCardCellStyle> {
  const MediaCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<MediaCardCell> createState() => _MediaCellState();
}

class _MediaCellState extends State<MediaCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<MediaCellBloc>(
      create: (_) => MediaCellBloc(
        cellController: makeCellController(
          widget.databaseController,
          widget.cellContext,
        ).as(),
      )..add(const MediaCellEvent.initial()),
      child: BlocBuilder<MediaCellBloc, MediaCellState>(
        builder: (context, state) {
          if (state.files.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(left: 4),
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
                        .tr(args: ['${state.files.length}']),
                    fontSize: 12,
                    color: AFThemeExtension.of(context).secondaryTextColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
