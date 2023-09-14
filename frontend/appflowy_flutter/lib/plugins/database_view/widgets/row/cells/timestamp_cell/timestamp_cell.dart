import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimestampCellStyle extends GridCellStyle {
  String? placeholder;
  Alignment alignment;
  EdgeInsets? cellPadding;

  TimestampCellStyle({
    this.placeholder,
    this.alignment = Alignment.center,
    this.cellPadding,
  });
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
    final alignment = widget.cellStyle?.alignment ?? Alignment.centerLeft;
    final placeholder = widget.cellStyle?.placeholder ?? "";
    final padding = widget.cellStyle?.cellPadding ?? GridSize.cellContentInsets;

    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        builder: (context, state) {
          final isEmpty = state.dateStr.isEmpty;
          final text = isEmpty ? placeholder : state.dateStr;
          return Align(
            alignment: alignment,
            child: Padding(
              padding: padding,
              child: FlowyText.medium(
                text,
                color: isEmpty
                    ? Theme.of(context).hintColor
                    : AFThemeExtension.of(context).textColor,
                maxLines: null,
              ),
            ),
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
