import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/card_cell.dart';

class MediaCardCellStyle extends CardCellStyle {
  const MediaCardCellStyle({
    required super.padding,
    required this.textStyle,
  });

  final TextStyle textStyle;
}

// This is a placeholder for the MediaCardCell, it is not implemented
// as we use the [RowMetaPB.attachmentCount] to display cumulative attachments
// on a Card.
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
    return const SizedBox.shrink();
  }
}
