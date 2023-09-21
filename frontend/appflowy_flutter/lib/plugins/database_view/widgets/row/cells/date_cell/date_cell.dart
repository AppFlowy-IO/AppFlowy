import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';
import 'date_cell_bloc.dart';
import 'date_editor.dart';

class DateCellStyle extends GridCellStyle {
  String? placeholder;
  Alignment alignment;
  EdgeInsets? cellPadding;

  DateCellStyle({
    this.placeholder,
    this.alignment = Alignment.center,
    this.cellPadding,
  });
}

abstract class GridCellDelegate {
  void onFocus(bool isFocus);
  GridCellDelegate get delegate;
}

class GridDateCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final DateCellStyle? cellStyle;

  GridDateCell({
    GridCellStyle? style,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as DateCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<GridDateCell> {
  late PopoverController _popover;
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as DateCellController;
    _cellBloc = DateCellBloc(cellController: cellController)
      ..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle != null
        ? widget.cellStyle!.alignment
        : Alignment.centerLeft;
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return AppFlowyPopover(
            controller: _popover,
            triggerActions: PopoverTriggerFlags.none,
            direction: PopoverDirection.bottomWithLeftAligned,
            constraints: BoxConstraints.loose(const Size(260, 620)),
            margin: EdgeInsets.zero,
            child: GridDateCellText(
              dateStr: state.dateStr,
              placeholder: widget.cellStyle?.placeholder ?? "",
              alignment: alignment,
              cellPadding:
                  widget.cellStyle?.cellPadding ?? GridSize.cellContentInsets,
            ),
            popupBuilder: (BuildContext popoverContent) {
              return DateCellEditor(
                cellController:
                    widget.cellControllerBuilder.build() as DateCellController,
                onDismissed: () => widget.onCellFocus.value = false,
              );
            },
            onClose: () {
              widget.onCellFocus.value = false;
            },
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
  void requestBeginFocus() {
    _popover.show();
    widget.onCellFocus.value = true;
  }

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}

class GridDateCellText extends StatelessWidget {
  final String dateStr;
  final String placeholder;
  final Alignment alignment;
  final EdgeInsets cellPadding;
  const GridDateCellText({
    required this.dateStr,
    required this.placeholder,
    required this.alignment,
    required this.cellPadding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = dateStr.isEmpty;
    final text = isPlaceholder ? placeholder : dateStr;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: cellPadding,
        child: FlowyText.medium(
          text,
          color: isPlaceholder
              ? Theme.of(context).hintColor
              : AFThemeExtension.of(context).textColor,
          maxLines: null,
        ),
      ),
    );
  }
}
