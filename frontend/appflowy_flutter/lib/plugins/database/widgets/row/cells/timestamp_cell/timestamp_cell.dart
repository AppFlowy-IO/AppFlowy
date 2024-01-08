import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimestampCellStyle extends GridCellStyle {
  String? placeholder;
  Alignment alignment;
  EdgeInsets? cellPadding;
  final bool useRoundedBorder;

  TimestampCellStyle({
    this.placeholder,
    this.alignment = Alignment.center,
    this.cellPadding,
    this.useRoundedBorder = false,
  });
}

class GridTimestampCell extends GridCellWidget {
  /// The [GridTimestampCell] is used by both [FieldType.CreatedTime]
  /// and [FieldType.LastEditedTime]. So it needs to know the field type.
  final FieldType fieldType;
  final TimestampCellController cellController;
  late final TimestampCellStyle? cellStyle;

  GridTimestampCell({
    super.key,
    GridCellStyle? style,
    required this.fieldType,
    required this.cellController,
  }) {
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
  TimestampCellBloc get cellBloc => context.read<TimestampCellBloc>();

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle?.alignment ?? Alignment.centerLeft;
    final placeholder = widget.cellStyle?.placeholder ?? "";
    final padding = widget.cellStyle?.cellPadding ?? GridSize.cellContentInsets;

    return BlocProvider(
      create: (_) {
        return TimestampCellBloc(cellController: widget.cellController)
          ..add(const TimestampCellEvent.initial());
      },
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        builder: (context, state) {
          final isEmpty = state.dateStr.isEmpty;
          final text = isEmpty ? placeholder : state.dateStr;

          if (PlatformExtension.isDesktopOrWeb ||
              widget.cellStyle == null ||
              !widget.cellStyle!.useRoundedBorder) {
            return Align(
              alignment: alignment,
              child: Padding(
                padding: padding,
                child: FlowyText.medium(
                  text,
                  color: isEmpty ? Theme.of(context).hintColor : null,
                  maxLines: null,
                ),
              ),
            );
          } else {
            return Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                minWidth: double.infinity,
              ),
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Padding(
                padding: padding,
                child: FlowyText.medium(
                  text,
                  fontSize: 16,
                  color: isEmpty
                      ? Theme.of(context).hintColor
                      : AFThemeExtension.of(context).textColor,
                  maxLines: null,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    cellBloc.close();
    super.dispose();
  }

  @override
  String? onCopy() => cellBloc.state.dateStr;

  @override
  void requestBeginFocus() {
    return;
  }
}
