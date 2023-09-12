import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimestampCellStyle extends GridCellStyle {
  Alignment alignment;

  TimestampCellStyle({this.alignment = Alignment.center});
}

class GridTimestampCell extends GridCellWidget {
  /// The [GridTimestampCell] is used by both [FieldType.CreatedTime]
  /// and [FieldType.LastEditedTime]. So it needs to know the field type.
  final FieldType fieldType;
  final CellControllerBuilder cellControllerBuilder;
  late final TimestampCellStyle? cellStyle;

  GridTimestampCell({
    GridCellStyle? style,
    required this.fieldType,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as TimestampCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridTimestampCell> createState() => _TimestampCellState();
}

class _TimestampCellState extends GridCellState<GridTimestampCell> {
  late TimestampCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as TimestampCellController;
    _cellBloc = TimestampCellBloc(cellController: cellController)
      ..add(const TimestampCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle != null
        ? widget.cellStyle!.alignment
        : Alignment.centerLeft;
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        builder: (context, state) {
          return GridTimestampCellText(
            dateStr: state.dateStr,
            alignment: alignment,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  String? onCopy() => _cellBloc.state.dateStr;

  @override
  void requestBeginFocus() {
    return;
  }
}

class GridTimestampCellText extends StatelessWidget {
  final String dateStr;
  final Alignment alignment;
  const GridTimestampCellText({
    required this.dateStr,
    required this.alignment,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: GridSize.cellContentInsets,
          child: FlowyText.medium(
            dateStr,
            maxLines: null,
          ),
        ),
      ),
    );
  }
}
