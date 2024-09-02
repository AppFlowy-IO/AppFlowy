import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/card_cell.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
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
    return BlocProvider(
      create: (_) => MediaCellBloc(
        cellController: makeCellController(
          widget.databaseController,
          widget.cellContext,
        ).as(),
      ),
      child: BlocBuilder<MediaCellBloc, MediaCellState>(
        buildWhen: (previous, current) =>
            previous.files.length != current.files.length,
        builder: (context, state) {
          if (state.files.isEmpty) {
            return const SizedBox.shrink();
          }

          final count = state.files.length;
          final name = widget.databaseController.fieldController.fieldInfos
              .firstWhereOrNull(
                (i) => i.id == widget.cellContext.fieldId,
              )
              ?.name;

          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Text(
              LocaleKeys.board_media_cardText.tr(
                args: [
                  '$count',
                  name?.toLowerCase() ??
                      LocaleKeys.board_media_fallbackName.tr(),
                ],
              ),
              style: widget.style.textStyle,
            ),
          );
        },
      ),
    );
  }
}
