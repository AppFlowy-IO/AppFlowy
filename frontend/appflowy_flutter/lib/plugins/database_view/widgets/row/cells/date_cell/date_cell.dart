import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';
import 'date_cell_bloc.dart';
import 'date_editor.dart';

class DateCellStyle extends GridCellStyle {
  Alignment alignment;

  DateCellStyle({this.alignment = Alignment.center});
}

abstract class GridCellDelegate {
  void onFocus(bool isFocus);
  GridCellDelegate get delegate;
}

class GridDateCell extends GridCellWidget {
  final bool editable;

  /// The [GridDateCell] is used by Field Type [FieldType.DateTime],
  /// [FieldType.CreatedTime], [FieldType.LastEditedTime]. So it needs
  /// to know the field type.
  final FieldType fieldType;
  final CellControllerBuilder cellControllerBuilder;
  late final DateCellStyle? cellStyle;

  GridDateCell({
    GridCellStyle? style,
    required this.fieldType,
    required this.cellControllerBuilder,
    this.editable = true,
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
          Widget dateTextWidget = GridDateCellText(
            dateStr: state.dateStr,
            alignment: alignment,
          );

          // If the cell is editable, wrap it in a popover.
          if (widget.editable) {
            dateTextWidget = AppFlowyPopover(
              controller: _popover,
              triggerActions: PopoverTriggerFlags.none,
              direction: PopoverDirection.bottomWithLeftAligned,
              constraints: BoxConstraints.loose(const Size(260, 500)),
              margin: EdgeInsets.zero,
              child: dateTextWidget,
              popupBuilder: (BuildContext popoverContent) {
                return DateCellEditor(
                  cellController: widget.cellControllerBuilder.build()
                      as DateCellController,
                  onDismissed: () => widget.onCellFocus.value = false,
                );
              },
              onClose: () {
                widget.onCellFocus.value = false;
              },
            );
          }
          return dateTextWidget;
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

    if (widget.editable) {
      widget.onCellFocus.value = true;
    }
  }

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}

class GridDateCellText extends StatelessWidget {
  final String dateStr;
  final Alignment alignment;
  const GridDateCellText({
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
